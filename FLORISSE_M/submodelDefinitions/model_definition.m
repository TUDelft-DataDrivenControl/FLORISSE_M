classdef model_definition
    %MODEL_DEFINITION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1
    end
    
    methods
        function obj = model_definition(~,deflModel,~,velModel,~,combinModel,~,otherModel)
            %MODEL_DEFINITION Construct an instance of this class
            %   Detailed explanation goes here
            display(deflModel)
            display(velModel)
            display(combinModel)
            display(otherModel)
            obj.Property1 = otherModel ;
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

