function [displ_y,displ_z] = jimenez_deflection(turbineResults,turbineCondition,turbineControl)
%JIMENEZ_DEFLECTION Summary of this function goes here
%   Detailed explanation goes here

% Jimenez (2014) wake deflection model 
% Calculate initial wake deflection due to blade rotation etc.
wake.zetaInit = 0.5*sin(turbineControl.ThrustAngle)*turbineResults.Ct; % Eq. 8

% Add an initial wakeangle to the zeta
if modelData.useWakeAngle
    % Rodriques rotation formula to rotate 'v', 'th' radians around 'k'
    rod = @(v,th,k) v*cos(th)+cross(k,v)*sin(th)+k*dot(k,v)*(1-cos(th));
    % Compute initial direction of wake unadjusted
    initDir = rod([1;0;0],wake.zetaInit,turbineControl.wakeNormal);
    % Initial wake direction adjusted for initial wake angle kd
    floris_rotz = @(x) [cosd(x) -sind(x) 0; sind(x) cosd(x) 0; 0 0 1];
    wakeVector = floris_rotz(rad2deg(modelData.kd))*initDir;
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
wakeDir = [1 0 0;0 0 1;0 -1 0]*turbineControl.wakeNormal; % Evaluated to remove Toolbox dependencies

% Calculate wake displacements as described in Jimenez
factors       = (modelData.KdY*deltaxs/turbine.rotorRadius)+1;
displacements = (wake.zetaInit*(15*(factors.^4)+(wake.zetaInit^2))./ ...
    ((15*modelData.KdY*(factors.^5))/turbine.rotorRadius))- ...
    (wake.zetaInit*turbine.rotorRadius*...
    (15+(wake.zetaInit^2))/(15*modelData.KdY));

% Determine wake centerline position of this turbine at location x
displ_y = turbine.LocWF(2) + wakeDir(2)*displacements + ...  % initial position + yaw induced offset
    (modelData.ad*(2*turbine.rotorRadius) + deltaxs * modelData.bd); % bladerotation-induced lateral offset

displ_z = turbine.LocWF(3) + wakeDir(3)*displacements + ...  % initial position + yaw*tilt induced offset
    (modelData.at*(2*turbine.rotorRadius) + deltaxs * modelData.bt); % bladerotation-induced vertical offset

end

