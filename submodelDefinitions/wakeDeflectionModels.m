function [displ_y,displ_z] = wakeDeflectionModels(modelData,deltaxs,turbine)

%% Wake deflection model choice
% Herein we define the wake deflection model we want to use, which can be
% either from Jimenez et al. (2009) with doi:10.1002/we.380, or from
% Bastankah and Porte-Agel (2016) with doi:10.1017/jfm.2016.595. The
% traditional FLORIS uses Jimenez, while the new FLORIS model presented
% by Annoni uses Porte-Agel's deflection model.
switch modelData.deflectionModel
    
    %% Porte-Agel (2016) wake deflection model
    case 'PorteAgel'
        Ct = turbine.Ct;
        Ti = turbine.TI;
        R = floris_eul2rotm(-[turbine.YawWF turbine.Tilt 0],'ZYZ');
        C = R(2:3,2:3)*(R(2:3,2:3).');
        
        % Eq. 7.3, x0 is the start of the far wake
        x0 = 2*turbine.rotorRadius*(cos(turbine.ThrustAngle).*(1+sqrt(1-Ct)))./...
            (sqrt(2)*(modelData.alpha*Ti + modelData.beta*(1-sqrt(1-Ct))));
        % Eq. 6.12
        theta_C0 = ((0.3*turbine.ThrustAngle)./cos(turbine.ThrustAngle)).*...
            (1-sqrt(1-turbine.Ct.*cos(turbine.ThrustAngle)));  % skew angle in near wake
        
        ky = @(I) modelData.ka*I + modelData.kb;
        kz = @(I) modelData.ka*I + modelData.kb;

        % sigNeutralx0 is the wake standard deviation in the case of an
        % alligned turbine. This expression uses: Ur./(Uinf+U0) = approx 1/2
        sigNeutral_x0 = eye(2)*turbine.rotorRadius*sqrt(1/2);
        varWake = @(x) mmat(repmat(C,1,1,length(x)),...
            (  repmat(diag([ky(Ti) kz(Ti)]),[1,1,length(x)])...
            .* repmat(reshape((x-x0),1,1,length(x)),2,2,1)...
            +  repmat(sigNeutral_x0,1,1,length(x))   ).^2);
        % varWake updated matrix definitions for backwards compatibility. Previously:
        %         varWake = @(x) mmat(zeros(2,2,length(x))+C,(repmat(diag([inputData.ky(Ti) ...
        %         inputData.kz(Ti)]),[1,1,length(x)]).*reshape((x-x0),1,1,length(x))+sigNeutral_x0).^2);
        vecdet = @(ar) ar(1,1,:).*ar(2,2,:)-ar(1,2,:).*ar(2,1,:);
        
        % Terms that are used in eq 7.4
        lnInnerTerm = @(x) sqrt(sqrt(squeeze(vecdet(mmat(varWake(x),inv(C*sigNeutral_x0.^2))))));
        lnTerm = @(x) log(((1.6+sqrt(Ct))*(1.6*lnInnerTerm(x)-sqrt(Ct)))./...
            ((1.6-sqrt(Ct))*(1.6*lnInnerTerm(x)+sqrt(Ct))));
        % displacement at the end of the near wake
        delta_x0 = tan(theta_C0)*x0;
        
        % Eq. 7.4
        FW_delta = @(x) delta_x0+theta_C0*(turbine.rotorRadius/7.35)*...
            sqrt(sqrt(det(C/((diag([ky(Ti) kz(Ti)])*Ct)^2))))*...
            (2.9+1.3*sqrt(1-Ct)-Ct)*lnTerm(x).';
        
        %         FW_delta = @(x) delta_x0+theta_C0*(turbine.rotorRadius/7.35)*...
        %             sqrt(cos(turbine.ThrustAngle)/(inputData.ky(Ti)*inputData.kz(Ti)*Ct))*...
        %             (2.9+1.3*sqrt(1-Ct)-Ct)*lnTerm(x).';
        
        NW_delta = @(x) delta_x0*x/x0;
        displacements = NW_delta(deltaxs).*(deltaxs<=x0)+FW_delta(deltaxs).*(deltaxs>x0);
        % wakeDir = rotx(90)*turbine.wakeNormal; % Original equation
        wakeDir = [1 0 0; 0 0 -1;0 1 0]*turbine.wakeNormal; % Evaluated to remove Toolbox dependencies
        
        % Determine wake centerline position of this turbine at location x
        displ_y = turbine.LocWF(2) + wakeDir(2)*displacements + ...  % initial position + yaw induced offset
            (modelData.ad + deltaxs * modelData.bd); % bladerotation-induced lateral offset
        
        displ_z = turbine.LocWF(3) + wakeDir(3)*displacements + ...  % initial position + yaw*tilt induced offset
            (modelData.at + deltaxs * modelData.bt); % bladerotation-induced vertical offset
        
        
        
    %% Jimenez (2014) wake deflection model 
    case 'Jimenez'
        % Calculate initial wake deflection due to blade rotation etc.
        wake.zetaInit = 0.5*sin(turbine.ThrustAngle)*turbine.Ct; % Eq. 8
        
        % Add an initial wakeangle to the zeta
        if modelData.useWakeAngle
            % Rodriques rotation formula to rotate 'v', 'th' radians around 'k'
            rod = @(v,th,k) v*cos(th)+cross(k,v)*sin(th)+k*dot(k,v)*(1-cos(th));
            % Compute initial direction of wake unadjusted
            initDir = rod([1;0;0],wake.zetaInit,turbine.wakeNormal);
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
        wakeDir = [1 0 0;0 0 1;0 -1 0]*turbine.wakeNormal; % Evaluated to remove Toolbox dependencies
        
        % Calculate wake displacements as described in Jimenez
        factors       = (modelData.KdY*deltaxs/turbine.rotorRadius)+1;
        displacements = (wake.zetaInit*(15*(factors.^4)+(wake.zetaInit^2))./ ...
            ((15*modelData.KdY*(factors.^5))/turbine.rotorRadius))- ...
            (wake.zetaInit*turbine.rotorRadius*...
            (15+(wake.zetaInit^2))/(15*modelData.KdY));
        
        % Determine wake centerline position of this turbine at location x
        displ_y = turbine.LocWF(2) + wakeDir(2)*displacements + ...  % initial position + yaw induced offset
            (modelData.ad + deltaxs * modelData.bd); % bladerotation-induced lateral offset
        
        displ_z = turbine.LocWF(3) + wakeDir(3)*displacements + ...  % initial position + yaw*tilt induced offset
            (modelData.at + deltaxs * modelData.bt); % bladerotation-induced vertical offset
        
        
        
    otherwise
        error(['Deflection model with name ''' modelData.deflectionModel ''' not specified. (Note: input is case-sensitive)']);
end
end

