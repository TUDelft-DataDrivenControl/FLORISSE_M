function [ ] = plot_2d_field( flowField,turbines )

    % Make the locations and yaw angles accessible in matrix form
    if strcmp(lower(flowField.frame),'if')
        turbLoc = [turbines.LocIF];
        YawAngles = [turbines.YawIF];
    elseif strcmp(lower(flowField.frame),'wf')
        turbLoc = [turbines.LocWF];
        YawAngles = [turbines.YawWF];
    else 
        error('flowField.frame can only be ''if'' (inert. frame) or ''wf'' (wind-aligned frame).');
    end
    
    % Select the flowfield at hub heigth and accompinying x and y index
    if ndims(flowField.U) == 3
        UatHub = squeeze(flowField.U(:,:,round(mean([turbines.hub_height])/flowField.resz)));
        xVec = squeeze(flowField.X(:,:,1));
        yVec = squeeze(flowField.Y(:,:,1));
    else
        UatHub = flowField.U;
        xVec   = flowField.X;
        yVec   = flowField.Y;
    end
    
    % Plot the flowfield
    contourf(xVec,yVec,UatHub,'Linecolor','none');
    
    colormap(parula(30));
    xlabel('x-direction (m)');
    ylabel('y-direction (m)');
    colorbar;
    caxis([floor(min(flowField.U(:))) ceil(max(flowField.U(:)))])
    
    % Plot the turbine numbers
    for j = 1:size(turbLoc,2)
        hold on;
        plot(turbLoc(1,j)+ [-1  1]*turbines(j).rotorRadius*sin(YawAngles(j)),...
             turbLoc(2,j)+ [ 1 -1]*turbines(j).rotorRadius*cos(YawAngles(j)),'k','LineWidth',2); 
        text(turbLoc(1,j)+30,turbLoc(2,j),['T' num2str(j)]);
    end
    axis equal;
end