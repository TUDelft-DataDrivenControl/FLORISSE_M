function [ flowField ] = floris_compute_flowfield( inputData,flowField,turbines,wakes )
    
    % Sort turbine and wake structs by WF
    sortVector = [turbines.turbId_WF];
    turbines(sortVector) = turbines;
    wakes(sortVector)    = wakes;
    
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
        wakes(turb_num).centerLine(1,:) = flowField.X(1,flowField.X(1,:,1)>=(turbines(turb_num).LocWF(1)-tpr),1);
        % Compute the Y and Z coordinates of the wake
        wakes(turb_num).centerLine = floris_wakeCenterline(inputData.wakeModel, turbines(turb_num), wakes(turb_num).centerLine(1,:));
    end
    
    % Compute the windspeed at a cutthrough of the wind farm at every x-coordinate
    for xSample = flowField.X(1,:,1)
        % Select the upwind turbines and store them in a struct
        UwTurbines = turbines((xSample - arrayfun(@(x) x.LocWF(1)-tpr, turbines))>=0);
        if ~isempty(UwTurbines)
            % compute the upwind turbine distance with respect to xSample
            deltaXs = xSample - arrayfun(@(x) x.LocWF(1), UwTurbines);
            
            % delta Y and Z with respect to wake centerline
            dY_wc = zeros([size(squeeze(flowField.U(:,1,:))) length(UwTurbines)]);
            dZ_wc = zeros([size(squeeze(flowField.U(:,1,:))) length(UwTurbines)]);
            for turb_num = 1:length(UwTurbines)
                % Find the index of this xSample in the wake centerline
                wakeLocIndex = wakes(turb_num).centerLine(1,:)==xSample;
                
                dY_wc(:,:,turb_num) = flowField.Y(:,1,:)-wakes(turb_num).centerLine(2,wakeLocIndex);
                dZ_wc(:,:,turb_num) = flowField.Z(:,1,:)-wakes(turb_num).centerLine(3,wakeLocIndex);
            end
            
            % Compute the velocity at every point by adding the velocity
            % deficits.^2 and taking the root
            sumKed = zeros(size(squeeze(flowField.U(:,1,:))));
            for turb_num = 1:length(UwTurbines)
                if flowField.fixYaw
                    % The mask determines if the free stream applies or the
                    % wake velocity needs to be computed
                    mask = (wakes(turb_num).boundary(deltaXs(turb_num),dY_wc(:,:,turb_num),dZ_wc(:,:,turb_num))).*...
                        (((squeeze(flowField.Y(:,1,:))-turbines(turb_num).LocWF(2))*tan(-turbines(turb_num).YawWF))<deltaXs(turb_num));
                else
                    mask = wakes(turb_num).boundary(deltaXs(turb_num),dY_wc(:,:,turb_num),dZ_wc(:,:,turb_num));
                end
                               
                switch inputData.wakeModel.modelData.sumModel
                    case 'Katic'
                        sumKed = sumKed+(mask.*(squeeze(flowField.U(:,1,:))-wakes(turb_num).V(squeeze(flowField.U(:,1,:)),...
                                         deltaXs(turb_num),dY_wc(:,:,turb_num),dZ_wc(:,:,turb_num))).^2);
                    case 'Voutsinas'
                        % To compute the energy deficit use the inflow
                        % speed of the upwind turbine instead of Uinf
                        sumKed = sumKed+(mask.*(turbines(turb_num).windSpeed-wakes(turb_num).V(turbines(turb_num).windSpeed,...
                                         deltaXs(turb_num),dY_wc(:,:,turb_num),dZ_wc(:,:,turb_num))).^2);
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