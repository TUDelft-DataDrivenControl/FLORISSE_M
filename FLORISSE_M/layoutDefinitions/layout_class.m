classdef layout_class < handle
    %LAYOUT_CLASS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        turbines
        ambientInflow
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
        function obj = layout_class(turbines, ambientInflow)
            obj.turbines = turbines;
            obj.ambientInflow = ambientInflow;
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

