function [ wake ] = floris_wakeCenterLinePosition( inputData,turbine,wake )
    if strcmp(inputData.wakeType,'PorteAgel')
        wake.centerLine(2,:) = turbine.LocWF(2);
        wake.centerLine(3,:) = turbine.LocWF(3);
    else
        % WakeDirection is used to determine the plane into which the wake is
        % displaced. displacement*wakeDir + linearOffset = centerlinePosition
        wakeDir = rotx(-90)*turbine.wakeNormal;

        deltaxs = wake.centerLine(1,:)-turbine.LocWF(1);
        % Calculate wake displacements as described in Jimenez
        factors       = (inputData.KdY*deltaxs/turbine.rotorRadius)+1;
        displacements = (wake.zetaInit*(15*(factors.^4)+(wake.zetaInit^2))./ ...
                       ((15*inputData.KdY*(factors.^5))/turbine.rotorRadius))- ...
                       (wake.zetaInit*turbine.rotorRadius*...
                       (15+(wake.zetaInit^2))/(15*inputData.KdY));

        % Wake centerLine position of this turbine at location x
        wake.centerLine(2,:) = turbine.LocWF(2) + wakeDir(2)*displacements + ...      % initial position + yaw induced offset
                        (1-inputData.useWakeAngle) *(inputData.ad + deltaxs * inputData.bd); % bladerotation-induced lateral offset

        wake.centerLine(3,:) = turbine.LocWF(3) + wakeDir(3)*displacements;       % initial position + yaw*tilt induced offset
    end
end