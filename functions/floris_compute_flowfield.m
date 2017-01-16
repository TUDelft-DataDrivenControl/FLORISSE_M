function [ wakes,flowField ] = floris_compute_flowfield( site,model,turbType,flowField,turbines,wakes )

    % Compute the centerlines and zone diameters at every voxel
    for  turb_num = 1:length(turbines)
        wakes(turb_num).xSamples = flowField.X(1,flowField.X(1,:,1)>=turbines(turb_num).LocWF(1),1);
        [wakes(turb_num)] = floris_centerline_and_diameter_at_x(...
             turbType.rotorDiameter, model, turbines(turb_num), wakes(turb_num));
    end
    
    % Compute the windspeed at a cutthrough of the wind farm
    for xSample = flowField.X(1,:,1)
        % Select the upwind turbines and compute their distance
        UwTurbines = turbines((xSample - arrayfun(@(x) x.LocWF(1), turbines))>=0);
        deltaXs = xSample - arrayfun(@(x) x.LocWF(1), UwTurbines);
        
        % The tusF variable creates a map at every Xsample slice of the
        % flowfield. It checks wether a voxel is affected by any upwind
        % turbine. This is used later on to cut the computation time in
        % half in extreme cases.
        tusF = zeros(size(flowField.U(:,1,:)));
        for turb_num = 1:length(UwTurbines)
            [~,wakeLocIndex] = min(abs(wakes(turb_num).xSamples-xSample));
            tusF(hypot(flowField.Y(:,1,:)-wakes(turb_num).centerline(wakeLocIndex), ...
            flowField.Z(:,1,:)-turbines(turb_num).LocWF(3))<= ...
            wakes(turb_num).diameters(wakeLocIndex,3)./2) = 1;
        end
    
        for i = 1:size(squeeze((tusF)),1)
            for j = 1:size(squeeze((tusF)),2)
                % Check if the voxel is affected by some turbine.. if not
                % skip the windspeed computation.
                if tusF(i,1,j)
                    sout = 0; % outer sum of Eq. 22
                    for turb_num = 1:length(UwTurbines)
                        [~,wakeLocIndex] = min(abs(wakes(turb_num).xSamples-xSample));
                        for zone = 1:3
                            if hypot(flowField.Y(i,1,j)-wakes(turb_num).centerline(wakeLocIndex), ...
                                flowField.Z(i,1,j)-turbines(turb_num).LocWF(3))<= ...
                                wakes(turb_num).diameters(wakeLocIndex,zone)./2
                                sout = sout + (turbines(turb_num).axialInd*(turbType.rotorDiameter/(turbType.rotorDiameter + 2*wakes(turb_num).Ke*wakes(turb_num).mU(zone)*deltaXs(turb_num)))^2)^2; % Eq. 16
                                break
                            end
                        end
                    end
                    flowField.U(i,flowField.X(1,:,1)==xSample,j) = site.u_inf_wf*(1-2*sqrt(sout));
                end
            end
        end
    end
end