function [ wake ] = floris_wakeCenterLinePosition( inputData,turbine,wake )

    deltaxs = wake.centerLine(1,:)-turbine.LocWF(1);
    switch inputData.deflType
    case 'Jimenez'
        % Rodriques rotation formula to rotate 'v', 'th' radians around 'k'
        rod = @(v,th,k) v*cos(th)+cross(k,v)*sin(th)+k*dot(k,v)*(1-cos(th));
        normalize = @(v) v./norm(v);

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
        % WakeDirection is used to determine the plane into which the wake is
        % displaced. displacement*wakeDir + linearOffset = centerlinePosition
        wakeDir = rotx(-90)*turbine.wakeNormal;
    
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
    case 'PorteAgel'
        turbine.ThrustAngle = -turbine.ThrustAngle;
        wakeDir = rotx(-90)*turbine.wakeNormal;
        D = 2*turbine.rotorRadius;
%         A = pi*turbine.rotorRadius^2;
%         H = turbine.hub_height;
        
        Ti = inputData.TI_0;% TODO: Implement turbulence model
        
        % x0 is the start of the far wake
        x0 = D.*(cos(turbine.ThrustAngle).*(1+sqrt(1-turbine.Ct.*cos(turbine.ThrustAngle))))...
            ./ (sqrt(2)*(inputData.alpha*Ti + inputData.beta*(1-sqrt(1-turbine.Ct))));
        theta_C0 = ((0.3*turbine.ThrustAngle)./cos(turbine.ThrustAngle)).*...
            (1-sqrt(1-turbine.Ct.*cos(turbine.ThrustAngle)));  % skew angle in near wake
        
        % TODO continue implementing porte agel
        displacements = theta_C0*deltaxs.*(deltaxs<=x0)+theta_C0*x0.*(deltaxs>x0);
        
        wake.centerLine(2,:) = turbine.LocWF(2) + wakeDir(2)*displacements;
        wake.centerLine(3,:) = turbine.LocWF(3) + wakeDir(3)*displacements;  
                turbine.ThrustAngle = -turbine.ThrustAngle;

    otherwise
        error(['Deflection type with name "' deflType '" not defined']);
    end
    if strcmp(inputData.wakeType,'PorteAgel')
        

    else
    end
end