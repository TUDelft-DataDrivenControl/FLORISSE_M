function [flowField] = floris_visualization(inputData,outputData,flowField)
%% Plot the layout and the full flowfield in either 2D or 3D 
    timer.script = tic;

    flowField.resx   = 5;   % resolution in x-axis in meters (windframe)
    flowField.resy   = 5;   % resolution in y-axis in meters (windframe)
    flowField.resz   = 10;  % resolution in z-axis in meters (windframe)
    flowField.fixYaw = true;% Account for yaw in near-turbine region in 2Dplot

    % Specify dimensions of to-be-extracted flow field
    if strcmp(lower(flowField.frame),'if')
        xMin = min(inputData.LocIF(:,1))-1000;
        xMax = max(inputData.LocIF(:,1))+1000;
        yMin = min(inputData.LocIF(:,2))-1000;
        yMax = max(inputData.LocIF(:,2))+1000;
    elseif strcmp(lower(flowField.frame),'wf')
        maxDims = max([outputData.turbines.LocWF],[],2);
        xMin = -200;
        xMax = maxDims(1)+1000;
        yMin = -200;
        yMax = maxDims(2)+200;
    else
        error('flowField.frame can only be ''if'' (inert. frame) or ''wf'' (wind-aligned frame).');
    end
    
    computeField = false;
    % Setup flowField visualisation grid if necessary
    if (~isfield(flowField,'U') && (flowField.plot2DFlowfield || flowField.plotLayout))
        zvec = inputData.hub_height(1);
        [flowGrid.X,flowGrid.Y,flowGrid.Z] = meshgrid(...
            xMin : flowField.resx : xMax,...
            yMin : flowField.resy : yMax,...
            zvec);
        computeField = true;
    end
    if ((isfield(flowField,'U') && ismatrix(flowField.U) && flowField.plot3DFlowfield)...
            ||(~isfield(flowField,'U') && flowField.plot3DFlowfield))
        zvec = 0 : flowField.resz : 200;
        [flowGrid.X,flowGrid.Y,flowGrid.Z] = meshgrid(...
            xMin : flowField.resx : xMax,...
            yMin : flowField.resy : yMax,...
            zvec);
        computeField = true;
    end

    if (~isfield(flowField,'U') || flowField.plotLayout)
        if strcmp(lower(flowField.frame),'if')
            % Coordinate change in flowField from IF -> WF necessary
            grid_2D.X = flowGrid.X(:,:,1);
            grid_2D.Y = flowGrid.Y(:,:,1);
            grid_2D.Z = flowGrid.Z(:,:,1);
            targetGrid_WF = frame_IF2WF(inputData.windDirection,inputData.LocIF,'if',...
                                  [grid_2D.X(:), grid_2D.Y(:),grid_2D.Z(:)]);
            flowField.X = flowGrid.X;
            flowField.Y = flowGrid.Y;
            flowField.Z = flowGrid.Z;

            % Draw rectangle (WF) around rotated rectangle (IF)
            flowField_WF = flowField; % make a copy and generate outer rectangular mesh
            [flowField_WF.X,flowField_WF.Y,flowField_WF.Z] = meshgrid(...
                min(targetGrid_WF(:,1)) : flowField.resx : max(targetGrid_WF(:,1)),...
                min(targetGrid_WF(:,2)) : flowField.resy : max(targetGrid_WF(:,2)),...
                zvec);
        else
            % No need to change coordinate system
            flowField_WF   = flowField;
            flowField_WF.X = flowGrid.X;
            flowField_WF.Y = flowGrid.Y;
            flowField_WF.Z = flowGrid.Z;
        end
    end
    
    if computeField
        disp(' Computing flowfield, this may take some time');
        flowField_WF.U  = inputData.Ufun(flowField_WF.Z).*ones(size(flowField_WF.X));
        flowField_WF.V  = zeros(size(flowField_WF.X));
        flowField_WF.W  = zeros(size(flowField_WF.X));

        % Compute the flowfield velocity at every voxel(3D) or pixel(2D)
        [flowField_WF] = floris_compute_flowfield(inputData,flowField_WF,outputData.turbines,outputData.wakes);
        
        if strcmp(lower(flowField.frame),'if') 
            % Linear grid interpolation from rotated mesh to desired grid
            F_interp = griddedInterpolant(flowField_WF.X(:,:,1)',flowField_WF.Y(:,:,1)',flowField_WF.U(:,:,1)');
            for j = 1:length(zvec)
                F_interp.Values = flowField_WF.U(:,:,j)';
                flowField.U(:,:,j) = reshape(...
                                        F_interp(targetGrid_WF(:,1),...
                                                 targetGrid_WF(:,2)),...
                                                   size(grid_2D.X));
%                 flowField.U(:,:,j) = reshape(interp2(,,...
%                                 flowField_WF.U,targetGrid_WF(:,1),...
%                                 targetGrid_WF(:,2)),size(flowField.X));
            end
        else % For wind-aligned frame, the grid is already the desired one
            flowField = flowField_WF;
        end
    end
        
    %% Plot the layout and flowfield visualization
    % Plot a map with the turbine layout and wake centerLines
    if flowField.plotLayout
        figure;
        plot_layout( inputData,outputData.turbines,flowField_WF.wakeCenterLines );
    end

    % Plot the flowfield as a cutthourgh at hubHeigth
    if flowField.plot2DFlowfield
        figure;
        plot_2d_field(flowField,outputData.turbines )
    end

    % Plot the 3D flowfield as
    if flowField.plot3DFlowfield
        volvisApp(flowField.X, flowField.Y, flowField.Z, flowField.U)
    end

    disp(['TIMER: visualization: ' num2str(toc(timer.script)) ' s.']);
end