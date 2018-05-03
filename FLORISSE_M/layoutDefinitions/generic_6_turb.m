classdef generic_6_turb < layout_prototype
    %GENERIC_6_TURB Summary of this class goes here
    %   Detailed explanation goes here
    properties
        turbines
        uniqueTurbineTypes
    end
    
    methods
        function obj = generic_6_turb
            %GENERIC_6_TURB Construct an instance of this class
            %   Detailed explanation goes here
            NREL5MWTurbType = nrel5mw();
            locIf = {[300,    100.0];
                     [300,    300.0];
                     [300,    500.0];
                     [1000,   100.0];
                     [1000,   300.0];
                     [1000,   500.0]};
            
            % Put all the turbines in a struct array
            obj.turbines = struct('turbineType', NREL5MWTurbType , ...
                                  'locIf',         locIf);
            obj.uniqueTurbineTypes = {NREL5MWTurbType};
        end
    end
end

