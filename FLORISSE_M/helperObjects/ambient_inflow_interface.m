classdef ambient_inflow_interface < handle
    %AMBIENT_INFLOW_INTERFACE defines how ambientInflow objects should behave
    
    properties (Abstract)
        Vref % Wind velocity
        windDirection % Wind direction in radians
        TI0 % Atmospheric turbulence intensity
        rho % Air density
    end
    methods (Abstract)
        Vfun(obj, Z) % Function that describes the inflow velocity profile
    end
end
