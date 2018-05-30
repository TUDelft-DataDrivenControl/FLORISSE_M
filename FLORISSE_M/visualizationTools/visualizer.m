classdef visualizer
    %VISUALIZER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        layout
        turbineResults
        plotLayout
        plot2DFlowfield
        plot3DFlowfield
        frame
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
            
            % Default visualization settings, if not specified
            if ~exist('plotLayout','var');  obj.plotLayout      = false; end
            if ~exist('plot2D','var');      obj.plot2DFlowfield = true; end
            if ~exist('plot3D','var');      obj.plot3DFlowfield = false;  end
            if ~exist('frame','var');       obj.frame           = 'IF';  end
            
            
        end
        
        function outputArg = define_flow_field(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.layout
            % Setup mesh resolution
            flowField.resx = 0.20*inputData.rotorRadius(1); % resolution in x-axis in meters
            flowField.resy = 0.20*inputData.rotorRadius(1); % resolution in y-axis in meters
            flowField.resz = 0.10*inputData.hub_height(1);  % resolution in z-axis in meters
            flowField.WF.fixYaw = true;% Account for yaw in near-turbine region in 2Dplot
        end
    end
end

