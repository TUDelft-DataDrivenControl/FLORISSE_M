subplot(1,2,1);
FLORIS.run();
FLORIS.visualize(0,1,0);
drawnow; hVis = gcf;

figure('Position',[192.2000 202.6000 1112 486.4000]);
h(1)=subplot(1,3,1);
copyobj(allchild(get(hVis,'CurrentAxes')),h(1));
axis equal tight
ylabel('x-direction (m)'); xlabel('y-direction (m)');
title('FLORIS [m/s]','interpreter','latex');
xlim([min(FLORIS.outputFlowField.X(:)) max(FLORIS.outputFlowField.X(:))])
ylim([min(FLORIS.outputFlowField.Y(:)) max(FLORIS.outputFlowField.Y(:))])
colorbar('southoutside')

subplot(1,3,2);
trisurf(tri, cellCenters(:,1), cellCenters(:,2), flowSpeedAverage); % Raw SOWFA data
lighting none; shading flat; axis equal tight;
light('Position',[-50 -15 29]); view(0,90); hold on;
plot3(FLORIS.inputData.LocIF(:,1),FLORIS.inputData.LocIF(:,2),...
    FLORIS.inputData.LocIF(:,3),'k.','markerSize',10);
ylabel('x-direction (m)'); xlabel('y-direction (m)');
xlim([min(FLORIS.outputFlowField.X(:)) max(FLORIS.outputFlowField.X(:))])
ylim([min(FLORIS.outputFlowField.Y(:)) max(FLORIS.outputFlowField.Y(:))])
title('LES [m/s]','interpreter','latex');
colorbar('southoutside')
caxis([floor(min(FLORIS.outputFlowField.U(:))) ceil(max(FLORIS.outputFlowField.U(:)))])

% Calculate error
U_interp = griddata(cellCenters(:,1), cellCenters(:,2), flowSpeedAverage, ...
                   FLORIS.outputFlowField.X(:),FLORIS.outputFlowField.Y(:));
U_interp = reshape(U_interp,size(FLORIS.outputFlowField.U));
U_error  = abs(U_interp - FLORIS.outputFlowField.U);

% Plot error
subplot(1,3,3);
contourf(FLORIS.outputFlowField.X,FLORIS.outputFlowField.Y,U_error,'Linecolor','none');
ylabel('x-direction (m)'); xlabel('y-direction (m)'); hold on;
axis equal tight
xlim([min(FLORIS.outputFlowField.X(:)) max(FLORIS.outputFlowField.X(:))])
ylim([min(FLORIS.outputFlowField.Y(:)) max(FLORIS.outputFlowField.Y(:))])
plot(FLORIS.inputData.LocIF(:,1),FLORIS.inputData.LocIF(:,2),'k.','markerSize',10);
title('Abs. error [m/s]','interpreter','latex');
colorbar('southoutside')
caxis([0.0, 3.0])

drawnow;