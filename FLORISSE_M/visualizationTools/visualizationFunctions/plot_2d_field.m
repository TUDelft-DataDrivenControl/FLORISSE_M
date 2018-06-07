function [ ] = plot_2d_field(turbines, turbLoc, flowField, YawAngles)
    % Select the flowfield at hub height and accompanying x and y index
    if ndims(flowField.U) == 3
        [~, ix] = min(abs(flowField.Z(1,1,:)-mean(turbLoc(:,3))));
        UatHub = squeeze(flowField.U(:,:,ix));
        xVec = squeeze(flowField.X(:,:,1));
        yVec = squeeze(flowField.Y(:,:,1));
    else
        UatHub = flowField.U;
        xVec   = flowField.X;
        yVec   = flowField.Y;
    end
    
    % Plot the flowfield
    figure
    contourf(xVec,yVec,UatHub,'Linecolor','none');
    
    colormap(parula(30));
    xlabel('x-direction (m)');
    ylabel('y-direction (m)');
    colorbar;
    caxis([floor(min(flowField.U(:))) ceil(max(flowField.U(:)))])
    
    % Plot the turbine numbers
    for j = 1:size(turbLoc,1)
        hold on;
        plot(turbLoc(j,1)+ [-1  1]*turbines(j).turbineType.rotorRadius*sin(YawAngles(j)),...
             turbLoc(j,2)+ [ 1 -1]*turbines(j).turbineType.rotorRadius*cos(YawAngles(j)),'k','LineWidth',2); 
        text(turbLoc(j,1)+30,turbLoc(j,2),['T' num2str(j)]);% ':' num2str(layout.idWf(j))]);
    end
    axis equal;
end