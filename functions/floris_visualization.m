function [flowField] = floris_visualization(inputData,outputData,flowField)
%% Plot the layout and the full flowfield in either 2D or 3D 
    timer.script = tic;

    flowField.resx   = 5;   % resolution in x-axis in meters (windframe)
    flowField.resy   = 5;   % resolution in y-axis in meters (windframe)
    flowField.resz   = 10;  % resolution in z-axis in meters (windframe)
    flowField.dims = max([outputData.turbines.LocWF],[],2);
    flowField.fixYaw = true;% Account for yaw in near-turbine region in 2Dplot

    computeField = false;

    % Setup flowField visualisation grid if neccesary
    if (~isfield(flowField,'U') && (flowField.plot2DFlowfield || flowField.plotLayout))
        [flowField.X,flowField.Y,flowField.Z] = meshgrid(...
            -200 : flowField.resx : flowField.dims(1)+1000,...
            -200 : flowField.resy : flowField.dims(2)+200,...
            inputData.hub_height(1));
        computeField = true;
    end;
    if (isfield(flowField,'U') && ismatrix(flowField.U) && flowField.plot3DFlowfield)
        [flowField.X,flowField.Y,flowField.Z] = meshgrid(...
            -200 : flowField.resx : flowField.dims(1)+500,...
            -200 : flowField.resy : flowField.dims(2)+200,...
            0    : flowField.resz : 200);
        computeField = true;
    end

    if computeField
        disp(' Computing flowfield, this may take some time');
        flowField.U  = inputData.uInfWf*ones(size(flowField.X));
        flowField.V  = zeros(size(flowField.X));
        flowField.W  = zeros(size(flowField.X));

        % Compute the flowfield velocity at every voxel(3D) or pixel(2D)
        [flowField] = floris_compute_flowfield(inputData,flowField,outputData.turbines,outputData.wakes);
    end
    %% Plot the layout and flowfield visualization

    % Plot a map with the turbine layout and wake centerLines
    if flowField.plotLayout
        figure;
        plot_layout( inputData,outputData.turbines,flowField.wakeCenterLines );
    end

    % Plot the flowfield as a cutthourgh at hubHeigth
    if flowField.plot2DFlowfield
        figure;
        plot_2d_field( flowField,outputData.turbines )
    end;

    % Plot the 3D flowfield as
    if flowField.plot3DFlowfield
        volvisApp(flowField.X, flowField.Y, flowField.Z, flowField.U)
    end;

    disp(['TIMER: visualization: ' num2str(toc(timer.script)) ' s.']);
end