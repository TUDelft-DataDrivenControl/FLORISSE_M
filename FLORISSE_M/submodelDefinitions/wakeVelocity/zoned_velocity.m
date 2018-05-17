classdef zoned_velocity < velocity_interface
    %ZONED_VELOCITY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        wakeRadiusInit
        a
        Ke
        mU
        me
    end
    
    methods
        function obj = zoned_velocity(modelData, turbine, turbineCondition, turbineControl, turbineResult)
            %ZONED_VELOCITY Construct an instance of this class
            %   Detailed explanation goes here
            
            % Initial wake radius [m]
            obj.wakeRadiusInit = turbine.turbineType.rotorRadius;
            % Store the axial induction
            obj.a = turbineResult.axialInduction;
            % Calculate ke, the basic expansion coefficient
            obj.Ke = modelData.Ke + modelData.KeCorrCT*(turbineResult.ct-modelData.baselineCT);
            obj.me = modelData.me;

            % Calculate mU, the zone multiplier for different wake zones
            if modelData.useaUbU
                obj.mU = modelData.MU/cos(modelData.aU+modelData.bU*turbineControl.yawAngle);
            else
                obj.mU = modelData.MU;
            end
        end
        
        function Vdeficit = deficit(obj, x, y, z)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            % Meshgrid of radii
            r = hypot(y,z);
            % Radius of wake zones [m]
            rZones = @(x,zone) max(obj.wakeRadiusInit+obj.Ke.*obj.me(zone)*x,0*x);

            % Center location of wake zones [m]
            cZones = @(x,zone) (obj.wakeRadiusInit./(obj.wakeRadiusInit + obj.Ke.*obj.mU(zone).*x)).^2;

            % cFull is the wake intensity reduction factor
            cFull = ((abs(r)<=rZones(x,3))-(abs(r)<rZones(x,2))).*cZones(x,3)+...
                ((abs(r)<rZones(x,2))-(abs(r)<rZones(x,1))).*cZones(x,2)+...
                (abs(r)<rZones(x,1)).*cZones(x,1);

            % wake.V is an analytical function for flow speed [m/s] in a single wake
            Vdeficit = 2*obj.a*cFull;
        end
        function booleanMap = boundary(obj, x, y, z)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here

            % wake.boundary is a boolean function telling whether a point (y,z)
            % lies within the wake radius of turbine(i) at distance x
            booleanMap = hypot(y,z)<(obj.wakeRadiusInit+obj.Ke.*obj.me(3)*x);
        end
    end
end

