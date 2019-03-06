classdef layout_class < matlab.mixin.Copyable %handle
    %LAYOUT_CLASS Defines wind farms layouts to use in FLORIS
    %   This class has 2 important properties, namely a struct with
    %   turbines and an ambientInflow object.
    
    properties
        turbines
        ambientInflow
    end
    properties (SetAccess = immutable)
        description
    end
    properties (Dependent)
        nTurbs
        idIf
        locIf
        idWf
        locWf
        uniqueTurbineTypes
    end
    
    methods
        function obj = layout_class(turbines, description)
            obj.turbines = turbines;
            obj.description = description;
        end
        
        function nTurbs = get.nTurbs(obj)
            %get.locIf Get the number of turbines
            nTurbs = length(obj.turbines);
        end
        
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
        
        function locWfMat = get.locWf(obj)
            %get.locWf Get the locations of the wind turbines in the Wind Frame
            locWfMat = frame_IF2WF(obj.ambientInflow.windDirection, obj.locIf);
        end
        
        function idArray = get.idWf(obj)
            %get.locIf Get the location order in the wind frame.
            [~, idArray] = sort(obj.locWf(:, 1));
        end
        
        function turbineTypes = get.uniqueTurbineTypes(obj)
            %get.uniqueTurbineTypes Gets the unique turbines used in a layout
            turbineTypes = unique([obj.turbines.turbineType]);
        end
    end
end

