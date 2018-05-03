classdef floris
    %FLORIS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        situation
        controlSet
        model
    end
    
    methods
        function obj = floris(situation, controlSet, model)
            %FLORIS Construct an instance of this class
            %   Detailed explanation goes here
            obj.situation = situation;
            obj.controlSet = controlSet;
            obj.model = model;
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

