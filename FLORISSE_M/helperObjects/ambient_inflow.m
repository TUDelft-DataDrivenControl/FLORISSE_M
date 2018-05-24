classdef ambient_inflow < handle
    %AMBIENT_INFLOW is a small helper object that holds the flow conditions
    %and describes the velocity profile used in the FLORIS simulation
    %   Detailed explanation goes here
    
    properties
        Vref
        Href
        windDirection
        TI0
        rho
    end
    
    methods
        % TODO: Use inputParser
        function obj = ambient_inflow(~,Vref, ~,Href, ~,windDirection, ~,TI0)
            %AMBIENT_INFLOW Construct an instance of this class
            %   Detailed explanation goes here
            obj.Vref = Vref;
            obj.Href = Href;
            obj.windDirection = windDirection;
            obj.TI0 = TI0;
            obj.rho = 1.1716;
        end
        
        function V = Vfun(obj, Z)
            %VFUN Vfun is a function that described the inflow velocity profile
            %   This function can be changed or overwritten by other
            %   velocity profiles or for example a constant
            alpha = 0.14;
            V = obj.Vref*(Z/obj.Href).^alpha;
        end
    end
end
