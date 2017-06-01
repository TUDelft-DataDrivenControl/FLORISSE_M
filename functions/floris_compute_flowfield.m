function [ wakes,flowField ] = floris_compute_flowfield( site,model,turbType,flowField,turbines,wakes )

    % Compute the centerLines and zone diameters at every voxel
    for  turb_num = 1:length(turbines)
        % Clear the current x and y coordinates which correspond to
        % turbine locations. Use an array of x-coordinates instead
        wakes(turb_num).centerLine = [];
        wakes(turb_num).centerLine(1,:) = flowField.X(1,flowField.X(1,:,1)>=turbines(turb_num).LocWF(1),1);
        [wakes(turb_num)] = floris_wakeCenterLine_and_diameter(...
             turbType.rotorDiameter, model, turbines(turb_num), wakes(turb_num));
    end
        
    % Compute the windspeed at a cutthrough of the wind farm
    for xSample = flowField.X(1,:,1)
        % Select the upwind turbines
        UwTurbines = turbines((xSample - arrayfun(@(x) x.LocWF(1), turbines))>=0);
        if ~isempty(UwTurbines)
            % compute the upwind turbine distance with respect to xSample
            deltaXs = xSample - arrayfun(@(x) x.LocWF(1), UwTurbines);

            % affectedVoxels and hypotMarkers are very similar, they are
            % both boolean matrices. hypotMarkers has a true/false value
            % for every voxel for every turbine for every zone.
            % affectedVoxels keeps track of all turbines and only zone 3.
            affectedVoxels = false(size( squeeze(flowField.U(:,1,:))));
            hypotMarkers = false([size( squeeze(flowField.U(:,1,:))) length(UwTurbines) 3]);

            for turb_num = 1:length(UwTurbines)
                [~,wakeLocIndex] = min(abs(wakes(turb_num).centerLine(1,:)-xSample));
                for zone = 1:3
                    hypotMarkers(:,:,turb_num,zone) = squeeze(hypot(flowField.Y(:,1,:)-wakes(turb_num).centerLine(2,wakeLocIndex), ...
                    flowField.Z(:,1,:)-wakes(turb_num).centerLine(3,wakeLocIndex))<= ...
                    wakes(turb_num).diameters(wakeLocIndex,zone)./2);
                end
                affectedVoxels = (affectedVoxels | hypotMarkers(:,:,turb_num,3));
            end
            
            % Only the voxels that are true in affectedVoxels have their
            % flow affected by some turbine. The other voxels are the
            % freestream.
            [row,col] = find(affectedVoxels);
            for i = 1:length(row)
                sout = 0; % outer sum of Eq. 22
                for turb_num = 1:length(UwTurbines)
                    for zone = 1:3
                        if hypotMarkers(row(i),col(i),turb_num,zone)
                            sout = sout + (turbines(turb_num).axialInd*(turbType.rotorDiameter/(turbType.rotorDiameter + 2*wakes(turb_num).Ke*wakes(turb_num).mU(zone)*deltaXs(turb_num)))^2)^2; % Eq. 16
                            break
                        end
                    end
                end
                flowField.U(row(i),flowField.X(1,:,1)==xSample,col(i)) = site.uInfWf*(1-2*sqrt(sout));
            end
        end
    end
end