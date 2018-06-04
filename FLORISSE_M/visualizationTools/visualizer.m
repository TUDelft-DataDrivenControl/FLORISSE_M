classdef visualizer < handle
    %VISUALIZER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        layout
        turbineResults
        wakeCombinationModel
        yawAngles
        avgWs
        plotLayout
        plot2DFlowfield
        plot3DFlowfield
        frame
        resx
        resy
        resz
%         fixYaw
        xMin
        xMax
        yMin
        yMax
        flowFieldWF
        flowFieldIF
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
            obj.layout = florisRunner.layout;
            obj.turbineResults = florisRunner.turbineResults;
            obj.wakeCombinationModel = florisRunner.model.wakeCombinationModel;
            obj.yawAngles = florisRunner.controlSet.yawAngles;
            obj.avgWs = [florisRunner.turbineConditions.avgWS];
            
            % Default visualization settings, if not specified
            if ~exist('plotLayout','var');  obj.plotLayout      = false; end
            if ~exist('plot2D','var');      obj.plot2DFlowfield = true; end
            if ~exist('plot3D','var');      obj.plot3DFlowfield = false;  end
            if ~exist('frame','var');       obj.frame           = 'IF';  end
            obj.define_flow_field_wf_mesh()
            obj.compute_flow_field_wf()
%             volvisApp(obj.flowFieldWF.X, obj.flowFieldWF.Y,...
%                   obj.flowFieldWF.Z, obj.flowFieldWF.U)
            plot_2d_field(obj.layout, obj.flowFieldWF, obj.yawAngles)
        end
        
        function define_flow_field_wf_mesh(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            refTurbType = obj.layout.turbines(1).turbineType;

            % Setup mesh resolution
            obj.resx = 0.20*refTurbType.rotorRadius; % resolution in x-axis in meters
            obj.resy = 0.20*refTurbType.rotorRadius; % resolution in y-axis in meters
            obj.resz = 0.10*refTurbType.hubHeight;  % resolution in z-axis in meters
%             obj.resx = 0.05*refTurbType.rotorRadius; % resolution in x-axis in meters
%             obj.resy = 0.05*refTurbType.rotorRadius; % resolution in y-axis in meters
%             obj.resz = 0.10*refTurbType.hubHeight;  % resolution in z-axis in meters
            
%             obj.xMin = min(obj.layout.locWf(:,1))-14*refTurbType.rotorRadius;
%             obj.xMax = max(obj.layout.locWf(:,1))+14*refTurbType.rotorRadius;
%             obj.yMin = min(obj.layout.locWf(:,2))-14*refTurbType.rotorRadius;
%             obj.yMax = max(obj.layout.locWf(:,2))+14*refTurbType.rotorRadius;
            obj.xMin = -1.1068e+03;
            obj.xMax = 2.4451e+03;
            obj.yMin = -1.1036e+03;
            obj.yMax = 1.8542e+03;
%             obj.xMin = min(obj.layout.locWf(:,1))-4*refTurbType.rotorRadius;
%             obj.xMax = max(obj.layout.locWf(:,1))+15*refTurbType.rotorRadius;
%             obj.yMin = min(obj.layout.locWf(:,2))-4*refTurbType.rotorRadius;
%             obj.yMax = max(obj.layout.locWf(:,2))+4*refTurbType.rotorRadius;
    
            % Determine if we need to calculate IF flowField
            if (~isfield(obj.flowFieldWF,'U') && (obj.plot2DFlowfield || obj.plotLayout))
                [obj.flowFieldWF.X, obj.flowFieldWF.Y, obj.flowFieldWF.Z] = meshgrid(...
                    obj.xMin : obj.resx : obj.xMax,...
                    obj.yMin : obj.resy : obj.yMax,...
                    refTurbType.hubHeight);
            end
            if ((isfield(obj.flowFieldWF,'U') && ismatrix(obj.flowFieldWF.U) && obj.plot3DFlowfield)...
                    ||(~isfield(obj.flowFieldWF,'U') && obj.plot3DFlowfield))
                [obj.flowFieldWF.X, obj.flowFieldWF.Y, obj.flowFieldWF.Z] = meshgrid(...
                    obj.xMin : obj.resx : obj.xMax,...
                    obj.yMin : obj.resy : obj.yMax,...
                    0 : obj.resz : 2*refTurbType.hubHeight);
            end
        end
        
        function compute_flow_field_wf(obj)
            % Compute the flow field for the WF
            disp(' Computing flowfield in wind-aligned frame. This may take some time.');
            obj.flowFieldWF.U  = obj.layout.ambientInflow.Vfun(obj.flowFieldWF.Z);
            obj.flowFieldWF.V  = zeros(size(obj.flowFieldWF.X));
            obj.flowFieldWF.W  = zeros(size(obj.flowFieldWF.X));

            % Compute the flowfield velocity at every voxel(3D) or pixel(2D)
            obj.flowFieldWF = floris_flowField(obj.flowFieldWF, obj.layout, obj.turbineResults, ...
                obj.yawAngles, obj.avgWs, true, obj.wakeCombinationModel);
            
        end
    end
end

