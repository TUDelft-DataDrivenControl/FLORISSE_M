classdef larsen_velocity < velocity_interface
    %jensen_gaussian_VELOCITY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Area
        ct
        c1Lars
        x0
    end
    
    methods
        function obj = larsen_velocity(modelData, turbine, turbineCondition, turbineControl, turbineResult)
            %jensen_gaussian_VELOCITY Construct an instance of this class
            %   Detailed explanation goes here
            
            % Initial wake radius [m]
            obj.Area = turbine.turbineType.rotorArea;
            % Store the thrust coefficient
            obj.ct = turbineResult.ct;
            
            D = 2*turbine.turbineType.rotorRadius;    % Rotor diameter
            H = turbine.turbineType.hubHeight;       % Turbine hub height [m]

            RnbLars = D*max(1.08,1.08+21.7*(turbineCondition.TI-0.05));
            R95Lars = 0.5*(RnbLars+min(H,RnbLars));
            DeffLars = D*sqrt((1+sqrt(1-obj.ct))/(2*sqrt(1-obj.ct)));

            obj.x0 = 9.5*D/((2*R95Lars/DeffLars)^3-1);
            obj.c1Lars = (DeffLars/2)^(5/2)*(105/(2*pi))^(-1/2)*(obj.ct*obj.Area*obj.x0).^(-5/6);
        end
        
        function Vdeficit = deficit(obj, x, y, z)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            Vdeficit  = ((1/9)*(obj.ct.*obj.Area.*((obj.x0+x).^-2)).^(1/3).* ...
                (hypot(y,z).^(3/2).*((3.*obj.c1Lars.^2).*obj.ct.*obj.Area.*(obj.x0+x)).^(-1/2) - ...
                (35/(2.*pi)).^(3/10).*(3.*obj.c1Lars^2).^(-1/5) ).^2);
        end
        function booleanMap = boundary(obj, x, y, z)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            booleanMap = hypot(y,z)<((35/(2*pi))^(1/5)*(3*(obj.c1Lars)^2)^(1/5)*((x).*obj.ct*obj.Area).^(1/3));
        end
    end
end
