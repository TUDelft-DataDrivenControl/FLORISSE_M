classdef clwindcon_9_turb < layout_prototype
    %GENERIC_6_TURB Summary of this class goes here
    %   Detailed explanation goes here
    properties
        turbines
        uniqueTurbineTypes
    end
    
    methods
        function obj = clwindcon_9_turb
            %GENERIC_6_TURB Construct an instance of this class
            %   Detailed explanation goes here
            DTU10mwTurbType = dtu10mw;
            D = 2*DTU10mwTurbType.rotorRadius;
            locIf = {D*[19,    10.0];
                     D*[14,    10.0];
                     D*[9,     10.0];
                     D*[19,    5.0];
                     D*[14,    5.0];
                     D*[9,     5.0];
                     D*[19,    0.0];
                     D*[14,    0.0];
                     D*[9,     0.0]};
            
            % Put all the turbines in a struct array
            obj.turbines = struct('turbineType', DTU10mwTurbType , ...
                                  'locIf',         locIf);
            obj.uniqueTurbineTypes = {DTU10mwTurbType};
        end
    end
end

