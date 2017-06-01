function [ ] = plot_3d_field( flowField, site )
%PLOT_3D_FIELD Plot the 3D flowfield as a quiver plot
%   Plot the 3D flowfield as a quiver plot or cone plot

    figure
    q = quiver3(flowField.X, flowField.Y, flowField.Z, flowField.U, flowField.V, flowField.W, ...
        1.8,'linewidth',2.5,'ShowArrowHead','off');
    % Color the arrows corresponding to their magniture
    quiverMagCol(q,gca); axis equal;
    set(gca,'view',[-55 35]);
    xlabel('x-direction (m)');
    ylabel('y-direction (m)');
    colorbar; caxis([floor(min(flowField.U(:))) ceil(site.uInfWf)])

%     [X, Y, Z] = meshgrid(...
%     -200 : flowField.resx : flowField.dims(1)+1000,...
%     -200 : flowField.resy : flowField.dims(2)+200,...
%     0 : flowField.resz : 200);
%     q=coneplot(flowField.X, flowField.Y, flowField.Z, flowField.U, flowField.V, flowField.W,X,Y,Z,.7,flowField.U);
%     set(q,'EdgeColor','none');
%     alpha(q, .2)
%     axis equal;

end

