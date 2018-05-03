classdef situation_prototype < handle
    %SITUATIONPROTOTYPE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Abstract)
        windDirection
        uInfWf
        TI_0
        airDensity
    end    
    properties (Dependent)
        idWf
        locWf
    end

    methods (Abstract)
        Ufun(obj,Height)
    end
    methods
        function locWfMat = get.locWf(obj)
            %get.locIf Get the locations of the wind turbines as an array
            locWfMat = frame_IF2WF(obj.windDirection, obj.locIf);
        end
        function idArray = get.idWf(obj)
            %get.locIf Get the locations of the wind turbines as an array
            [~, idArray] = sort(obj.locWf(:, 1));
        end
    end
end

