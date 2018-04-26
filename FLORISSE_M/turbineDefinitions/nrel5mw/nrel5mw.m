classdef nrel5mw < turbine_prototype
    %NREL5MW Summary of this class goes here
    %   See https://www.nrel.gov/docs/fy09osti/38060.pdf for a more
    %   detailed explanation of the NREL 5MW reference wind turbine.
    properties
        rotorRadius
        genEfficiency
        hubHeight
        pP
    end
    methods
        function obj = nrel5mw()
            %NREL5MW Construct an instance of this class
            %   Detailed explanation goes here

            % Specify the path to the WS-CP-CT tables
            filepath = getFileLocation();
            % Available control methods
            availableControl = {'pitch', 'greedy', 'axialInduction'};
            % Instantiate turbine with location of LUTs and available controls
            obj@turbine_prototype(filepath, availableControl);

            obj.rotorRadius = 126.4/2.;
            obj.genEfficiency = 0.944;
            obj.hubHeight = 90.0;
            obj.pP = 1.88;
        end
    end
end

% This function is compatible with C-compilation
function filePath = getFileLocation()
    filePath = mfilename('fullpath');
    filePath(1:end-1-length(mfilename()));
end
