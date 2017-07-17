function [ wake ] = floris_initwake( inputData,turbine,wake )
% This function computes the coefficients that determine wake behaviour.
% The initial deflection and diameter of the wake are also computed

    % Rodriques rotation formula to rotate 'v', 'th' radians around 'k'
    rod = @(v,th,k) v*cos(th)+cross(k,v)*sin(th)+k*dot(k,v)*(1-cos(th));
    normalize = @(v) v./norm(v);
    
    % Calculate ke, the basic expansion coefficient
    wake.Ke = inputData.Ke + inputData.KeCorrCT*(turbine.Ct-inputData.baselineCT);

    % Calculate mU, the zone multiplier for different wake zones
    if inputData.useaUbU
        wake.mU = inputData.MU/cos(inputData.aU+inputData.bU*turbine.YawWF);
    else
        wake.mU = inputData.MU;
    end

    % Calculate initial wake deflection due to blade rotation etc.
    wake.zetaInit = 0.5*sin(turbine.ThrustAngle)*turbine.Ct; % Eq. 8

    % Add an initial wakeangle to the zeta
    if inputData.useWakeAngle
        % Compute initial direction of wake unadjusted
        initDir = rod([1;0;0],wake.zetaInit,turbine.wakeNormal);
        % Inital wake direction adjust for inital wake angle kd
        wakeVector = rotz(rad2deg(inputData.kd))*initDir;
        wake.zetaInit = acos(dot(wakeVector,[1;0;0]));
        
        if wakeVector(1)==1
            turbine.wakeNormal = [0 0 1].';
        else
            turbine.wakeNormal = normalize(cross([1;0;0],wakeVector));
        end
    end
    
    % Calculate initial wake diameter
    if inputData.adjustInitialWakeDiamToYaw
        wake.wakeRadiusInit = turbine.rotorRadius*cos(turbine.ThrustAngle);
    else
        wake.wakeRadiusInit = turbine.rotorRadius;
    end
    
%     % Calculate initial wake deflection due to blade rotation etc.
%     wake.zetaInit = 0.5*sin(turbine.YawWF)*turbine.Ct; % Eq. 8
%     
%     % Add an initial wakeangle to the zeta
%     if inputData.useWakeAngle
%         wake.zetaInit = wake.zetaInit + inputData.kd;
%     end;
% 
%     % Calculate initial wake diameter
%     if inputData.adjustInitialWakeDiamToYaw
%         wake.wakeRadiusInit = turbine.rotorRadius*cos(turbine.YawWF);
%     else
%         wake.wakeRadiusInit = turbine.rotorRadius;
%     end
end