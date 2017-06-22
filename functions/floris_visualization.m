function floris_visualization(inputData,outputData)
timer.script = tic;

turbines = outputData.turbines;
wakes    = outputData.wakes;
wtRows   = {outputData.wtRows};
   
% Setup flowField visualisation grid if neccesary
if (inputData.plot2DFlowfield || inputData.plot3DFlowfield)
    % resz is not used when only 2Dflowfield is plotted
    flowField.resx   = 5;     % resolution in x-axis in meters (windframe)
    flowField.resy   = 5;     % resolution in y-axis in meters (windframe)
    flowField.resz   = 10;     % resolution in z-axis in meters (windframe)
    flowField.fixYaw = true;  % Account for yaw in near-turbine region in 2Dplot
    % TODO: implement fixyaw for 3d plot

    % flowField.dims holds the X, Y and Z windframe dimensions in which
    % the turbines exist
    flowField.dims = max([turbines.LocWF],[],2);
    
    % The X, Y and Z variables form a 3D or 2D mesh
    if inputData.plot3DFlowfield
        [flowField.X,flowField.Y,flowField.Z] = meshgrid(...
            -200 : flowField.resx : flowField.dims(1)+500,...
            -200 : flowField.resy : flowField.dims(2)+200,...
            0    : flowField.resz : 200);
    else
        [flowField.X,flowField.Y,flowField.Z] = meshgrid(...
            -200 : flowField.resx : flowField.dims(1)+1000,...
            -200 : flowField.resy : flowField.dims(2)+200,...
            inputData.hub_height(1));
    end
    
    % initialize the flowfield as freestream in the U direction
    flowField.U  = inputData.uInfWf*ones(size(flowField.X));
    flowField.V  = zeros(size(flowField.X));
    flowField.W  = zeros(size(flowField.X));
end;

%% Plot the layout and flowfield visualization
% Plot a map with the turbine layout and wake centerLines
if inputData.plotLayout
    figure;
    plot_layout( wtRows,inputData,turbines,wakes );
end

if (inputData.plot2DFlowfield || inputData.plot3DFlowfield)
    % Compute the flowfield velocity at every voxel(3D) or pixel(2D)
    [wakes,flowField] = floris_compute_flowfield(inputData,flowField,turbines,wakes);
end

% Plot the flowfield as a cutthourgh at hubHeigth
if inputData.plot2DFlowfield
    figure;
    plot_2d_field( flowField,turbines )
end;

% Plot the 3D flowfield as
if inputData.plot3DFlowfield
    figure;
    
    q = quiver3(flowField.X, flowField.Y, flowField.Z, flowField.U, flowField.V, flowField.W, ...
        1.8,'linewidth',2.5,'ShowArrowHead','off');
    quiverMagCol(q,gca);
    axis equal;
    set(gca,'view',[-55 35]);
    xlabel('x-direction (m)');
    ylabel('y-direction (m)');
    colorbar;
    caxis([floor(min(flowField.U(:))) ceil(max(flowField.U(:)))])
    
    %     [X, Y, Z] = meshgrid(...
    %     -200 : flowField.resx : flowField.dims(1)+1000,...
    %     -200 : flowField.resy : flowField.dims(2)+200,...
    %     0 : flowField.resz : 200);
    %     q=coneplot(flowField.X, flowField.Y, flowField.Z, flowField.U, flowField.V, flowField.W,X,Y,Z,.7,flowField.U);
    %     set(q,'EdgeColor','none');
    %     alpha(q, .2)
    %     axis equal;
    
end;

disp(['TIMER: visualization: ' num2str(toc(timer.script)) ' s.']);
end