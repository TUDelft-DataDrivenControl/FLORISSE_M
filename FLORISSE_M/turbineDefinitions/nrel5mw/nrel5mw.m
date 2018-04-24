classdef nrel5mw < turbine_prototype
    %NREL5MW Summary of this class goes here
    %   See https://www.nrel.gov/docs/fy09osti/38060.pdf for a more
    %   detailed explanation of the NREL 5MW reference wind turbine.
    methods
        function obj = nrel5mw(controlMethod)
            %NREL5MW Construct an instance of this class
            %   Detailed explanation goes here
            [filepath, ~, ~] = fileparts(mfilename('fullpath'));
            % Available control methods
            availableControl = {'pitch', 'greedy', 'axialInduction'};
            % Instantiate turbine with
            % rotorRadius, genEfficiency, hubHeight and pP
            obj@turbine_prototype(126.4/2., 0.944, 90.0, 1.88, ...
                                 filepath, controlMethod, availableControl);
        end
    end
end
