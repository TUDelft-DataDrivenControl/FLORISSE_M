function [ wake ] = floris_initwake( inputData,turbine,wake )
% This function computes the coefficients that determine wake behaviour.
% The initial deflection and diameter of the wake are also computed.
    
    % Calculate initial wake diameter
    if inputData.adjustInitialWakeDiamToYaw
        wake.wakeRadiusInit = turbine.rotorRadius*cos(turbine.ThrustAngle);
    else
        wake.wakeRadiusInit = turbine.rotorRadius;
    end
    
    D = 2*turbine.rotorRadius; % Rotor diameter
    
    
    %% Determine the velocity deficit and location for a single wake
    % This can be according to a number of choices, namely the standard
    % FLORIS model with 3 discrete wake zones. Also a Gaussian wake shape
    % can be assumed, among others.
    switch inputData.wakeType
    case 'Zones' % FLORIS wake zones model with 3 discrete deficit profiles
        % Calculate ke, the basic expansion coefficient
        wake.Ke = inputData.Ke + inputData.KeCorrCT*(turbine.Ct-inputData.baselineCT);

        % Calculate mU, the zone multiplier for different wake zones
        if inputData.useaUbU
            wake.mU = inputData.MU/cos(inputData.aU+inputData.bU*turbine.YawWF);
        else
            wake.mU = inputData.MU;
        end

        % Radius of wake zones [m]
        wake.rZones = @(x,zone) max(wake.wakeRadiusInit+wake.Ke.*inputData.me(zone)*x,0*x);
        
        % Center location of wake zones [m]
        wake.cZones = @(x,zone) (wake.wakeRadiusInit./(wake.wakeRadiusInit + wake.Ke.*wake.mU(zone).*x)).^2;

        % cFull is the wake intensity reduction factor
        cFull = @(x,r) ((abs(r)<=wake.rZones(x,3))-(abs(r)<wake.rZones(x,2))).*wake.cZones(x,3)+...
            ((abs(r)<wake.rZones(x,2))-(abs(r)<wake.rZones(x,1))).*wake.cZones(x,2)+...
            (abs(r)<wake.rZones(x,1)).*wake.cZones(x,1);

        % wake.V is an analytical function for flow speed [m/s] in a single wake
        wake.V = @(U,Ti,a,x,y,z) U.*(1-2*a*cFull(x,hypot(y,z)));
        
        % wake.boundary is a boolean function telling whether a point (y,z) 
        % lies within the wake radius of turbine(i) at distance x
        wake.boundary = @(Ti,x,y,z) hypot(y,z)<(wake.rZones(x,3));

    case 'Gauss' % Gaussian wake profile shape
        % Calculate ke, the basic expansion coefficient
        wake.Ke = inputData.Ke + inputData.KeCorrCT*(turbine.Ct-inputData.baselineCT);

        r0Jens = turbine.rotorRadius;       % Initial wake radius [m]
        rJens = @(x) wake.Ke*x+r0Jens;      % Wake radius as a function of x [m]
        cJens = @(x) (r0Jens./rJens(x)).^2; % Wake intensity reduction factor according to Jensen

        gv = .65; % Gaussian variable
        sd = 2;   % Number of std. devs to which the gaussian wake extends
        varWake = @(x) rJens(x).*gv;
        
        % cFull is the wake intensity reduction factor
        cFull = @(x,r) (pi*rJens(x).^2).*(normpdf(r,0,varWake(x))./((normcdf(sd,0,1)-normcdf(-sd,0,1))*varWake(x)*sqrt(2*pi))).*cJens(x);
        
        % wake.V is an analytical function for flow speed [m/s] in a single wake
        wake.V = @(U,Ti,a,x,y,z) U.*(1-2*a*cFull(x,hypot(y,z)));
        
        % wake.boundary is a boolean function telling whether a point (y,z) 
        % lies within the wake radius of turbine(i) at distance x        
        wake.boundary = @(Ti,x,y,z) hypot(y,z)<( sd*varWake(x));
        
    case 'Larsen' % Larsen (2006) wake profile
        A = pi*turbine.rotorRadius^2; % Rotor swept area [m]
        H = turbine.hub_height;       % Turbine hub height [m]

        RnbLars = D*max(1.08,1.08+21.7*(inputData.IaLars-0.05));
        R95Lars = 0.5*(RnbLars+min(H,RnbLars));
        DeffLars = D*sqrt((1+sqrt(1-turbine.Ct))/(2*sqrt(1-turbine.Ct)));

        x0 = 9.5*D/((2*R95Lars/DeffLars)^3-1);
        c1Lars = (DeffLars/2)^(5/2)*(105/(2*pi))^(-1/2)*(turbine.Ct*A*x0).^(-5/6);

        wake.boundary = @(Ti,x,y,z) hypot(y,z)<((35/(2*pi))^(1/5)*(3*(c1Lars)^2)^(1/5)*((x).*turbine.Ct*A).^(1/3));
        wake.V  = @(U,Ti,a,x,y,z) U-U.*((1/9)*(turbine.Ct.*A.*((x0+x).^-2)).^(1/3).*( hypot(y,z).^(3/2).*((3.*c1Lars.^2).*turbine.Ct.*A.*(x0+x)).^(-1/2) - (35/(2.*pi)).^(3/10).*(3.*c1Lars^2).^(-1/5) ).^2);
        
    case 'PorteAgel' % Wake shape from Porte-Agel
        
        % NEAR WAKE CALCULATIONS
        % Eq. 7.3, x0 is the start of the far wake
        x0 = @(Ti) D.*(cos(turbine.ThrustAngle).*(1+sqrt(1-turbine.Ct*cos(turbine.ThrustAngle))))./...
                (sqrt(2)*(inputData.alpha*Ti + inputData.beta*(1-sqrt(1-turbine.Ct))));
            
        % C0 is the relative velocity deficit in the near wake core
        C0 = 1-sqrt(1-turbine.Ct.*cos(turbine.ThrustAngle));
        
        % Rotation matrix R
        R = eul2rotm(-[turbine.YawWF turbine.Tilt 0],'ZYZ');
        C = R(2:3,2:3)*(R(2:3,2:3).'); % Ellipse covariance matrix
        ellipseA = inv(C*turbine.rotorRadius.^2);
        ellipse = @(y,z) ellipseA(1)*y.^2+2*ellipseA(2)*y.*z+ellipseA(4)*z.^2;
        
        % sigNeutralx0 is the wake standard deviation in the case of a
        % wind-aligned turbine. This expression uses: Ur./(Uinf+U0) = approx 1/2
        sigNeutral_x0 = eye(2)*turbine.rotorRadius*sqrt(1/2);
        
        % r<=rpc Eq 6.13
        NW_mask = @(Ti,x,y,z) (sqrt(ellipse(y,z))<=(1-x/x0(Ti)));
        
        % r-rpc Eq 6.13
        elipRatio = @(Ti,x,y,z) 1-(1-x/x0(Ti))./(eps+sqrt(ellipse(y,z)));
        
        % exp(-((r-rpc)/(2s)).^2 Eq 6.13
        NW_exp = @(Ti,x,y,z) exp(-.5*squeeze(mmat(permute(cat(4,y,z),[3 4 1 2]),...
            mmat(inv((((eps+0*(x<=0)) + x* (x>0))/x0(Ti)).^2*C*(sigNeutral_x0.^2)),permute(cat(4,y,z),[4 3 1 2])))).*(elipRatio(Ti,x,y,z).^2));
        
        % Eq 6.13
        NW = @(U,Ti,x,y,z) U.*(1-C0*(NW_mask(Ti,x,y,z)+NW_exp(Ti,x,y,z).*~NW_mask(Ti,x,y,z)));
        
        % Eq 7.2
        varWake = @(Ti,x) C*((diag([inputData.ky(Ti) inputData.kz(Ti)])*(x-x0(Ti)))+sigNeutral_x0).^2;
        % exp(-.5*[y z]*inv(SIGMA(x))*[y;z]) Eq 7.1
        
        % FAR WAKE CALCULATIONS
        FW_exp = @(Ti,x,y,z) exp(-.5*squeeze(mmat(permute(cat(4,y,z),[3 4 1 2]),...
            mmat(inv(varWake(Ti,x)),permute(cat(4,y,z),[4 3 1 2])))));
        % Eq 7.1
        FW = @(U,Ti,x,y,z) U.*(1-(1-sqrt(1-turbine.Ct.*cos(turbine.ThrustAngle)*...
            sqrt(det((C*(sigNeutral_x0.^2))/varWake(Ti,x))))).*FW_exp(Ti,x,y,z));
%         FW = @(U,x,y,z) U.*(1-(1-sqrt(1-turbine.Ct.*cos(turbine.ThrustAngle)*...
%             sqrt(trace(C*(sigNeutral_x0.^2))/trace(varWake(x))))).*FW_exp(x,y,z));
        
        % Eq 7.1 and 6.13 form the wake velocity profile
        wake.V  = @(U,Ti,a,x,y,z) NW(U,Ti,x,y,z).*(x<=x0(Ti)) + FW(U,Ti,x,y,z).*(x>x0(Ti));
        wake.boundary = @(Ti,x,y,z) (NW_mask(Ti,x,y,z)+~NW_mask(Ti,x,y,z).*NW_exp(Ti,x,y,z).*(x<=x0(Ti)) + FW_exp(Ti,x,y,z).*(x>x0(Ti)))>normcdf(-2,0,1);
        
        % wake.V is an analytical function for flow speed [m/s] in a single wake
        % wake.boundary is a boolean function telling whether a point (y,z) 
        % lies within the wake radius of turbine(i) at distance x        
        
        
%         keyboard
%         [X,Y,Z] = meshgrid(-20:20:3000,-200:2:200,-200:2:200);
%         Uinf=X.*0+13;
%         U=X.*0;
%         for i = 1:length(X(1,:,1))
%             U(:,i,:) = wake.V(squeeze(Uinf(:,i,:)),inputData.TI_0 ...
%                 ,0,X(1,i,1),squeeze(Y(:,i,:)),squeeze(Z(:,i,:)));
%         end
%         volvisApp(X,Y,Z,U)

    otherwise
        error(['Wake type with name: "' inputData.wakeType '" not defined']);
    end

end