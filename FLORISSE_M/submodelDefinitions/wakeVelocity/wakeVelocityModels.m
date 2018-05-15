function [wake] = wakeVelocityModels(modelData,turbine,wake)

%% Wake deficit model choice
% Herein we define how we want to model the shape of our wake (looking at
% the y-z slice). The traditional FLORIS model uses three discrete zones,
% 'Zones', but more recently a Gaussian wake profile 'Gauss' has seemed to 
% better capture the wake shape with less tuning parameters. This idea has
% further been explored by Bastankah and Porte-Agel (2016), which led to
% the 'PorteAgel' wake deficit model.
switch modelData.deficitModel
    
    %% Porte-Agel (2016) wake deficit model
    case 'PorteAgel'
            % Wake deficit for the Porte-Agel model
            
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
            
    case 'Zones'
        a = turbine.axialInd;
        
        % Calculate ke, the basic expansion coefficient
        wake.Ke = modelData.Ke + modelData.KeCorrCT*(turbine.Ct-modelData.baselineCT);
        
        % Calculate mU, the zone multiplier for different wake zones
        if modelData.useaUbU
            wake.mU = modelData.MU/cos(modelData.aU+modelData.bU*turbine.YawWF);
        else
            wake.mU = modelData.MU;
        end
        
        % Radius of wake zones [m]
        wake.rZones = @(x,zone) max(wake.wakeRadiusInit+wake.Ke.*modelData.me(zone)*x,0*x);
        
        % Center location of wake zones [m]
        wake.cZones = @(x,zone) (wake.wakeRadiusInit./(wake.wakeRadiusInit + wake.Ke.*wake.mU(zone).*x)).^2;
        
        % cFull is the wake intensity reduction factor
        cFull = @(x,r) ((abs(r)<=wake.rZones(x,3))-(abs(r)<wake.rZones(x,2))).*wake.cZones(x,3)+...
            ((abs(r)<wake.rZones(x,2))-(abs(r)<wake.rZones(x,1))).*wake.cZones(x,2)+...
            (abs(r)<wake.rZones(x,1)).*wake.cZones(x,1);
        
        % wake.V is an analytical function for flow speed [m/s] in a single wake
        wake.V = @(U,x,y,z) U.*(1-2*a*cFull(x,hypot(y,z)));
        
        % wake.boundary is a boolean function telling whether a point (y,z)
        % lies within the wake radius of turbine(i) at distance x
        wake.boundary = @(x,y,z) hypot(y,z)<(wake.rZones(x,3));

        
    case 'Larsen'
        D = 2*turbine.rotorRadius;    % Rotor diameter
        A = pi*turbine.rotorRadius^2; % Rotor swept area [m]
        H = turbine.hub_height;       % Turbine hub height [m]

        RnbLars = D*max(1.08,1.08+21.7*(turbine.TI-0.05));
        R95Lars = 0.5*(RnbLars+min(H,RnbLars));
        DeffLars = D*sqrt((1+sqrt(1-turbine.Ct))/(2*sqrt(1-turbine.Ct)));

        x0 = 9.5*D/((2*R95Lars/DeffLars)^3-1);
        c1Lars = (DeffLars/2)^(5/2)*(105/(2*pi))^(-1/2)*(turbine.Ct*A*x0).^(-5/6);

        wake.boundary = @(x,y,z) hypot(y,z)<((35/(2*pi))^(1/5)*(3*(c1Lars)^2)^(1/5)*((x).*turbine.Ct*A).^(1/3));
        wake.V  = @(U,x,y,z) U-U.*((1/9)*(turbine.Ct.*A.*((x0+x).^-2)).^(1/3).*( hypot(y,z).^(3/2).*((3.*c1Lars.^2).*turbine.Ct.*A.*(x0+x)).^(-1/2) - (35/(2.*pi)).^(3/10).*(3.*c1Lars^2).^(-1/5) ).^2);


    case 'JensenGaussian'
        a = turbine.axialInd;
        
        % Calculate ke, the basic expansion coefficient
        wake.Ke = modelData.Ke + modelData.KeCorrCT*(turbine.Ct-modelData.baselineCT);
        
        r0Jens = turbine.rotorRadius;       % Initial wake radius [m]
        rJens = @(x) wake.Ke*x+r0Jens;      % Wake radius as a function of x [m]
        cJens = @(x) (r0Jens./rJens(x)).^2; % Wake intensity reduction factor according to Jensen
        
        gv = .65; % Gaussian variable
        sd = 2;   % Number of std. devs to which the gaussian wake extends
        P_normcdf_lb = 0.022750131948179; % This is the evaluation of normcdf(-sd,0,1) for sd = 2
        P_normcdf_ub = 0.977249868051821; % This is the evaluation of normcdf(+sd,0,1) for sd = 2
        varWake = @(x) rJens(x).*gv;
        
        
        % cFull is the wake intensity reduction factor
        % cFull = @(x,r) (pi*rJens(x).^2).*(normpdf(r,0,varWake(x))./((normcdf(sd,0,1)-normcdf(-sd,0,1))*varWake(x)*sqrt(2*pi))).*cJens(x);
        % The above function is the true equation. The lower one is evaluated for std = 2,  to avoid dependencies on the Statistics Toolbox.
        floris_normpdf = @(x,mu,sigma) (1/(sigma*sqrt(2*pi)))*exp(-(x-mu).^2/(2*sigma.^2)); % to avoid dependencies on the Statistics Toolbox
        cFull = @(x,r) (pi*rJens(x).^2).*(floris_normpdf(r,0,varWake(x))./((P_normcdf_ub-P_normcdf_lb)*varWake(x)*sqrt(2*pi))).*cJens(x);
        
        % wake.V is an analytical function for flow speed [m/s] in a single wake
        wake.V = @(U,x,y,z) U.*(1-2*a*cFull(x,hypot(y,z)));
        
        % wake.boundary is a boolean function telling whether a point (y,z)
        % lies within the wake radius of turbine(i) at distance x
        wake.boundary = @(x,y,z) hypot(y,z)<( sd*varWake(x));
        
        
    otherwise
        
        error(['Deficit model with name ''' modelData.deficitModel ''' not specified. (Note: input is case-sensitive)']);
end
end

