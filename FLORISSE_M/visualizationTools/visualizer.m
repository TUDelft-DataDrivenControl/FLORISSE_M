classdef visualizer < handle
    %VISUALIZER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        layout
        turbineResults
        wakeCombinationModel
        yawAngleWFArray
        avgWs
        flowFieldWF
        flowFieldIF
        flowfieldMain
    end
    
    methods
        function obj = visualizer(florisRunner)
            %VISUALIZER Construct an instance of this class
            %   Detailed explanation goes here
            if ~florisRunner.has_run()
                disp([' outputData is not (yet) available/not formatted properly.' ...
                    ' Please run a (single) simulation, then call this function.']);
                return
            end
            % Store the relevant properties from the FLORIS object
            obj.layout = florisRunner.layout;
            obj.turbineResults = florisRunner.turbineResults;
            obj.wakeCombinationModel = florisRunner.model.wakeCombinationModel;
            obj.yawAngleWFArray = florisRunner.controlSet.yawAngleWFArray;
            obj.avgWs = [florisRunner.turbineConditions.avgWS];
            
            % Make flowfields for both the Inertial and Wind Direction frame
            obj.flowFieldWF = obj.create_empty_flowfield(obj.layout.locWf, [-4 14 -4 4]);
            obj.flowFieldIF = obj.create_empty_flowfield(obj.layout.locIf, [-14 14 -14 14]);
            % Take the corners of the Inertial and Wind Direction frame
            allCorners = [obj.flowFieldWF.corners [0 0 0 0].'; ...
                frame_IF2WF(obj.layout.ambientInflow.windDirection, ...
                [obj.flowFieldIF.corners [0 0 0 0].'])];
            % Make another flowfield which contains both flowfields
            obj.flowfieldMain = obj.create_empty_flowfield(allCorners, [0 0 0 0]);
        end
        
        function flowField = create_empty_flowfield(obj, locAr, boundaries)
            % The flowfield objects are at the center of the visualization.
            % They contain all the coordinates and velocity information
            refRotorRadius = obj.layout.turbines(1).turbineType.rotorRadius;
            
            xmin = min(locAr(:,1)) + boundaries(1)*refRotorRadius;
            xmax = max(locAr(:,1)) + boundaries(2)*refRotorRadius;
            ymin = min(locAr(:,2)) + boundaries(3)*refRotorRadius;
            ymax = max(locAr(:,2)) + boundaries(4)*refRotorRadius;
            % Store the corners starting at the bottom left and continuing
            % counterclockwise
            corners = [xmin ymin; xmax ymin; xmax ymax; xmin ymax];
            flowField = struct('resx',    0.20*refRotorRadius, ...
                               'resy',    0.20*refRotorRadius, ...
                               'resz',    0.05*refRotorRadius, ...
                               'corners', corners, ...
                               'X',       {[]}, ...
                               'Y',       {[]}, ...
                               'Z',       {[]}, ...
                               'U',       {[]}, ...
                               'V',       {[]}, ...
                               'W',       {[]});
        end
        
        function plot2dWF(obj,plotFig)
        %This function plots a 2D slice of the velocity field oriented
        %with the X-axis along the wind direction
            if nargin < 2
                plotFig = true; % Default option
            end
            % Start by checking if the mainFlowField has the relevant
            % information, otherwise get it
            if isempty(obj.flowfieldMain.U)
                obj.flowfieldMain = obj.define_flow_field_mesh(obj.flowfieldMain, '2D');
                obj.compute_velocity_wf();
            end
            % Extract the velocity information from the main flowfield and
            % fill up the relevant matrices in the wind frame flowfield
            if isempty(obj.flowFieldWF.U)
                mask = obj.flowfieldMain.X > obj.flowFieldWF.corners(1, 1) & ...
                       obj.flowfieldMain.X < obj.flowFieldWF.corners(3, 1) & ...
                       obj.flowfieldMain.Y > obj.flowFieldWF.corners(1, 2) & ...
                       obj.flowfieldMain.Y < obj.flowFieldWF.corners(3, 2);
                % Find the x-dimensions of the mask to reshape the results
                [xIdMin, ~] = find(mask, 1,'first');
                [xIdMax, ~] = find(mask, 1,'last');
                % Extract and reshape all the relevant flowfield information
                for field = ['X', 'Y', 'Z', 'U', 'V', 'W']
                    obj.flowFieldWF.(field) = reshape(obj.flowfieldMain.(field)(mask), 1+xIdMax-xIdMin ,[]);
                end
            end
            if plotFig
                plot_2d_field(obj.layout.turbines, obj.layout.locWf, obj.flowFieldWF, obj.yawAngleWFArray)
            end
        end
        
        function plot2dIF(obj,plotFig)
        %This function plots a 2D slice of the velocity field oriented
        %with the X-axis identical to the inertial frame
            if nargin < 2
                plotFig = true; % Default option
            end        
            % Start by checking if the mainFlowField has the relevant
            % information, otherwise get it
            if isempty(obj.flowfieldMain.U)
                obj.flowfieldMain = obj.define_flow_field_mesh(obj.flowfieldMain, '2D');
                obj.compute_velocity_wf();
            end
            % Extract the velocity information from the main flowfield and
            % fill up the relevant matrices in the inertial frame flowfield
            if isempty(obj.flowFieldIF.U)
                % Define a mesh grid fot the inertial frame
                obj.flowFieldIF = obj.define_flow_field_mesh(obj.flowFieldIF, '2D');
                % rotate the inertial grid into the wind frame
                targetGrid = frame_IF2WF(obj.layout.ambientInflow.windDirection, ...
                    [obj.flowFieldIF.X(:), obj.flowFieldIF.Y(:), obj.flowFieldIF.Z(:)]);
                % use interp2/interp3 to interpolate the main flowfield velocity
                % values to fill up the inertial frame U
                if (ndims(obj.flowfieldMain.X) == 2)
                    obj.flowFieldIF.U = reshape(interp2(obj.flowfieldMain.X, ...
                        obj.flowfieldMain.Y,obj.flowfieldMain.U,...
                        targetGrid(:,1),targetGrid(:,2)), size(obj.flowFieldIF.X));                    
                else
                    obj.flowFieldIF.U = reshape(interp3(obj.flowfieldMain.X, ...
                        obj.flowfieldMain.Y,obj.flowfieldMain.Z,obj.flowfieldMain.U,...
                        targetGrid(:,1),targetGrid(:,2),targetGrid(:,3)), size(obj.flowFieldIF.X));
                end
            end
            if plotFig
                plot_2d_field(obj.layout.turbines, obj.layout.locIf, obj.flowFieldIF, ...
                              obj.yawAngleWFArray+ obj.layout.ambientInflow.windDirection)
            end
        end
        
        function plot3dWF(obj,plotFig)
        %This function starts the volumeVisualization app and shows the
        %velocity field oriented with the X-axis along the wind direction
            if nargin < 2
                plotFig = true; % Default option
            end
            % Start by checking if the mainFlowField has the relevant
            % information, otherwise get it
            if ismatrix(obj.flowfieldMain.U)
                obj.flowfieldMain = obj.define_flow_field_mesh(obj.flowfieldMain, '3D');
                obj.compute_velocity_wf();
            end
            if ismatrix(obj.flowFieldWF.U)
                mask = obj.flowfieldMain.X > obj.flowFieldWF.corners(1, 1) & ...
                       obj.flowfieldMain.X < obj.flowFieldWF.corners(3, 1) & ...
                       obj.flowfieldMain.Y > obj.flowFieldWF.corners(1, 2) & ...
                       obj.flowfieldMain.Y < obj.flowFieldWF.corners(3, 2);
                indStart = find(mask, 1,'first');
                indEnd = find(mask, 1,'last');
                [xIdMin, yIdMin, ~] = ind2sub(size(obj.flowfieldMain.X),indStart);
                [xIdMax, yIdMax, ~] = ind2sub(size(obj.flowfieldMain.X),indEnd);
                for field = ['X', 'Y', 'Z', 'U', 'V', 'W']
                    obj.flowFieldWF.(field) = reshape(obj.flowfieldMain.(field)(mask), ...
                                                      1+xIdMax-xIdMin, 1+yIdMax-yIdMin, []);
                end
            end
            if plotFig
                volvisApp(obj.flowFieldWF.X, obj.flowFieldWF.Y,...
                          obj.flowFieldWF.Z, obj.flowFieldWF.U)
            end
        end
        
        function plot3dIF(obj,plotFig)
        %This function starts the volumeVisualization app and shows the
        %velocity field oriented with the X-axis identical to the inertial frame
            if nargin < 2
                plotFig = true; % Default option
            end        
            % Start by checking if the mainFlowField has the relevant
            % information, otherwise get it
            if ismatrix(obj.flowfieldMain.U)
                obj.flowfieldMain = obj.define_flow_field_mesh(obj.flowfieldMain, '3D');
                obj.compute_velocity_wf();
            end
            if ismatrix(obj.flowFieldIF.U)
                obj.flowFieldIF = obj.define_flow_field_mesh(obj.flowFieldIF, '3D');
                targetGrid = frame_IF2WF(obj.layout.ambientInflow.windDirection, ...
                    [obj.flowFieldIF.X(:), obj.flowFieldIF.Y(:), obj.flowFieldIF.Z(:)]);
                obj.flowFieldIF.U = reshape(interp3(obj.flowfieldMain.X, ...
                    obj.flowfieldMain.Y, obj.flowfieldMain.Z, obj.flowfieldMain.U, ...
                    targetGrid(:,1), targetGrid(:,2), targetGrid(:,3)), size(obj.flowFieldIF.X));
            end
            if plotFig
                volvisApp(obj.flowFieldIF.X, obj.flowFieldIF.Y,...
                          obj.flowFieldIF.Z, obj.flowFieldIF.U)
            end
        end
        
        function plot_layout(obj)
            plot_layout_and_wakes(obj)
        end
        
        function flowField = define_flow_field_mesh(obj, flowField, dimension)
            % Make a 2D or 3D meshgrid for a flowfield
            refHubHeight = obj.layout.turbines(1).locIf(3);
            switch dimension
                case '2D'
                    if isempty(flowField.X)
                        [flowField.X, flowField.Y, flowField.Z] = meshgrid(...
                            flowField.corners(1, 1) : flowField.resx : flowField.corners(3, 1), ...
                            flowField.corners(1, 2) : flowField.resy : flowField.corners(3, 2), ...
                            refHubHeight);
                    end
                case '3D'
                    if ismatrix(flowField.X)
                        % Make sure the z-array includes the hub
                        zArHalf1 = refHubHeight : -flowField.resz : 0;
                        zArHalf2 = refHubHeight : flowField.resz : 2*refHubHeight;
                        [flowField.X, flowField.Y, flowField.Z] = meshgrid(...
                            flowField.corners(1, 1) : flowField.resx : flowField.corners(3, 1), ...
                            flowField.corners(1, 2) : flowField.resy : flowField.corners(3, 2), ...
                            [zArHalf1(end:-1:2) zArHalf2]);
                    end
                otherwise
                    error('define_flow_field_wf_mesh:valueError', 'dimension input most contain string with either 2D or 3D, it contained %s', dimension);
            end
        end
        
        function compute_velocity_wf(obj)
            % Compute the velocity on a meshgrid aligned with the wind frame
            if isempty(obj.flowfieldMain.U) || ~isequal(size(obj.flowfieldMain.X), size(obj.flowfieldMain.U))
                disp(' Computing flowfield velocities. This may take some time.');
                % Instantiate the flowField according to the ambientInflow
                obj.flowfieldMain.U  = obj.layout.ambientInflow.Vfun(obj.flowfieldMain.Z);
                obj.flowfieldMain.V  = zeros(size(obj.flowfieldMain.X));
                obj.flowfieldMain.W  = zeros(size(obj.flowfieldMain.X));

                % Compute the flowfield velocity at every voxel(3D) or pixel(2D)
                obj.flowfieldMain = compute_flow_field(obj.flowfieldMain, obj.layout, obj.turbineResults, ...
                    obj.yawAngleWFArray, obj.avgWs, true, obj.wakeCombinationModel);
            end
        end
    end
end

