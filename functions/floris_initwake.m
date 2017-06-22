function [ wake ] = floris_initwake( inputData,turbine,wake )
% This function computes the coefficients that determine wake behaviour.
% The initial deflection and diameter of the wake are also computed

    % Calculate ke, the basic expansion coefficient
    wake.Ke = inputData.Ke + inputData.KeCorrCT*(turbine.Ct-inputData.baselineCT);

    % Calculate mU, the zone multiplier for different wake zones
    if inputData.useaUbU
        wake.mU = inputData.MU/cos(inputData.aU+inputData.bU*turbine.YawWF);
    else
        wake.mU = inputData.MU;
    end

    % Calculate initial wake deflection due to blade rotation etc.
    wake.zetaInit = 0.5*sin(turbine.YawWF)*turbine.Ct; % Eq. 8
    
    % Add an initial wakeangle to the zeta
    if inputData.useWakeAngle
        wake.zetaInit = wake.zetaInit + inputData.kd;
    end;

    % Calculate initial wake diameter
    if inputData.adjustInitialWakeDiamToYaw
        wake.wakeDiameterInit = turbine.rotorDiameter*cos(turbine.YawWF);
    else
        wake.wakeDiameterInit = turbine.rotorDiameter;
    end
end