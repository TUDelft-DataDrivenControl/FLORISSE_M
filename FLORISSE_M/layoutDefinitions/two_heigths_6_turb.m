classdef two_heigths_6_turb < layout_prototype
    %two_heigths_6_turb Summary of this class goes here
    %   Detailed explanation goes here
    properties
        turbines
    end
    
    methods
        function obj = two_heigths_6_turb
            %two_heigths_6_turb Construct an instance of this class
            %   Detailed explanation goes here
            NREL5MWTurbType = nrel5mw;
            NREL5MWPole2 = nrel5mw;
            NREL5MWPole2.hubHeight = 100;
            locIf = {[300,    100.0];
                     [300,    300.0];
                     [300,    500.0];
                     [1000,   100.0];
                     [1000,   300.0];
                     [1000,   500.0]};
            % Form the turbine struct array with the first turbineType on the
            % first three positions and the second turbineType on the last
            % positions
            obj.turbines = struct('turbineType', NREL5MWTurbType, ...
                                  'locIf',         locIf);
            for i = [4 5 6]
                obj.turbines(i).turbineType = NREL5MWPole2;
            end
        end
    end
end

