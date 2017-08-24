function [ ] = plot_2d_field( flowField,turbines )

    % Make the locations, yaw angles accesible in matrix form
    turbWF = [turbines.LocWF];
    YawWfs = [turbines.YawWF];
    
    % Select the flowfield at hub heigth and accompinying x and y index
    if ndims(flowField.U) == 3
        UatHub = flowField.U(:,:,round(mean([turbines.hub_height])/flowField.resz)).';
        xVec = flowField.X(1,:,1);
        yVec = flowField.Y(:,1,1);
    else
        UatHub = flowField.U.';
        xVec = flowField.X(1,:);
        yVec = flowField.Y(:,1);
    end
    
    % Plot the flowfield
    contourf(xVec,yVec,UatHub.','Linecolor','none');
    
    colormap(parula(30));
    xlabel('x-direction (m)');
    ylabel('y-direction (m)');
    colorbar;
    caxis([floor(min(flowField.U(:))) ceil(max(flowField.U(:)))])
    
    % Plot the turbine numbers
    for j = 1:size(turbWF,2)
        hold on;
        plot(turbWF(1,j)+ [-1  1]*turbines(j).rotorRadius*sin(YawWfs(j)),...
             turbWF(2,j)+ [ 1 -1]*turbines(j).rotorRadius*cos(YawWfs(j)),'k','LineWidth',2); 
        text(turbWF(1,j)+30,turbWF(2,j),['T' num2str(j)]);
    end
    axis equal;
end