% Calculate ke
ke(turbi) = model.ke + model.keCorrCT*(Ct(turbi)-model.baselineCT);

% Calculate mU: decay rate of wake zones
if model.useaUbU
    mU{turbi} = model.MU/cosd(model.aU+model.bU*yawAngles_wf(turbi));
else
    mU{turbi} = model.MU;
end;

% Calculate initial wake deflection
wakeAngleInit(turbi) = 0.5*sind(yawAngles_wf(turbi))*Ct(turbi); % Eq. 8
if model.useWakeAngle
    wakeAngleInit(turbi) = wakeAngleInit(turbi) + model.initialWakeAngle*pi/180;
end;

% Calculate initial wake diameter
if model.adjustInitialWakeDiamToYaw
    wakeDiameter0(turbi) = turb.rotorDiameter*cosd(yawAngles_wf(turbi));
else
    wakeDiameter0(turbi) = turb.rotorDiameter;
end;