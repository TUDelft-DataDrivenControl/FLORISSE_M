classdef floris
    %FLORIS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        layout
        controlSet
        model
    end
    
    methods
        function obj = floris(layout, controlSet, model)
            %FLORIS Construct an instance of this class
            %   Detailed explanation goes here
            if isnan(layout.ambientFlow)
                error('You must set an ambientFlow before the layout %s is usable in a simulation', layout.description)
            end
            obj.layout = layout;
            obj.controlSet = controlSet;
            obj.model = model;
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.layout.ambientFlow.windDirection;
        end
    end
end

