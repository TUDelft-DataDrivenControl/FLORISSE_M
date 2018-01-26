classdef PorteAgel<handle
    properties
        params
    end
    methods
        %% Parameter settings
        function self = PorteAgel()
            self.params.adjustInitialWakeDiamToYaw = false; % Adjust the intial swept surface overlap

            self.params.alpha = 2.32;     % near wake parameter
            self.params.beta  = .154;     % near wake parameter
            self.params.veer  = 0;        % veer of atmosphere
            self.params.ad    = -4.5;     % lateral wake displacement bias parameter (a + bx)
            self.params.bd    = -.01;     % lateral wake displacement bias parameter (a + bx)

            self.params.TIthresholdMult = 30; % threshold distance of turbines to include in \"added turbulence\"
            self.params.TIa   = .73;      % magnitude of turbulence added
            self.params.TIb   = .8325;    % contribution of turbine operation
            self.params.TIc   = .0325;    % contribution of ambient turbulence intensity
            self.params.TId   = -.32;     % contribution of downstream distance from turbine

            self.params.ka	= .3837;    % wake expansion parameter (ka*TI + kb)
            self.params.kb 	= .0037;    % wake expansion parameter (ka*TI + kb)
            %     inputData.ky    = @(I) inputData.ka*I + inputData.kb;
            %     inputData.kz    = @(I) inputData.ka*I + inputData.kb;

            self.params.ad = -4.5;   % lateral wake displacement bias parameter (a + bx)
            self.params.bd = -0.01;  % lateral wake displacement bias parameter (a + bx)
            self.params.at = 0.0;    % vertical wake displacement bias parameter (a + bx)
            self.params.bt = 0.0;    % vertical wake displacement bias parameter (a + bx)

            % For more information, see the publication from Bastankah and
            % Porte-Agel (2016) with doi:10.1017/jfm.2016.595.
        end
        
        
        
        %% Wake centerline position
        function [wakeDir,displacements] = centerline(deltaxs,turbine,inputData)
        Ct = turbine.Ct;
        Ti = turbine.TI;
        R = floris_eul2rotm(-[turbine.YawWF turbine.Tilt 0],'ZYZ');
        C = R(2:3,2:3)*(R(2:3,2:3).');
        
        % Eq. 7.3, x0 is the start of the far wake
        x0 = 2*turbine.rotorRadius*(cos(turbine.ThrustAngle).*(1+sqrt(1-Ct)))./...
                (sqrt(2)*(self.params.alpha*Ti + self.params.beta*(1-sqrt(1-Ct))));
        % Eq. 6.12
        theta_C0 = ((0.3*turbine.ThrustAngle)./cos(turbine.ThrustAngle)).*...
            (1-sqrt(1-turbine.Ct.*cos(turbine.ThrustAngle)));  % skew angle in near wake

        % sigNeutralx0 is the wake standard deviation in the case of an
        % alligned turbine. This expression uses: Ur./(Uinf+U0) = approx 1/2
        sigNeutral_x0 = eye(2)*turbine.rotorRadius*sqrt(1/2);
       varWake = @(x) mmat(repmat(C,1,1,length(x)),...
            (  repmat(diag([inputData.ky(Ti) inputData.kz(Ti)]),[1,1,length(x)])...
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
            sqrt(sqrt(det(C/((diag([inputData.ky(Ti) inputData.kz(Ti)])*Ct)^2))))*...
            (2.9+1.3*sqrt(1-Ct)-Ct)*lnTerm(x).';
        
%         FW_delta = @(x) delta_x0+theta_C0*(turbine.rotorRadius/7.35)*...
%             sqrt(cos(turbine.ThrustAngle)/(inputData.ky(Ti)*inputData.kz(Ti)*Ct))*...
%             (2.9+1.3*sqrt(1-Ct)-Ct)*lnTerm(x).';
        
        NW_delta = @(x) delta_x0*x/x0;
        displacements = NW_delta(deltaxs).*(deltaxs<=x0)+FW_delta(deltaxs).*(deltaxs>x0);
        % wakeDir = rotx(90)*turbine.wakeNormal; % Original equation
        wakeDir = [1 0 0; 0 0 -1;0 1 0]*turbine.wakeNormal; % Evaluated to remove Toolbox dependencies
        end
        
        
        %% Wake deficit
        function [wakeOut] = deficit(self,inputData,turbine,wakeIn)
            %PORTEAGELWAKE Summary of this function goes here
            %   Detailed explanation goes here
            D = 2*turbine.rotorRadius;
            Ti = turbine.TI;
            % NEAR WAKE CALCULATIONS
            % Eq. 7.3, x0 is the start of the far wake
            x0 = D.*(cos(turbine.ThrustAngle).*(1+sqrt(1-turbine.Ct*cos(turbine.ThrustAngle))))./...
                (sqrt(2)*(self.params.alpha*Ti + self.params.beta*(1-sqrt(1-turbine.Ct))));
            
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
            varWake = @(x) C*((diag([inputData.ky(Ti) inputData.kz(Ti)])*(x-x0))+sigNeutral_x0).^2;
            
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
            
            
            %     keyboard
            %     [X,Y,Z] = meshgrid(0:20:3000,-200:2:200,-200:2:200);
            %     Uinf=X.*0+13;
            %     U=X.*0;
            %     for i = 1:length(X(1,:,1))
            %         U(:,i,:) = wake.V(squeeze(Uinf(:,i,:)),X(1,i,1),squeeze(Y(:,i,:)),squeeze(Z(:,i,:)));
            %     end
            %     volvisApp(X,Y,Z,U)
        end
        
    end
end