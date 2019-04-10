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
        function obj = layout_class(WFName)
                        
            % load wind farm table with all WTs in the WF
            File = dir(sprintf('./Settings/Wind Farm/%s.txt',WFName));
            fprintf("Importing wind farm layout from %s\n",File.name);
            WindFarm = readtable(fullfile(File.folder,File.name),'Encoding','UTF-8','HeaderLines',0,'ReadVariableNames',true,'Delimiter','\t','MultipleDelimsAsOne',true); % 'TextType','string'; % let Matlab identify other import settings from file
            
            % fill the wind farm object with turbines (type (dimensions, characteristics), location, ID)
            obj.description = WFName;
            % obj = turbine_type(pP=1.88, ... cpctMapFunc, availableControl, 'NREL5MW reference turbine');
            obj.turbines = struct('turbineType', cellfun(@turbine_type,WindFarm.Type,'UniformOutput',false), ... % turbineType is now also a cell array instead of a scalar!
                                  'locIf', num2cell([WindFarm.UTM_Easting WindFarm.UTM_Northing WindFarm.HubHeight],2), ... % new input, is not a property or the turbine type!
                                  'ID', WindFarm.ID);
            
        end
        
        function nTurbs = get.nTurbs(obj)
            %get.locIf Get the number of turbines
            nTurbs = length(obj.turbines);
        end
        
        function locIfMat = get.locIf(obj)
            %get.locIf Get the locations of the wind turbines as an array
            locIfMat = vertcat(obj.turbines(:).locIf);
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
