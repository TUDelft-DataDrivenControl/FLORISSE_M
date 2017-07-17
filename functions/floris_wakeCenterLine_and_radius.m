function [ wake ] = floris_wakeCenterLine_and_radius( inputData,turbine,wake )

    % WakeDirection is used to determine the plane into which the wake is
    % displaced. displacement*wakeDir + linearOffset = centerlinePosition
    wakeDir = rotx(-90)*turbine.wakeNormal;
    
    for sample_x = 1:length(wake.centerLine)
        deltax = wake.centerLine(1,sample_x)-turbine.LocWF(1);
        if deltax >= 0
            % Calculate wake location delta Y: Eq. 8-12
            factor       = (inputData.KdY*deltax/turbine.rotorRadius)+1;
            displacement = (wake.zetaInit*(15*(factor^4)+(wake.zetaInit^2))/ ...
                           ((15*inputData.KdY*(factor^5))/turbine.rotorRadius))- ...
                           (wake.zetaInit*turbine.rotorRadius*...
                           (15+(wake.zetaInit^2))/(15*inputData.KdY));

            % Wake centerLine position of this turbine at location x
%  Possible correction: (1-inputData.useWakeAngle) *(inputData.ad + deltax * inputData.bd); 
            wake.centerLine(2,sample_x) = turbine.LocWF(2) + inputData.ad + wakeDir(2)*displacement + ...  % initial position + yaw induced offset
                            (1-inputData.useWakeAngle) *(deltax * inputData.bd);                % bladerotation-induced lateral offset
            
            wake.centerLine(3,sample_x) = turbine.LocWF(3) + wakeDir(3)*displacement;       % initial position + yaw*tilt induced offset

                        
           % Calculate wake diameter for zones 1-3: Eq. 13
           for zone = 1:3
               wake.radii(sample_x,zone) = max(wake.wakeRadiusInit + wake.Ke*inputData.me(zone)*deltax,0);
           end
        end
    end
end