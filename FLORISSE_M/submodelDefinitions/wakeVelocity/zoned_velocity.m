classdef zoned_velocity < velocity_interface
    %ZONED_VELOCITY Wake velocity object implementing the zoned wake
    %model from Gebraad. More details can be found in :cite:`Gebraad2014`.
    
    properties
        wakeRadiusInit % Initial wake radius
        a % Axial induction factor
        Ke % Base expansion coefficient
        mU % Zone multiplier for recovery
        me % Zone multiplier for expansion
    end
    
    methods
        function obj = zoned_velocity(modelData, turbine, turbineCondition, turbineControl, turbineResult)
            %ZONED_VELOCITY Construct an instance of this class
            
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
            %DEFICIT Compute the velocity deficit at a certain position
            
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
            %BOUNDARY Determine if a coordinate is inside the wake

            % wake.boundary is a boolean function telling whether a point (y,z)
            % lies within the wake radius of turbine(i) at distance x
            booleanMap = hypot(y,z)<(obj.wakeRadiusInit+obj.Ke.*obj.me(3)*x);
        end
    end
end

