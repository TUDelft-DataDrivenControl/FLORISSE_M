function [ wake ] = floris_initwake( inputData,turbine,wake )
% This function computes the coefficients that determine wake behaviour.
% The initial deflection and diameter of the wake are also computed

    % Rodriques rotation formula to rotate 'v', 'th' radians around 'k'
    rod = @(v,th,k) v*cos(th)+cross(k,v)*sin(th)+k*dot(k,v)*(1-cos(th));
    normalize = @(v) v./norm(v);
    
    % Calculate ke, the basic expansion coefficient
    wake.Ke = inputData.Ke + inputData.KeCorrCT*(turbine.Ct-inputData.baselineCT);

    % Calculate mU, the zone multiplier for different wake zones
    if inputData.useaUbU
        wake.mU = inputData.MU/cos(inputData.aU+inputData.bU*turbine.YawWF);
    else
        wake.mU = inputData.MU;
    end

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
    
    % Calculate initial wake diameter
    if inputData.adjustInitialWakeDiamToYaw
        wake.wakeRadiusInit = turbine.rotorRadius*cos(turbine.ThrustAngle);
    else
        wake.wakeRadiusInit = turbine.rotorRadius;
    end
    
    switch inputData.wakeType
        case 'Zones'
            wake.rZones = @(x,z) max(wake.wakeRadiusInit+wake.Ke.*inputData.me(z)*x,0*x);
            wake.cZones = @(x,z) (wake.wakeRadiusInit./(wake.wakeRadiusInit + wake.Ke.*wake.mU(z).*x)).^2;

            % c is the wake intensity reduction factor, b is the boundary
            wake.cFull = @(x,r) ((abs(r)<=wake.rZones(x,3))-(abs(r)<wake.rZones(x,2))).*wake.cZones(x,3)+...
                ((abs(r)<wake.rZones(x,2))-(abs(r)<wake.rZones(x,1))).*wake.cZones(x,2)+...
                (abs(r)<wake.rZones(x,1)).*wake.cZones(x,1);
            
            wake.V = @(U,a,x,r) U*(1-2*a*wake.cFull(x,r));
            wake.boundary = @(x) wake.rZones(x,3);
            
        case 'Gauss'
            r0Jens = turbine.rotorRadius;
            rJens = @(x) wake.Ke*x+r0Jens;
            cJens = @(x) (r0Jens./rJens(x)).^2;

            gv = .65;
            sd = 2;%*(.5/.65);

            sig = @(x) rJens(x).*gv;
            wake.cFull = @(x,r) (pi*rJens(x).^2).*(normpdf(r,0,sig(x))./((normcdf(sd,0,1)-normcdf(-sd,0,1))*sig(x)*sqrt(2*pi))).*cJens(x);
            wake.V = @(U,a,x,r) U*(1-2*a*wake.cFull(x,r));
            wake.boundary = @(x) sd*sig(x);
        case 'Larsen'
            D = 2*turbine.rotorRadius;
            A = pi*turbine.rotorRadius^2;
            H = turbine.hub_height;
            
            IaLars = .06; % ambient turbulence
            RnbLars = D*max(1.08,1.08+21.7*(IaLars-0.05));
            R95Lars = 0.5*(RnbLars+min(H,RnbLars));
            DeffLars = D*sqrt((1+sqrt(1-turbine.Ct))/(2*sqrt(1-turbine.Ct)));

            x0 = 9.5*D/((2*R95Lars/DeffLars)^3-1);
            c1Lars = (DeffLars/2)^(5/2)*(105/(2*pi))^(-1/2)*(turbine.Ct*A*x0).^(-5/6);

            wake.boundary = @(x) (35/(2*pi))^(1/5)*(3*(c1Lars)^2)^(1/5)*((x).*turbine.Ct*A).^(1/3);
            wake.V  = @(U,a,x,r) U-U*((1/9)*(turbine.Ct.*A.*((x0+x).^-2)).^(1/3).*( abs(r).^(3/2).*((3.*c1Lars.^2).*turbine.Ct.*A.*(x0+x)).^(-1/2) - (35/(2.*pi)).^(3/10).*(3.*c1Lars^2).^(-1/5) ).^2);
    end

end