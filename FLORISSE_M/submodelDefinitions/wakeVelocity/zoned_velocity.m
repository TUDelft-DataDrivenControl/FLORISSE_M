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
                obj.mU = modelData.MU/cos(modelData.aU+modelData.bU*turbineControl.yawAngleWF);
            else
                obj.mU = modelData.MU;
            end
        end
        
        function Vdeficit = deficit(obj, x, y, z)
            %DEFICIT Compute the velocity deficit at a certain position
            
            % Meshgrid of radii
            r = hypot(y,z);

            % cFull is the wake intensity reduction factor
            cFull = ((abs(r)<=obj.rZones(x,3))-(abs(r)<obj.rZones(x,2))).*obj.cZones(x,3)+...
                ((abs(r)<obj.rZones(x,2))-(abs(r)<obj.rZones(x,1))).*obj.cZones(x,2)+...
                (abs(r)<obj.rZones(x,1)).*obj.cZones(x,1);

            % wake.V is an analytical function for flow speed [m/s] in a single wake
            Vdeficit = 2*obj.a*cFull;
        end
        
        function r = rZones(obj, x, zone)
            % Radius of wake zones [m]
            r = max(obj.wakeRadiusInit+obj.Ke.*obj.me(zone)*x,0*x);
        end
        
        function c = cZones(obj, x, zone)
            % Relative velocity deficit in wake zone [], scales axial induction
            c = (obj.wakeRadiusInit./(obj.wakeRadiusInit + obj.Ke.*obj.mU(zone).*x)).^2;
        end
        
        function booleanMap = boundary(obj, x, y, z)
            %BOUNDARY Determine if a coordinate is inside the wake

            % wake.boundary is a boolean function telling whether a point (y,z)
            % lies within the wake radius of turbine(i) at distance x
            booleanMap = hypot(y,z)<(obj.wakeRadiusInit+obj.Ke.*obj.me(3)*x);
        end
        
        function [overlap, RVdef] = deficit_integral(obj, deltax, dy, dz, rotRadius)
            Q   = 0;
            wakeOverlapTurb = [0 0 0];
            for zone = 1:3
                wakeOverlapTurb(zone) = obj.floris_intersect(obj.rZones(deltax,zone), rotRadius, hypot(dy,dz));

                for zonej = 1:(zone-1) % minus overlap areas of lower zones
                    wakeOverlapTurb(zone) = wakeOverlapTurb(zone)-wakeOverlapTurb(zonej);
                end
                Q = Q + 2*obj.a*obj.cZones(deltax,zone)*wakeOverlapTurb(zone);
            end
            
            rotorArea = pi * rotRadius^2;
            % Relative volumetric flowrate through swept area
            RVdef = 1-Q/rotorArea;
            % Estimate the size of the area affected by the wake
            overlap = sum(wakeOverlapTurb(:))/(rotorArea);
        end
    end
    methods(Static)
        function [ Aol ] = floris_intersect( R, r, d )
            %floris_intersect 
            %   Calculates the overlap area between two circles on the same line,
            %   displaced with distance d and with radii R and r
            d = abs(d);
            if d >= R+r  % if not contained at all
                Aol = 0;   
            elseif d <= abs(R-r) % if one is contained completely in the other circle
                Aol = pi*min(abs([r, R]))^2;
            else
                Aol = r^2*acos((d^2+r^2-R^2)/(2*d*r)) + R^2*acos((d^2+R^2-r^2)/(2*d*R)) - ...
                      0.5*sqrt((-d+r+R)*(d+r-R)*(d-r+R)*(d+r+R));
            end
        end
    end
end

