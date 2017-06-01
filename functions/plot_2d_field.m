function [ ] = plot_2d_field( flowField,site,turbines,turbType )

    % Make the locations, yaw angles accesible in matrix form
    turbWF = [turbines.LocWF];
    YawWfs = [turbines.YawWF];
    
    % Select the flowfield at hub heigth and accompinying x and y index
    if ndims(flowField.U) == 3
        UatHub = flowField.U(:,:,round(turbType.hub_height/flowField.resz)).';
        xVec = flowField.X(1,:,1);
        yVec = flowField.Y(:,1,1);
    else
        UatHub = flowField.U.';
        xVec = flowField.X(1,:);
        yVec = flowField.Y(:,1);
    end
    
    % Correction for turbine yaw in flow field in turning radius of turbine
    if flowField.fixYaw
        for turbi = 1:size(turbWF,2) % for each turbine
            ytop    = turbWF(2,turbi)+cos(YawWfs(turbi))*turbType.rotorDiameter/2;
            ybottom = turbWF(2,turbi)-cos(YawWfs(turbi))*turbType.rotorDiameter/2;

            [~,celltopy]    = min(abs(ytop   - yVec));
            [~,cellbottomy] = min(abs(ybottom- yVec));

            for celly = cellbottomy-2:1:celltopy+2
                % cell location of turbine blade x
                xlocblade = turbWF(1,turbi)-sin(YawWfs(turbi))*(yVec(celly)-turbWF(2,turbi));
                [~,cellxtower] = min(abs(xVec-turbWF(1,turbi)));
                [~,cellxblade] = min(abs(xVec-xlocblade));
                
                if yVec(celly) > turbWF(2,turbi) % top part
                    if YawWfs(turbi) < 0
                        UatHub(cellxtower:cellxblade,celly) = UatHub(cellxtower-1,celly);
                    else
                        UatHub(cellxblade:cellxtower,celly) = UatHub(cellxtower+1,celly);
                    end;
                else % lower part
                    if YawWfs(turbi) < 0
                        UatHub(cellxblade:cellxtower,celly) = UatHub(cellxtower+1,celly);
                    else
                        UatHub(cellxtower:cellxblade,celly) = UatHub(cellxtower-1,celly);
                    end;
                end;
            end;
        end;
    end;
    
    % Plot the flowfield
    figure
    contourf(xVec,yVec,UatHub.','Linecolor','none');
    
    colormap(parula(30));
    xlabel('x-direction (m)');
    ylabel('y-direction (m)');
    colorbar;
    caxis([floor(min(flowField.U(:))) ceil(site.uInfWf)])
    
    % Plot the turbine numbers
    for j = 1:size(turbWF,2)
        hold on;
        plot(turbWF(1,j)+ [-0.5, +0.5]*turbType.rotorDiameter*sin(YawWfs(j)),...
             turbWF(2,j)+ [+0.5, -0.5]*turbType.rotorDiameter*cos(YawWfs(j)),'k','LineWidth',2); 
        text(turbWF(1,j)+30,turbWF(2,j),['T' num2str(j)]);
    end;
    axis equal;
end