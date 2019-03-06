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
        
    % Determine probe locations in wind-aligned frame
    [probeLocationsWF]   = frame_IF2WF(florisObj.layout.ambientInflow.windDirection,[xIF(:), yIF(:), zIF(:)]);
    xWF(:,1)             = probeLocationsWF(:,1);
    yWF(:,1)             = probeLocationsWF(:,2);
    zWF(:,1)             = zIF;
    
    % Debugging option: force one-by-one calculations
    forceOneByOne = false;
    verbose = false;
    
    % Determine if the probes can be formatted in a structured grid
    if (length(unique(xWF)) * length(unique(yWF)) * length(unique(zWF)) == length(xWF)) && ...
            length(unique(yWF)) > 1 && length(unique(zWF)) > 1 && ~forceOneByOne
        if verbose
            disp('Found structured grid of vertical slices. Calculating probes in slices.')
        end
        uProbe = [];
        [xUnique,~,bi] = unique(xWF,'stable');
        % Calculate slice by slice
        for xi = 1:length(xUnique)
            % Create 2D vertical slice grid at x-location
            [flowField.X, flowField.Y, flowField.Z] = meshgrid(...
            xUnique(xi), unique(yWF), unique(zWF));
                
            % Calculate flowfield
            flowField = calculateFlowFieldLocal(flowField,florisObj,fixYaw);
            
            % 2D Interpolation to match indices
            uProbe = [uProbe; interp2(flowField.Y',flowField.Z',flowField.U',yWF(xi==bi),zWF(xi==bi))];
        end

    % Either of two situations:
    %  1) We have structure in our [xWF yWF zWF] data
    %  2) We have no structure, and more than nInterpBuffer probes        
    elseif ((max(zWF)-min(zWF)) < 1.0 || max(xWF)-min(xWF) < 1.0 || ...
            max(yWF)-min(yWF) < 1.0 || length(xWF) > nInterpBuffer) && ~forceOneByOne
        
        flowFieldRes = 5.0; % Resolution of 5 m in any direction
        [flowField.X, flowField.Y, flowField.Z] = meshgrid(...
            min(xWF) : flowFieldRes : max(xWF), ...
            min(yWF) : flowFieldRes : max(yWF), ...
            min(zWF) : flowFieldRes : max(zWF));
        
        % Calculate flowfield
        flowField = calculateFlowFieldLocal(flowField,florisObj,fixYaw); 
        
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
        
    
    else % We have no structure, but less than nInterpBuffer probes. Do one-by-one:  
        if verbose
            disp('Calculating flow field one by one.')
        end
        Uin = florisObj.layout.ambientInflow.Vfun(zWF);
        uProbe = zeros(size(xWF));
        for i = 1:length(xWF)
            flowField = struct('X',xWF(i),'Y',yWF(i),'Z',zWF(i),'U',Uin(i));
            flowField = calculateFlowFieldLocal(flowField,florisObj,fixYaw);
            uProbe(i) = flowField.U;
        end
    end
   
   
    % Calculate flowField function
    function [flowFieldOut] = calculateFlowFieldLocal(flowFieldIn,florisObjIn,fixYaw)
        % Set-up the FLORIS object, exporting the variables of interest
        layout               = florisObjIn.layout;
        turbineResults       = florisObjIn.turbineResults;
        yawAngles            = florisObjIn.controlSet.yawAngleWFArray;
        avgWs                = [florisObjIn.turbineConditions.avgWS];
        wakeCombinationModel = florisObjIn.model.wakeCombinationModel;
        
        flowFieldOut = flowFieldIn; % Copy flowfield
        
        % Calculate output
        flowFieldOut.U = layout.ambientInflow.Vfun(flowFieldOut.Z);
        flowFieldOut = compute_flow_field(flowFieldOut, layout, turbineResults, ...
        yawAngles, avgWs, fixYaw, wakeCombinationModel);
        flowFieldOut.X = squeeze(flowFieldOut.X);
        flowFieldOut.Y = squeeze(flowFieldOut.Y);
        flowFieldOut.Z = squeeze(flowFieldOut.Z);
        flowFieldOut.U = squeeze(flowFieldOut.U);
    end
end