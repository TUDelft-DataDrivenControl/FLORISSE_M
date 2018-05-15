classdef wakeWrong
    %WAKE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        velocityDeficitObject
        deflectionModel
    end
    
    methods
        function obj = wake(modelDefinition, turbineCondition, turbineControl, turbineResult)
            %WAKE Construct an instance of this class
            %   Detailed explanation goes here
%             keyboard
            obj.velocityDeficitObject = modelDefinition.velocityDeficitObject;
%             obj.deflectionModel = modelDefinition.deflectionModel;
            obj.velocityDeficitObject.prepare_wake(modelDefinition.modelData, ...
                             turbineResult, turbineCondition, turbineControl);
                         keyboard
            obj.deflectionModel.prepare_wake(...
                             turbineResult, turbineCondition, turbineControl);
        end
        
        function V = deficit(obj, U, x, y, z)
            V = obj.velocityDeficitObject.deficit(U, x, y, z);
        end
        function V = boundary(obj, x, y, z)
            V = obj.velocityDeficitObject.boundary(x, y, z);
        end
        function [dy, dz] = deflection(obj,x)
            [dy, dz] = obj.deflectionModel.deflection(x);
        end
    end
end

