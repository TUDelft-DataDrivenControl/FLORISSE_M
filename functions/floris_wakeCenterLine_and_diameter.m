function [ wake ] = floris_wakeCenterLine_and_diameter( inputData,turbine,wake )

    for sample_x = 1:length(wake.centerLine)
        deltax = wake.centerLine(1,sample_x)-turbine.LocWF(1);
        if deltax >= 0
            % Calculate wake location delta Y: Eq. 8-12
            factor       = (2*inputData.KdY*deltax/turbine.rotorDiameter)+1;
            displacement = (wake.zetaInit*(15*(factor^4)+(wake.zetaInit^2))/ ...
                           ((30*inputData.KdY*(factor^5))/turbine.rotorDiameter))- ...
                           (wake.zetaInit*turbine.rotorDiameter*...
                           (15+(wake.zetaInit^2))/(30*inputData.KdY));

            % Wake centerLine position of this turbine at location x
%             wake.centerLine(2,sample_x) = turbine.LocWF(2) + displacement + ...                   % initial position + yaw induced offset
%                                         (1-model.useWakeAngle) *(model.ad + deltax * model.bd); % bladerotation-induced lateral offset
            % The originial matlab-FLORIS takes the wake angle outside the parenthesis?
            wake.centerLine(2,sample_x) = turbine.LocWF(2) +inputData.ad + displacement + ...                   % initial position + yaw induced offset
                            (1-inputData.useWakeAngle) *(deltax * inputData.bd); % bladerotation-induced lateral offset
           
           % Calculate wake diameter for zones 1-3: Eq. 13
           for zone = 1:3
               wake.diameters(sample_x,zone) = max(wake.wakeDiameterInit + 2*wake.Ke*inputData.me(zone)*deltax,0);
           end
        end
    end
end