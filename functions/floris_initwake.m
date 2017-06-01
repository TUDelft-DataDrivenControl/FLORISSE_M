function [ wake ] = floris_initwake( model,turbine,wake,turb_type )
% This function computes the coefficients that determine wake behaviour.
% The initial deflection and diameter of the wake are also computed
    
    % Rodriques rotation formula to rotate 'v', 'th' radians around 'k'
    rod = @(v,th,k) v*cos(th)+cross(k,v)*sin(th)+k*dot(k,v)*(1-cos(th));
    normalize = @(v) v./norm(v);

    % Calculate ke, the basic expansion coefficient
    wake.Ke = model.Ke + model.KeCorrCT*(turbine.Ct-model.baselineCT);

    % Calculate mU, the zone multiplier for different wake zones
    if model.useaUbU
        wake.mU = model.MU/cos(model.aU+model.bU*turbine.ThrustAngle);
    else
        wake.mU = model.MU;
    end

    % Calculate initial wake deflection due to blade rotation etc.
    wake.zetaInit = 0.5*sin(turbine.ThrustAngle)*turbine.Ct; % Eq. 8

    % Add an initial wakeangle to the zeta
    if model.useWakeAngle
        % Compute initial direction of wake unadjusted
        initDir = rod([1;0;0],wake.zetaInit,turbine.wakeNormal);
        % Inital wake direction adjust for inital wake angle kd
        wakeVector = rotz(rad2deg(model.kd))*initDir;
        wake.zetaInit = acos(dot(wakeVector,[1;0;0]));
        
        if wakeVector(1)==1
            turbine.wakeNormal = [0 0 1].';
        else
            turbine.wakeNormal = normalize(cross([1;0;0],wakeVector));
        end
    end
    
    % Calculate initial wake diameter
    if model.adjustInitialWakeDiamToYaw
        wake.wakeDiameterInit = turb_type.rotorDiameter*cos(turbine.ThrustAngle);
    else
        wake.wakeDiameterInit = turb_type.rotorDiameter;
    end
end