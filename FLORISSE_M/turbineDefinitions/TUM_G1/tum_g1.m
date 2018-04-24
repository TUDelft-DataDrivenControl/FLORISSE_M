classdef tum_g1 < turbine_prototype
    %TUM_G1 Model wind turbine
    %   Turbine diameter is 1.1m and hubheight is 0.825m
    
    methods
        function obj = tum_g1(controlMethod)
            %tum_g1 Construct an instance of this class
            %   Detailed explanation goes here
            
            % Get the path of this file
            [filepath, ~, ~] = fileparts(mfilename('fullpath'));
            % Available control methods
            availableControl = {'pitch', 'greedy', 'axialInduction'};
            % Instantiate turbine with
            % rotorRadius, genEfficiency, hubHeight and pP
            obj@turbine_prototype(1.1/2., 1.0, 0.825, 1.787, ...
                                 filepath, controlMethod, availableControl);
        end
    end
end

