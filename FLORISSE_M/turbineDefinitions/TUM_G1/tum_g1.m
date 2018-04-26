classdef tum_g1 < turbine_prototype
    %TUM_G1 Model wind turbine
    %   Turbine diameter is 1.1m and hubheight is 0.825m
    properties
        rotorRadius
        genEfficiency
        hubHeight
        pP
    end
    methods
        function obj = tum_g1()
            %tum_g1 Construct an instance of this class
            %   Detailed explanation goes here
            
            % Specify the path to the WS-CP-CT tables
            filepath = getFileLocation();
            % Available control methods
            availableControl = {'pitch', 'greedy', 'axialInduction'};
            % Instantiate turbine with
            % rotorRadius, genEfficiency, hubHeight and pP
            obj@turbine_prototype(filepath, availableControl);
            obj.rotorRadius = 1.1/2;
            obj.genEfficiency = 1.0;
            obj.hubHeight = 0.825;
            obj.pP = 1.787;
        end
    end
end

% This function is compatible with C-compilation
function filePath = getFileLocation()
    filePath = mfilename('fullpath');
    filePath(1:end-1-length(mfilename()));
end
