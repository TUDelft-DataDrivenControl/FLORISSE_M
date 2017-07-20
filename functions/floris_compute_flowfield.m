function [ flowField ] = floris_compute_flowfield( inputData,flowField,turbines,wakes )

    % Compute the centerLines and zone diameters at every voxel
    for  turb_num = 1:length(turbines)
        % Clear the current x and y coordinates which correspond to
        % turbine locations. Use an array of x-coordinates instead
        wakes(turb_num).centerLine = [];
        wakes(turb_num).centerLine(1,:) = flowField.X(1,flowField.X(1,:,1)>=turbines(turb_num).LocWF(1),1);
        [wakes(turb_num)] = floris_wakeCenterLinePosition(inputData, turbines(turb_num), wakes(turb_num));
    end
    
    % Compute the windspeed at a cutthrough of the wind farm
    for xSample = flowField.X(1,:,1)
        % Select the upwind turbines
        UwTurbines = turbines((xSample - arrayfun(@(x) x.LocWF(1), turbines))>=0);
        if ~isempty(UwTurbines)
            % compute the upwind turbine distance with respect to xSample
            deltaXs = xSample - arrayfun(@(x) x.LocWF(1), UwTurbines);

            % At position xSample; Compute the radius from the centerline
            % of the wake of an upwind turbine to all points (Y,Z)
            hypots = zeros([size(squeeze(flowField.U(:,1,:))) length(UwTurbines)]);
            for turb_num = 1:length(UwTurbines)
                [~,wakeLocIndex] = min(abs(wakes(turb_num).centerLine(1,:)-xSample));
                
                hypots(:,:,turb_num) = squeeze(hypot(flowField.Y(:,1,:)-wakes(turb_num).centerLine(2,wakeLocIndex), ...
                flowField.Z(:,1,:)-90));
            end
            
            % Compute the velocity at every point by adding the velocity
            % deficits.^2 and takign the root as described in katic(1986)
            sout = zeros(size(squeeze(flowField.U(:,1,:))));
            for turb_num = 1:length(UwTurbines)
                sout = sout + (hypots(:,:,turb_num)<wakes(turb_num).boundary(deltaXs(turb_num))).*((turbines(turb_num).axialInd*wakes(turb_num).cFull(deltaXs(turb_num),hypots(:,:,turb_num))).^2); % Eq. 16
            end
            flowField.U(:,flowField.X(1,:,1)==xSample,:) = inputData.uInfWf*(1-2*sqrt(sout));
        end
    end
    
    % Store the wake centerline in the flowfield result
    for turb_num = 1:length(turbines)
        flowField.wakeCenterLines{turb_num} = wakes(turb_num).centerLine;
    end
end