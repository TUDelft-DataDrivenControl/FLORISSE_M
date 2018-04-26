classdef two_heigths_6_turb < layout_prototype
    %GENERIC_6_TURB Summary of this class goes here
    %   Detailed explanation goes here
    properties
        turbines
    end
    
    methods
        function obj = two_heigths_6_turb
            %GENERIC_6_TURB Construct an instance of this class
            %   Detailed explanation goes here
            NREL5MWTurb = nrel5mw;
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
            
            obj.turbines = struct('turbineType', NREL5MWTurb , ...
                                  'locIf',         locIf(1:3));
            obj.turbines(4:6) = struct('turbineType', NREL5MWPole2 , ...
                                  'locIf',         locIf(4:6));
        end
    end
end

