function [displ_y,displ_z] = rans_deficit_deflection(turbineResults,turbineCondition,turbineControl)
%PORTE_AGEL_DEFLECTION Summary of this function goes here
%   Detailed explanation goes here

% Shorthand for some parameters
Ct = turbineResults.Ct;
Ti = turbineCondition.TI;
R = floris_eul2rotm(-[turbineControl.YawWF turbineControl.Tilt 0],'ZYZ');
C = R(2:3,2:3)*(R(2:3,2:3).');

% Eq. 7.3, x0 is the start of the far wake
x0 = 2*turbine.rotorRadius*(cos(turbineControl.ThrustAngle).*(1+sqrt(1-Ct)))./...
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
    (modelData.ad*(2*turbine.rotorRadius) + deltaxs * modelData.bd); % bladerotation-induced lateral offset

displ_z = turbine.LocWF(3) + wakeDir(3)*displacements + ...  % initial position + yaw*tilt induced offset
    (modelData.at*(2*turbine.rotorRadius) + deltaxs * modelData.bt); % bladerotation-induced vertical offset

end

