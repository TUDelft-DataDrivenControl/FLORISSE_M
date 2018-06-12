classdef ambient_inflow_log < ambient_inflow_interface
    %AMBIENT_INFLOW_LOG Creates an ambientInflow object with a logarithmic
    
    properties
        Vref % Wind velocity
        Href % Reference height for logarithmic velocity inflow profile
        windDirection % Wind direction in radians
        TI0 % Atmospheric turbulence intensity
        rho % Air density
    end
    
    methods
        % TODO: Use inputParser
        function obj = ambient_inflow_log(VvString, Vref, ...
                                          HString, Href, ...
                                          WDString, windDirection, ...
                                          TIString, TI0)
            %AMBIENT_INFLOW_LOG Construct an instance of this class
            obj.Vref = Vref;
            obj.Href = Href;
            obj.windDirection = windDirection;
            obj.TI0 = TI0;
            obj.rho = 1.1716;
        end
        
        function V = Vfun(obj, Z)
            %VFUN describes the inflow velocity profile
            alpha = 0.14;
            V = obj.Vref*(Z/obj.Href).^alpha;
        end
    end
end
