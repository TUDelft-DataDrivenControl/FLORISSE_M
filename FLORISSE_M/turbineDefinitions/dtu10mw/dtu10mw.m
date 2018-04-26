classdef dtu10mw < turbine_prototype
    %DTU10MW Summary of this class goes here
    %   Detailed explanation goes here
    properties
        rotorRadius
        genEfficiency
        hubHeight
        pP
    end
    methods
        function obj = dtu10mw()
            %DTU10MW Construct an instance of this class
            %   Detailed explanation goes here

            % Specify the path to the WS-CP-CT tables
            filepath = getFileLocation();
            % Available control methods
            availableControl = {'axialInduction'};
            % Instantiate turbine with
            % rotorRadius, genEfficiency, hubHeight and pP
            obj@turbine_prototype(filepath, availableControl);
            obj.rotorRadius = 178.3/2.;
            obj.genEfficiency = 0.944;
            obj.hubHeight = 119.0;
            obj.pP = 1.88;
        end
    end
end

% This function is compatible with C-compilation
function filePath = getFileLocation()
    filePath = mfilename('fullpath');
    filePath(1:end-1-length(mfilename()));
end
