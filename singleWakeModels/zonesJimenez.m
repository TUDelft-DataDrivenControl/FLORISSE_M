classdef zonesJimenez
    %ZONESJIMENEZ Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1
    end
    
    methods        
        function [wake] = deficit(self,inputData,turbine,wake)   
        % Calculate initial wake deflection due to blade rotation etc.
        wake.zetaInit = 0.5*sin(turbine.ThrustAngle)*turbine.Ct; % Eq. 8
        
        % Add an initial wakeangle to the zeta
        if inputData.useWakeAngle
            % Rodriques rotation formula to rotate 'v', 'th' radians around 'k'
            rod = @(v,th,k) v*cos(th)+cross(k,v)*sin(th)+k*dot(k,v)*(1-cos(th));
            % Compute initial direction of wake unadjusted
            initDir = rod([1;0;0],wake.zetaInit,turbine.wakeNormal);
            % Initial wake direction adjusted for initial wake angle kd
            floris_rotz = @(x) [cosd(x) -sind(x) 0; sind(x) cosd(x) 0; 0 0 1];
            wakeVector = floris_rotz(rad2deg(inputData.kd))*initDir;
            wake.zetaInit = acos(dot(wakeVector,[1;0;0]));

            if wakeVector(1)==1
                turbine.wakeNormal = [0 0 1].';
            else
                normalize = @(v) v./norm(v);
                turbine.wakeNormal = normalize(cross([1;0;0],wakeVector));
            end
        end
        
        % WakeDirection is used to determine the plane into which the wake is
        % displaced. displacement*wakeDir + linearOffset = centerlinePosition
        % A positive angle causes a negative displacement, for that reason
        % -90 is used.
        
        % wakeDir = rotx(-90)*turbine.wakeNormal; % Original equation
        wakeDir = [1 0 0;0 0 1;0 -1 0]*turbine.wakeNormal; % Evaluated to remove Toolbox dependencies
    
        % Calculate wake displacements as described in Jimenez
        factors       = (inputData.KdY*deltaxs/turbine.rotorRadius)+1;
        displacements = (wake.zetaInit*(15*(factors.^4)+(wake.zetaInit^2))./ ...
                       ((15*inputData.KdY*(factors.^5))/turbine.rotorRadius))- ...
                       (wake.zetaInit*turbine.rotorRadius*...
                       (15+(wake.zetaInit^2))/(15*inputData.KdY));
                   
        % Determine wake centerline position of this turbine at location x
        wake.centerLine(2,:) = turbine.LocWF(2) + wakeDir(2)*displacements + ...  % initial position + yaw induced offset
            (inputData.wakeModel.params.ad + deltaxs * inputData.wakeModel.params.bd); % bladerotation-induced lateral offset

        wake.centerLine(3,:) = turbine.LocWF(3) + wakeDir(3)*displacements + ...  % initial position + yaw*tilt induced offset
            (inputData.wakeModel.params.at + deltaxs * inputData.wakeModel.params.bt); % bladerotation-induced vertical offset
                   
        end
        
        %% Volumetric flow rate calculation
        function [Q] = flowrate(inputData,uw_wake,dw_turbine,deltax,turbLocIndex)
            Q   = dw_turbine.rotorArea;
            wakeOverlapTurb = [0 0 0];
            for zone = 1:3
               wakeOverlapTurb(zone) = floris_intersect(uw_wake.rZones(deltax,zone),dw_turbine.rotorRadius,...
                 hypot(dw_turbine.LocWF(2)-(uw_wake.centerLine(2,turbLocIndex)),...
                       dw_turbine.LocWF(3)-(uw_wake.centerLine(3,turbLocIndex))));

               for zonej = 1:(zone-1) % minus overlap areas of lower zones
                   wakeOverlapTurb(zone) = wakeOverlapTurb(zone)-wakeOverlapTurb(zonej);
               end
               Q = Q - 2*turbines(uw_turbi).axialInd*uw_wake.cZones(deltax,zone)*wakeOverlapTurb(zone);
            end            
        end
        
    end
end

