function [flowField] = floris_visualization(inputData,outputData,flowField,frame)
%% Plot the layout and the full flowfield in either 2D or 3D 
    timer.script = tic;

    % Setup structs
    flowField.IF.frame = 'IF'; % Inertial frame
    flowField.WF.frame = 'WF'; % Wind-aligned frame
    
    scale = inputData.rotorRadius(1)/(126.4/2); % equal 1 for NREL turbine
    
    % Setup mesh resolution
    flowField.resx   = 5*scale;   % resolution in x-axis in meters (windframe)
    flowField.resy   = 5*scale;   % resolution in y-axis in meters (windframe)
    flowField.resz   = 10*scale;  % resolution in z-axis in meters (windframe)
    flowField.WF.fixYaw = true;% Account for yaw in near-turbine region in 2Dplot
    
    % Specify dimensions of to-be-extracted flow field
    flowField.IF.xMin = min(inputData.LocIF(:,1))-1000*scale;
    flowField.IF.xMax = max(inputData.LocIF(:,1))+1000*scale;
    flowField.IF.yMin = min(inputData.LocIF(:,2))-1000*scale;
    flowField.IF.yMax = max(inputData.LocIF(:,2))+1000*scale;
    
%     if strcmp(frame,'IF')
%         xMin = min(inputData.LocIF(:,1))-1000;
%         xMax = max(inputData.LocIF(:,1))+1000;
%         yMin = min(inputData.LocIF(:,2))-1000;
%         yMax = max(inputData.LocIF(:,2))+1000;
%     elseif strcmp(frame,'WF')
%         maxDims = max([outputData.turbines.LocWF],[],2);
%         xMin = -200;
%         xMax = maxDims(1)+1000;
%         yMin = -200;
%         yMax = maxDims(2)+200;
%     else
%         error('frame can only be ''IF'' (inert. frame) or ''WF'' (wind-aligned frame).');
%     end
    
    computeField.IF = false;
    computeField.WF = false;
    
    % Determine if we need to calculate WF flowField, and the corr. mesh
    if (~isfield(flowField.WF,'U') && (flowField.plot2DFlowfield || flowField.plotLayout))
        flowField.zvec = inputData.hub_height(1);
        [flowField.IF.X,flowField.IF.Y,flowField.IF.Z] = meshgrid(...
            flowField.IF.xMin : flowField.resx : flowField.IF.xMax,...
            flowField.IF.yMin : flowField.resy : flowField.IF.yMax,...
            flowField.zvec);
        computeField.WF = true;
        computeField.IF = strcmp(frame,'IF'); % If WF updated, then IF updated too (if to be plotted)
    end
    if ((isfield(flowField.WF,'U') && ismatrix(flowField.WF.U) && flowField.plot3DFlowfield)...
            ||(~isfield(flowField.WF,'U') && flowField.plot3DFlowfield))
        flowField.zvec = 0 : flowField.resz : 200*scale;
        [flowField.IF.X,flowField.IF.Y,flowField.IF.Z] = meshgrid(...
            flowField.IF.xMin : flowField.resx : flowField.IF.xMax,...
            flowField.IF.yMin : flowField.resy : flowField.IF.yMax,...
            flowField.zvec);
        computeField.WF = true;
        computeField.IF = strcmp(frame,'IF');
    end

    % For the case that WF.U is previously calculated, but IF.U is not
    if (strcmp(frame,'IF') && ~isfield(flowField.IF,'U'))
        computeField.IF = true;
    end
    
    % Set up mesh for WF calculations
    if (computeField.WF)
        % Fix the outer bounds of the mesh for compatibility with IF and WF
        grid_2D.X = flowField.IF.X(:,:,1);
        grid_2D.Y = flowField.IF.Y(:,:,1);
        grid_2D.Z = flowField.IF.Z(:,:,1);
        targetGrid_WF = frame_IF2WF(inputData.windDirection,inputData.LocIF,'IF',...
            [grid_2D.X(:), grid_2D.Y(:),grid_2D.Z(:)]);
        
        % Draw rectangle (WF) around rotated rectangle (IF)
        [flowField.WF.X,flowField.WF.Y,flowField.WF.Z] = meshgrid(...
            min(targetGrid_WF(:,1)) : flowField.resx : max(targetGrid_WF(:,1)),...
            min(targetGrid_WF(:,2)) : flowField.resy : max(targetGrid_WF(:,2)),...
            flowField.zvec);
        
        % Compute the flow field for the WF
        disp(' Computing flowfield in wind-aligned frame. This may take some time.');
        flowField.WF.U  = inputData.Ufun(flowField.WF.Z).*ones(size(flowField.WF.X));
        flowField.WF.V  = zeros(size(flowField.WF.X));
        flowField.WF.W  = zeros(size(flowField.WF.X));

        % Compute the flowfield velocity at every voxel(3D) or pixel(2D)
        [flowField.WF] = floris_flowField(inputData,flowField.WF,outputData.turbines,outputData.wakes);        
        
        % Save targetGrid_WF for later use in interpolation
        flowField.IF.targetGrid_WF = targetGrid_WF;
    end
    
    % Do the calculations
    if computeField.IF       
        % Linear grid interpolation from rotated mesh to desired grid
        disp(' Interpolating flowfield to inertial frame.');
        F_interp = griddedInterpolant(flowField.WF.X(:,:,1)',flowField.WF.Y(:,:,1)',flowField.WF.U(:,:,1)');
        for j = 1:size(flowField.WF.U,3)
            F_interp.Values = flowField.WF.U(:,:,j)';
            flowField.IF.U(:,:,j) = reshape(...
                F_interp(flowField.IF.targetGrid_WF(:,1),...
                flowField.IF.targetGrid_WF(:,2)),...
                size(flowField.IF.X(:,:,1)));
        end
    end
        
    %% Plot the layout and flowfield visualization
    % Plot a map with the turbine layout and wake centerLines
    if flowField.plotLayout
        figure; % This is always plotted in wind-aligned frame
        plot_layout( inputData,outputData.turbines,flowField.WF.wakeCenterLines );
    end

    % Plot the flowfield as a cutthourgh at hubHeigth
    if flowField.plot2DFlowfield
        figure;
        flowField.(frame).resz = flowField.resz;
        plot_2d_field(flowField.(frame),outputData.turbines )
    end

    % Plot the 3D flowfield as
    if flowField.plot3DFlowfield
        volvisApp(flowField.(frame).X, flowField.(frame).Y,...
                  flowField.(frame).Z, flowField.(frame).U)
    end

    disp(['TIMER: visualization: ' num2str(toc(timer.script)) ' s.']);
end