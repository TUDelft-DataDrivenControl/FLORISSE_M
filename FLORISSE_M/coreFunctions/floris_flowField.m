function [ flowField ] = floris_flowField(flowField, layout, turbineResults, yawAngles, avgWs, fixYaw, wakeCombinationModel)
    % Sort turbine and wake structs by WF
    if fixYaw
        % tpr stands for TurbinePreRegion. It is the amount of meters in front
        % of a turbine where the flowfield will take into account a turbine
        tpr = max([layout.uniqueTurbineTypes.rotorRadius])/2;
    else
        tpr = 0;
    end
    
    % Compute the windspeed at a cutthrough of the wind farm at every x-coordinate
    for xSample = flowField.X(1,:,1)
%         keyboard
        % Select the upwind turbines and store them in a struct
        uwTurbIfIndexes = find(xSample-(layout.locWf(:,1)-tpr)>=0);
%         if xSample >= 180
%             keyboard
%         end
        if ~isempty(uwTurbIfIndexes)
            % compute the upwind turbine distance with respect to xSample
            deltaXs = xSample - layout.locWf(uwTurbIfIndexes, 1);
            
            % delta Y and Z with respect to wake centerline
            dY_wc = zeros([size(squeeze(flowField.U(:,1,:))) length(uwTurbIfIndexes)]);
            dZ_wc = zeros([size(squeeze(flowField.U(:,1,:))) length(uwTurbIfIndexes)]);
            
            % Compute the velocity at every point by adding the velocity
            % deficits.^2 and taking the root
            sumKed = zeros(size(squeeze(flowField.U(:,1,:))));
            for turbNum = 1:length(uwTurbIfIndexes)
                turbIfIndex = uwTurbIfIndexes(turbNum);
                curWake = turbineResults(turbIfIndex).wake;
                % Find the index of this xSample in the wake centerline
                [dy, dz] = curWake.deflection(xSample);
                dY_wc(:,:,turbNum) = flowField.Y(:,1,:)-dy-layout.locWf(turbIfIndex,2);
                dZ_wc(:,:,turbNum) = flowField.Z(:,1,:)-dz-layout.locWf(turbIfIndex,3);
                
                if fixYaw
                    % The mask determines if the free stream applies or the
                    % wake velocity needs to be computed
                    mask = (curWake.boundary(deltaXs(turbNum),dY_wc(:,:,turbNum),dZ_wc(:,:,turbNum))).*...
                        (((squeeze(flowField.Y(:,1,:))-layout.locWf(turbIfIndex,2))*tan(-yawAngles(turbIfIndex)))<deltaXs(turbNum));
                else
                    mask = curWake.boundary(deltaXs(turbNum),dY_wc(:,:,turbNum),dZ_wc(:,:,turbNum));
                end
                
                sumKed = sumKed+wakeCombinationModel(squeeze(flowField.U(:,1,:)), avgWs(turbIfIndex), ...
                    1-mask.*curWake.deficit(deltaXs(turbNum), dY_wc(:,:,turbNum), dZ_wc(:,:,turbNum)));
            end
            flowField.U(:,flowField.X(1,:,1)==xSample,:) = squeeze(flowField.U(:,1,:))-sqrt(sumKed);
        end
    end
end