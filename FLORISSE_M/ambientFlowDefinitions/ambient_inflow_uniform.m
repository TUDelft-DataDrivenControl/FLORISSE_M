classdef ambient_inflow_uniform < ambient_inflow_interface
    %AMBIENT_INFLOW_UNIFORM Creates an ambientInflow object with a uniform
    %velocity profile
    
    properties
        Vref % Wind velocity
        windDirection % Wind direction in radians
        TI0 % Atmospheric turbulence intensity
        rho % Air density
    end
    
    methods
        % TODO: Use inputParser
        function obj = ambient_inflow_uniform(VString, Vref, ...
                                              WDString ,windDirection, ...
                                              TIString, TI0)
            %AMBIENT_INFLOW_UNIFORM Construct an instance of this class
            obj.Vref = Vref;
            obj.windDirection = windDirection;
            obj.TI0 = TI0;
            obj.rho = 1.1716;
        end
        
        function V = Vfun(obj, Z)
            %VFUN describes the inflow velocity profile
            V = Z*0+obj.Vref;
        end
    end
end
