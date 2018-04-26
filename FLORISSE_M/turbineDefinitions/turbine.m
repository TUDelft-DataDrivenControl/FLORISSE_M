classdef turbine
    %TURBINE Specific turbine in a wind farm
    %   Detailed explanation goes here
    
    properties
        turbineType
        locIf
    end
    
    methods
        function obj = turbine(turbineType, locIf)
            %TURBINE Construct an instance of this class
            %   Detailed explanation goes here
            obj.turbineType = turbineType;
            obj.locIf = locIf;
        end
    end
end

