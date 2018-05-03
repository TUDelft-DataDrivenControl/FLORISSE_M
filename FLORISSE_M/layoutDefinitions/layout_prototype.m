classdef layout_prototype
    %LAYOUTPROTOTYPE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Abstract)
        turbines
        uniqueTurbineTypes
    end
    properties (Dependent)
        idIf
        locIf
%         uniqueTurbineTypes
    end
    
    methods
        function locIfMat = get.locIf(obj)
            %get.locIf Get the locations of the wind turbines as an array
            locIfMat = zeros(length(obj.turbines),3);
            for i = 1:length(obj.turbines)
                locIfMat(i, :) = [obj.turbines(i).locIf obj.turbines(i).turbineType.hubHeight];
            end
        end
        
        function idArray = get.idIf(obj)
            %get.locIf Get the locations of the wind turbines as an array
            [~, idArray] = sort(obj.locIf(:, 1));
        end
        
%         function turbineTypes = get.uniqueTurbineTypes(obj)
%             %get.uniqueTurbineTypes Gets the unique turbines used in a layout
%             % turbineTypes = unique([obj.turbines.turbineType]);
%             % Is the preffered way of doing this, however it is not
%             % allowed due to C compilation. Instead the unique turbinetypes
%             % are stored in a cell array.
% 
%             turbineTypes = {obj.turbines(1).turbineType};
%             for i = 4
%                 turbineTypes{end+1} = obj.turbines(i).turbineType;
%             end
%         end
    end
end

