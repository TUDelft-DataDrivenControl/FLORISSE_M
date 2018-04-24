classdef dtu10mw < turbine_prototype
    %DTU10MW Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function obj = dtu10mw(controlMethod)
            %DTU10MW Construct an instance of this class
            %   Detailed explanation goes here
            [filepath, ~, ~] = fileparts(mfilename('fullpath'));
            % Available control methods
            availableControl = {'axialInduction'};
            % Instantiate turbine with
            % rotorRadius, genEfficiency, hubHeight and pP
            obj@turbine_prototype(178.3/2., 0.944, .0, 1.88, ...
                                 filepath, controlMethod, availableControl);
        end
    end
end

