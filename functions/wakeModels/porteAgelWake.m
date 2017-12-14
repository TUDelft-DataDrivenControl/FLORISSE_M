function [ wake ] = porteAgelWake( inputData,turbine,wake )
%PORTEAGELWAKE Summary of this function goes here
%   Detailed explanation goes here
    D = 2*turbine.rotorRadius;
    Ti = turbine.TI;
    % NEAR WAKE CALCULATIONS
    % Eq. 7.3, x0 is the start of the far wake
    x0 = D.*(cos(turbine.ThrustAngle).*(1+sqrt(1-turbine.Ct*cos(turbine.ThrustAngle))))./...
            (sqrt(2)*(inputData.alpha*Ti + inputData.beta*(1-sqrt(1-turbine.Ct))));

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
    NW = @(U,x,y,z) U.*(1-C0*(NW_mask(x,y,z)+NW_exp(x,y,z).*~NW_mask(x,y,z)));

    % Eq 7.2
    varWake = @(x) C*((diag([inputData.ky(Ti) inputData.kz(Ti)])*(x-x0))+sigNeutral_x0).^2;
    % exp(-.5*[y z]*inv(SIGMA(x))*[y;z]) Eq 7.1

    % FAR WAKE CALCULATIONS
    FW_exp = @(x,y,z) exp(-.5*squeeze(mmat(permute(cat(4,y,z),[3 4 1 2]),...
        mmat(inv(varWake(x)),permute(cat(4,y,z),[4 3 1 2])))));
    % Eq 7.1
    FW = @(U,x,y,z) U.*(1-(1-sqrt(1-turbine.Ct.*cos(turbine.ThrustAngle)*...
        sqrt(det((C*(sigNeutral_x0.^2))/varWake(x))))).*FW_exp(x,y,z));
%     FW = @(U,x,y,z) U.*(1-(1-sqrt(1-turbine.Ct.*cos(turbine.ThrustAngle)*...
%         sqrt(trace(C*(sigNeutral_x0.^2))/trace(varWake(x))))).*FW_exp(x,y,z));

    % Eq 7.1 and 6.13 form the wake velocity profile
    wake.V  = @(U,x,y,z) NW(U,x,y,z).*(x<=x0) + FW(U,x,y,z).*(x>x0);
%     wake.boundary = @(Ti,x,y,z) (NW_mask(Ti,x,y,z)+~NW_mask(Ti,x,y,z).*NW_exp(Ti,x,y,z).*(x<=x0(Ti)) + FW_exp(Ti,x,y,z).*(x>x0(Ti)))>normcdf(-2,0,1);
    wake.boundary = @(x,y,z) (NW_mask(x,y,z)+~NW_mask(x,y,z).*NW_exp(x,y,z).*(x<=x0) + FW_exp(x,y,z).*(x>x0))>0.022750131948179; % Evaluated to avoid dependencies on Statistics Toolbox

    % wake.V is an analytical function for flow speed [m/s] in a single wake
    % wake.boundary is a boolean function telling whether a point (y,z) 
    % lies within the wake radius of turbine(i) at distance x        


%     keyboard
%     [X,Y,Z] = meshgrid(0:20:x0(.1),-200:2:200,-200:2:200);
%     [X,Y,Z] = meshgrid(0:20:3000,-200:2:200,-200:2:200);
%     Uinf=X.*0+13;
%     U=X.*0;
%     Ui=X.*0;
%     for i = 1:length(X(1,:,1))
%         U(:,i,:) = wake.V(squeeze(Uinf(:,i,:)),.1 ...
%             ,0,X(1,i,1),squeeze(Y(:,i,:)),squeeze(Z(:,i,:)));
%         Ui(:,i,:) = NW_mask(.1,X(1,i,1),squeeze(Y(:,i,:)),squeeze(Z(:,i,:)));
%     end
%     volvisApp(X,Y,Z,U)
%     volvisApp(X,Y,Z,Ui)

end

