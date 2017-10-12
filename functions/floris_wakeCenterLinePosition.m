function [ wake ] = floris_wakeCenterLinePosition( inputData,turbine,wake )
%Compute the wake centerline position using the method explained by Jimenez
%or PorteAgel.

    % Displacement between location 'x' and current turbine
    deltaxs = wake.centerLine(1,:)-turbine.LocWF(1);
    
    switch inputData.deflType
    case 'Jimenez'
        % Calculate initial wake deflection due to blade rotation etc.
        wake.zetaInit = 0.5*sin(turbine.ThrustAngle)*turbine.Ct; % Eq. 8
        
        % Add an initial wakeangle to the zeta
        if inputData.useWakeAngle
            % Rodriques rotation formula to rotate 'v', 'th' radians around 'k'
            rod = @(v,th,k) v*cos(th)+cross(k,v)*sin(th)+k*dot(k,v)*(1-cos(th));
            % Compute initial direction of wake unadjusted
            initDir = rod([1;0;0],wake.zetaInit,turbine.wakeNormal);
            % Initial wake direction adjusted for initial wake angle kd
            wakeVector = rotz(rad2deg(inputData.kd))*initDir;
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
        Ct = turbine.Ct;
        Ti = turbine.TI;
        R = eul2rotm(-[turbine.YawWF turbine.Tilt 0],'ZYZ');
        C = R(2:3,2:3)*(R(2:3,2:3).');
        
        % Eq. 7.3, x0 is the start of the far wake
        x0 = 2*turbine.rotorRadius*(cos(turbine.ThrustAngle).*(1+sqrt(1-Ct)))./...
                (sqrt(2)*(inputData.alpha*Ti + inputData.beta*(1-sqrt(1-Ct))));
        % Eq. 6.12
        theta_C0 = ((0.3*turbine.ThrustAngle)./cos(turbine.ThrustAngle)).*...
            (1-sqrt(1-turbine.Ct.*cos(turbine.ThrustAngle)));  % skew angle in near wake

        % sigNeutralx0 is the wake standard deviation in the case of an
        % alligned turbine. This expression uses: Ur./(Uinf+U0) = approx 1/2
        sigNeutral_x0 = eye(2)*turbine.rotorRadius*sqrt(1/2);
        varWake = @(x) mmat(zeros(2,2,length(x))+C,...
            (repmat(diag([inputData.ky(Ti) inputData.kz(Ti)]),[1,1,length(x)]).*...
            reshape((x-x0),1,1,length(x))+sigNeutral_x0).^2);
        vecdet = @(ar) ar(1,1,:).*ar(2,2,:)-ar(1,2,:).*ar(2,1,:);
        
        % Terms that are used in eq 7.4
        lnInnerTerm = @(x) sqrt(sqrt(squeeze(vecdet(mmat(varWake(x),inv(C*sigNeutral_x0.^2))))));
        lnTerm = @(x) log(((1.6+sqrt(Ct))*(1.6*lnInnerTerm(x)-sqrt(Ct)))./...
            ((1.6-sqrt(Ct))*(1.6*lnInnerTerm(x)+sqrt(Ct))));
        % displacement at the end of the near wake
        delta_x0 = tan(theta_C0)*x0;
        
        % Eq. 7.4
        FW_delta = @(x) delta_x0+theta_C0*(turbine.rotorRadius/7.35)*...
            sqrt(sqrt(det(C/((diag([inputData.ky(Ti) inputData.kz(Ti)])*Ct)^2))))*...
            (2.9+1.3*sqrt(1-Ct)-Ct)*lnTerm(x).';
        
%         FW_delta = @(x) delta_x0+theta_C0*(turbine.rotorRadius/7.35)*...
%             sqrt(cos(turbine.ThrustAngle)/(inputData.ky(Ti)*inputData.kz(Ti)*Ct))*...
%             (2.9+1.3*sqrt(1-Ct)-Ct)*lnTerm(x).';
        
        NW_delta = @(x) delta_x0*x/x0;
        displacements = NW_delta(deltaxs).*(deltaxs<=x0)+FW_delta(deltaxs).*(deltaxs>x0);
        
        wakeDir = rotx(90)*turbine.wakeNormal;
        wake.centerLine(2,:) = turbine.LocWF(2) + wakeDir(2)*displacements;
        wake.centerLine(3,:) = turbine.LocWF(3) + wakeDir(3)*displacements;  

    otherwise
        error(['Deflection type with name "' deflType '" not defined']);
    end
    if strcmp(inputData.wakeType,'PorteAgel')
        

    else
    end
end