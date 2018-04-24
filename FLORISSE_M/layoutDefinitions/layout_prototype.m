classdef layout_prototype
    %LAYOUTPROTOTYPE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Abstract)
        turbines
    end
    properties (Dependent)
        idIf
        locIf
    end
    
    methods
        function locIfMat = get.locIf(obj)
            %get.locIf Get the locations of the wind turbines as an array
            locIfMat = [];
            for turbine = obj.turbines
                locIfMat = [locIfMat;...
                            turbine.locIf turbine.turbineType.hubHeight];
            end
        end
        function idArray = get.idIf(obj)
            %get.locIf Get the locations of the wind turbines as an array
            [~, idArray] = sort(obj.locIf(:, 1));
        end
    end
end

