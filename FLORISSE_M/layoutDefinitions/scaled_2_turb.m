classdef scaled_2_turb < layout_prototype
    %scaled_2_turb Summary of this class goes here
    %   Detailed explanation goes here
    properties
        turbines
        uniqueTurbineTypes
    end
    
    methods
        function obj = scaled_2_turb
            %GENERIC_6_TURB Construct an instance of this class
            %   Detailed explanation goes here
            TUMG1TurbType = tum_g1;
            D = 2*TUMG1TurbType.rotorRadius;
            
            % Wind turbine location in inertial frame [x, y], multiplied with D
            locIf = {D*[0,    .5];
                     D*[0,    5]};

            % Put all the turbines in a struct array
            obj.turbines = struct('turbineType', TUMG1TurbType, ...
                                  'locIf',         locIf);
            obj.uniqueTurbineTypes = {TUMG1TurbType};
        end
    end
end

