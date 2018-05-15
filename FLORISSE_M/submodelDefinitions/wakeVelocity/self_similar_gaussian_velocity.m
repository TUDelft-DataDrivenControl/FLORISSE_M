function [outputArg1,outputArg2] = self_similar_gaussian_velocity(inputArg1,inputArg2)
%SELF_SIMILAR_GAUSSIAN_VELOCITY Summary of this function goes here
%   Detailed explanation goes here


D = 2*turbine.rotorRadius;
Ti = turbine.TI;
% NEAR WAKE CALCULATIONS
% Eq. 7.3, x0 is the start of the far wake
x0 = D.*(cos(turbine.ThrustAngle).*(1+sqrt(1-turbine.Ct*cos(turbine.ThrustAngle))))./...
    (sqrt(2)*(modelData.alpha*Ti + modelData.beta*(1-sqrt(1-turbine.Ct))));

% C0 is the relative velocity deficit in the near wake core
C0 = 1-sqrt(1-turbine.Ct.*cos(turbine.ThrustAngle));

% Rotation matrix R
R = floris_eul2rotm(-[turbine.YawWF turbine.Tilt 0],'ZYZ');
C = R(2:3,2:3)*(R(2:3,2:3).'); % Ellipse covariance matrix
ellipseA = inv(C*turbine.rotorRadius.^2);
ellipse = @(y,z) ellipseA(1)*y.^2+2*ellipseA(2)*y.*z+ellipseA(4)*z.^2;

% sigNeutralx0 is the wake standard deviation in the case of a
% wind-aligned turbine. This expression uses: Ur./(Uinf+U0) = approx 1/2
sigNeutral_x0 = eye(2)*turbine.rotorRadius*sqrt(1/2);

% r<=rpc Eq 6.13
NW_mask = @(x,y,z) sqrt(ellipse(y,z))<=(1-x/x0);

% r-rpc Eq 6.13
elipRatio = @(x,y,z) 1-(1-x/x0)./(eps+sqrt(ellipse(y,z)));

% exp(-((r-rpc)/(2s)).^2 Eq 6.13
NW_exp = @(x,y,z) exp(-.5*squeeze(mmat(permute(cat(4,y,z),[3 4 1 2]),...
    mmat(inv((((eps+0*(x<=0)) + x* (x>0))/x0).^2*C*(sigNeutral_x0.^2)),...
    permute(cat(4,y,z),[4 3 1 2])))).*(elipRatio(x,y,z).^2));

% Eq 6.13
NW = @(x,y,z) 1-C0*(NW_mask(x,y,z)+NW_exp(x,y,z).*~NW_mask(x,y,z));

% Eq 7.2
ky = @(I) modelData.ka*I + modelData.kb;
kz = @(I) modelData.ka*I + modelData.kb;
varWake = @(x) C*((diag([ky(Ti) kz(Ti)])*(x-x0))+sigNeutral_x0).^2;

% FAR WAKE CALCULATIONS
% exp(-.5*[y z]*inv(SIGMA(x))*[y;z]) Eq 7.1
FW_exp = @(x,y,z) exp(-.5*squeeze(mmat(permute(cat(4,y,z),[3 4 1 2]),...
    mmat(inv(varWake(x)),permute(cat(4,y,z),[4 3 1 2])))));
% Eq 7.1
FW_scalar = @(x) 1-sqrt(1-turbine.Ct.*cos(turbine.ThrustAngle)*...
    sqrt(det((C*(sigNeutral_x0.^2))/varWake(x))));
FW = @(x,y,z) 1-FW_scalar(x).*FW_exp(x,y,z);

% Compute the integrated velocity deficit in a circular region with
% radius bladeR with centerpoint position x, y, z
wake.FW_int = @(x, y, z, bladeR) bvcdf_wake(x, y, z, bladeR, varWake, FW_scalar);

% Eq 7.1 and 6.13 form the wake velocity profile
wake.V  = @(U,x,y,z) U.*(NW(x,y,z).*(x<=x0) + FW(x,y,z).*(x>x0));
%     wake.boundary = @(x,y,z) (NW_mask(x,y,z)+~NW_mask(x,y,z).*NW_exp(x,y,z).*(x<=x0) + FW_exp(x,y,z).*(x>x0))>normcdf(-2,0,1);
wake.boundary = @(x,y,z) (NW_mask(x,y,z)+~NW_mask(x,y,z).*NW_exp(x,y,z).*(x<=x0) + FW_exp(x,y,z).*(x>x0))>0.022750131948179; % Evaluated to avoid dependencies on Statistics Toolbox
%     wake.radius = @(x,y,z) NW_exp(x,y,z).*(x<=x0) + FW_exp(x,y,z).*(x>x0);
% wake.V is an analytical function for flow speed [m/s] in a single wake
% wake.boundary is a boolean function telling whether a point (y,z)
% lies within the wake radius of turbine(i) at distance x    

end

