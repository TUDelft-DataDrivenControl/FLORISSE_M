function [uProbe] = compute_probes(florisObj,xIF,yIF,zIF,fixYaw,nInterpBuffer);
%
% This function computes the flow velocity at a set of arbitrary probe
% locations (x,y,z) in the wind farm. Structure is exploited when possible.
%
% By: Bart Doekemeijer
%

    % Run the FLORIS object, if no results available yet
    if florisObj.has_run == 0
        florisObj.run();
    end
    
    if nargin < 5
        fixYaw = false;
    end
    
    if nargin < 6
        % nInterpBuffer determines at what number of unstructured probe
        % entries it will switch from one-by-one evaluation (analytically
        % correct but slow) to a full 3D evaluation and then a linear
        % interpolation (slightly off but much faster for many probes).
        nInterpBuffer = 3e4;
    end
    
    % Set-up the FLORIS object, exporting the variables of interest
    layout               = florisObj.layout;
    turbineResults       = florisObj.turbineResults;
    yawAngles            = florisObj.controlSet.yawAngleArray;
    avgWs                = [florisObj.turbineConditions.avgWS];
    wakeCombinationModel = florisObj.model.wakeCombinationModel;
    
    % Determine probe locations in wind-aligned frame
    [probeLocationsWF]   = frame_IF2WF(layout.ambientInflow.windDirection,[xIF(:), yIF(:), zIF(:)]);
    xWF(:,1)             = probeLocationsWF(:,1);
    yWF(:,1)             = probeLocationsWF(:,2);
    zWF(:,1)             = zIF;
    
    
     
    % Determine if the probes can be formatted in a smart way
    if (max(zWF)-min(zWF)) < 1.0 || max(xWF)-min(xWF) < 1.0 || max(yWF)-min(yWF) < 1.0 || length(xWF) > nInterpBuffer
        % Either of two situations:
        %  1) We have structure in our [xWF yWF zWF] data
        %  2) We have no structure, and more than nInterpBuffer probes
        interpField = true;
        flowFieldRes = 5.0; % Resolution of 5 m in any direction
        [flowField.X, flowField.Y, flowField.Z] = meshgrid(...
            min(xWF) : flowFieldRes : max(xWF), ...
            min(yWF) : flowFieldRes : max(yWF), ...
            min(zWF) : flowFieldRes : max(zWF));
    else
        % We have no structure, but less than nInterpBuffer probes. Do one-by-one
        interpField = false;
    end
    
    if interpField
        disp('Accelerating compute_probes.m using a structured flowfield and linear interpolation. To disable, set nInterpBuffer = Inf.')
        
        % Interpolation using structured evaluation
        flowField.U = layout.ambientInflow.Vfun(flowField.Z);
        flowField = compute_flow_field(flowField, layout, turbineResults, ...
            yawAngles, avgWs, fixYaw, wakeCombinationModel);
        flowField.X = squeeze(flowField.X);
        flowField.Y = squeeze(flowField.Y);
        flowField.Z = squeeze(flowField.Z);
        flowField.U = squeeze(flowField.U);
        
        if sum(size(flowField.U)~=1) == 1 % 1D data
            if length(unique(flowField.X)) > 1
                uProbe = interp1(flowField.X,flowField.U,xWF);
            elseif length(unique(flowField.Y)) > 1
                uProbe = interp1(flowField.Y,flowField.U,yWF);
            elseif length(unique(flowField.Z)) > 1
                uProbe = interp1(flowField.Z,flowField.U,zWF);  
            else
                error('Cannot determine how to interpolate 1D data.');
            end
        elseif sum(size(flowField.U)~=1) == 2 % 2D data
            % 2D interpolation
            if length(unique(flowField.X)) <= 1
                uProbe = interp2(flowField.Y',flowField.Z',flowField.U',yWF,zWF);
            elseif  length(unique(flowField.Y)) <= 1
                uProbe = interp2(flowField.X',flowField.Z',flowField.U',xWF,zWF);
            elseif length(unique(flowField.Z)) <= 1
                uProbe = interp2(flowField.X,flowField.Y,flowField.U,xWF,yWF);
            else
                error('Cannot determine how to interpolate 2D data.');
            end
        elseif sum(size(flowField.U)~=1) == 3 % 3D data
            % 3D interpolation
            uProbe = interp3(flowField.X,flowField.Y,flowField.Z,flowField.U,xWF,yWF,zWF);
        else
            error('Cannot determine how to interpolate 3D data.');
        end
        
    else
        % Calculate velocity field one-by-one (for every probe location)
        Uin = layout.ambientInflow.Vfun(zWF);
        uProbe = zeros(size(xIF));
        for i = 1:length(xIF)
            flowField = struct('X',xWF(i),'Y',yWF(i),'Z',zWF(i),'U',Uin(i));
            flowField = compute_flow_field(flowField, layout, turbineResults, ...
                yawAngles, avgWs, fixYaw, wakeCombinationModel);
            uProbe(i) = flowField.U;
        end
    end
end