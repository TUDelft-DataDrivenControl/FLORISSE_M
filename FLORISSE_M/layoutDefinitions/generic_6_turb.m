classdef generic_6_turb < layout_prototype
    %GENERIC_6_TURB Summary of this class goes here
    %   Detailed explanation goes here
    properties
        turbines
    end    
    methods
        function obj = generic_6_turb()
            %GENERIC_6_TURB Construct an instance of this class
            %   Detailed explanation goes here
            NREL5MWpitch = nrel5mw('pitch');
            locIf = [300,    100.0;
                     300,    300.0;
                     300,    500.0;
                     1000,   100.0;
                     1000,   300.0;
                     1000,   500.0];
            
            obj.turbines = [];
            for i = 1:size(locIf,1)
                obj.turbines = [obj.turbines turbine(NREL5MWpitch, locIf(i,:))];
            end
        end
    end
end

