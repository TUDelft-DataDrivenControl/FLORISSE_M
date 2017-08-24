function [ flowField ] = floris_compute_flowfield( inputData,flowField,turbines,wakes )

    if flowField.fixYaw
        % tpr stands for TurbinePreRegion. It is the amount of meters in front
        % of a turbine where the flowfield will take into account a turbine
        tpr = 50;
    else
        tpr = 0;
    end
    
    % Compute the centerLines and zone diameters at every voxel
    for  turb_num = 1:length(turbines)
        % Clear the current x and y coordinates which correspond to turbine locations.
        wakes(turb_num).centerLine = [];
        % Replace the centerline positions with an array of x-coordinates
        wakes(turb_num).centerLine(1,:) = flowField.X(1,flowField.X(1,:,1)>=turbines(turb_num).LocWF(1)-tpr,1);
        % Compute the Y and Z coordinates of the wake
        [wakes(turb_num)] = floris_wakeCenterLinePosition(inputData, turbines(turb_num), wakes(turb_num));
    end
    
    % Compute the windspeed at a cutthrough of the wind farm at every x-coordinate
    for xSample = flowField.X(1,:,1)
        % Select the upwind turbines and store them in a struct
        UwTurbines = turbines((xSample - arrayfun(@(x) x.LocWF(1)-tpr, turbines))>=0);
        if ~isempty(UwTurbines)
%             keyboard
            % compute the upwind turbine distance with respect to xSample
            deltaXs = xSample - arrayfun(@(x) x.LocWF(1), UwTurbines);

            % At position xSample; Compute the radius from the centerline
            % of the wake of an upwind turbine to all points (Y,Z)
            rads = zeros([size(squeeze(flowField.U(:,1,:))) length(UwTurbines)]);
            for turb_num = 1:length(UwTurbines)
                % Find the index of this xSample in the wake centerline
                wakeLocIndex = find(wakes(turb_num).centerLine(1,:)==xSample);
                
                rads(:,:,turb_num) = squeeze(hypot(flowField.Y(:,1,:)-wakes(turb_num).centerLine(2,wakeLocIndex), ...
                flowField.Z(:,1,:)-wakes(turb_num).centerLine(3,wakeLocIndex)));
            end
            
            % Compute the velocity at every point by adding the velocity
            % deficits.^2 and taking the root
            sumKed = zeros(size(squeeze(flowField.U(:,1,:))));
            for turb_num = 1:length(UwTurbines)
                if flowField.fixYaw
                    % The mask determines if the free stream applies or the
                    % wake velocity needs to be computed
                    mask = (rads(:,:,turb_num)<=wakes(turb_num).boundary(deltaXs(turb_num))).*...
                        (((squeeze(flowField.Y(:,1,:))-turbines(turb_num).LocWF(2))*tan(-turbines(turb_num).YawWF))<deltaXs(turb_num));
                else
                    mask = rads(:,:,turb_num)<=wakes(turb_num).boundary(deltaXs(turb_num));
                end
                
                switch inputData.wakeSum
                    case 'Katic'
                        sumKed = sumKed+mask.* ...
                            ((rads(:,:,turb_num)<=wakes(turb_num).boundary(deltaXs(turb_num))).* ...
                            (squeeze(flowField.U(:,1,:))-wakes(turb_num).V(squeeze(flowField.U(:,1,:)),turbines(turb_num).axialInd,deltaXs(turb_num),rads(:,:,turb_num))).^2);
                    case 'Voutsinas'
                        % To compute the energy deficit use the inflow
                        % speed of the upwind turbine instead of Uinf
                        sumKed = sumKed+mask.* ...
                            ((rads(:,:,turb_num)<=wakes(turb_num).boundary(deltaXs(turb_num))).* ...
                            (turbines(turb_num).windSpeed-wakes(turb_num).V(turbines(turb_num).windSpeed,turbines(turb_num).axialInd,deltaXs(turb_num),rads(:,:,turb_num))).^2);
                end
            end
            flowField.U(:,flowField.X(1,:,1)==xSample,:) = squeeze(flowField.U(:,1,:))-sqrt(sumKed);
        end
    end
    
    % Store the wake centerlines in the flowfield result for plotting
    for turb_num = 1:length(turbines)
        flowField.wakeCenterLines{turb_num} = wakes(turb_num).centerLine;
    end
end