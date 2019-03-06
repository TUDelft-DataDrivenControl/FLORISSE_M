classdef self_similar_gaussian_velocity < velocity_interface
    %SELF_SIMILAR_GAUSSIAN_VELOCITY Wake velocity object implementing a
    %symmetric Gaussian wake as described in :cite:`Bastankhah2016`.
    
    properties
        ct % Turbine thrust coefficient
        thrustAngle % Turbine thrust angle
        TI % Turbulence intensity at turbine
        x0 % Start of the far wake
        C0 % Relative velocity deficit in the near wake core
        ky % Horizontal wake expansion parameter
        kz % Vertical wake expansion parameter
        C % Ellipse covariance matrix
        ellipseA % Wake standard deviation ellipse
        sigNeutral_x0 % Wake standard deviation in the case of a wind-aligned turbine
    end
    
    methods
        function obj = self_similar_gaussian_velocity(modelData, turbine, turbineCondition, turbineControl, turbineResult)
            %SELF_SIMILAR_GAUSSIAN_VELOCITY Construct an instance of this class

            % Store the thrust coefficient
            obj.ct = turbineResult.ct;
            obj.thrustAngle = turbineControl.thrustAngle;
            obj.TI = turbineCondition.TI;
            % wake Epxansion parameters
            obj.ky = modelData.ka*obj.TI + modelData.kb;
            obj.kz = modelData.ka*obj.TI + modelData.kb;
            
            D = 2*turbine.turbineType.rotorRadius;    % Rotor diameter

            % NEAR WAKE CALCULATIONS
            % Eq. 6.16, x0 is the start of the far wake
            obj.x0 = D.*(cos(obj.thrustAngle).*(1+sqrt(1-obj.ct)))./...
                    (sqrt(2)*(modelData.alpha*obj.TI + modelData.beta*(1-sqrt(1-obj.ct))));

            % C0 is the relative velocity deficit in the near wake core
            obj.C0 = 1-sqrt(1-obj.ct.*cos(obj.thrustAngle));

            % Rotation matrix R
            R = floris_eul2rotm(-[turbineControl.yawAngleWF turbineControl.tiltAngle 0],'ZYZ');
            obj.C = R(2:3,2:3)*(R(2:3,2:3).'); % Ellipse covariance matrix
            obj.ellipseA = inv(obj.C*turbine.turbineType.rotorRadius.^2);

            % sigNeutralx0 is the wake standard deviation in the case of a
            % wind-aligned turbine. This expression uses: Ur./(Uinf+U0) = approx 1/2
            obj.sigNeutral_x0 = eye(2)*turbine.turbineType.rotorRadius*sqrt(1/2);

            % % Compute the integrated velocity deficit in a circular region with
            % % radius bladeR with centerpoint position x, y, z
            % wake.FW_int = @(x, y, z, bladeR) bvcdf_wake(x, y, z, bladeR, varWake, FW_scalar);
        end
        
        function Vdeficit = deficit(obj, x, y, z)
            %DEFICIT Compute the velocity deficit at a certain position
            
            % r<=rpc Eq 6.13
            ellipse = obj.ellipseA(1)*y.^2+2*obj.ellipseA(2)*y.*z+obj.ellipseA(4)*z.^2;
            NW_mask = sqrt(ellipse)<=(1-x/obj.x0);

            % r-rpc Eq 6.13
            elipRatio = 1-(1-x/obj.x0)./(eps+sqrt(ellipse));

            % exp(-((r-rpc)/(2s)).^2 Eq 6.13
            NW_exp = exp(-.5*squeeze(mmat(permute(cat(4,y,z),[3 4 1 2]),...
                mmat(inv((((eps+0*(x<=0)) + x* (x>0))/obj.x0).^2*obj.C*(obj.sigNeutral_x0.^2)),...
                permute(cat(4,y,z),[4 3 1 2])))).*(elipRatio.^2));

            % Eq 6.13
            NW = obj.C0*(NW_mask+NW_exp.*~NW_mask);

            % Eq 7.2
            varWake = obj.C*((diag([obj.ky obj.kz])*(x-obj.x0))+obj.sigNeutral_x0).^2;

            % FAR WAKE CALCULATIONS
            % exp(-.5*[y z]*inv(SIGMA(x))*[y;z]) Eq 7.1
            FW_exp = exp(-.5*squeeze(mmat(permute(cat(4,y,z),[3 4 1 2]),...
                mmat(inv(varWake),permute(cat(4,y,z),[4 3 1 2])))));
            % Eq 7.1
            FW_scalar = 1-sqrt(1-obj.ct.*cos(obj.thrustAngle)*...
                sqrt(det((obj.C*(obj.sigNeutral_x0.^2))/varWake)));
            FW = FW_scalar.*FW_exp;

            % Eq 7.1 and 6.13 form the wake velocity profile
            % V is an analytical function for flow speed [m/s] in a single wake
            Vdeficit  = NW.*(x<=obj.x0) + FW.*(x>obj.x0);
        end
        function booleanMap = boundary(obj, x, y, z)
            %BOUNDARY Determine if a coordinate is inside the wake

            % r<=rpc Eq 6.13
            ellipse = obj.ellipseA(1)*y.^2+2*obj.ellipseA(2)*y.*z+obj.ellipseA(4)*z.^2;
            NW_mask = sqrt(ellipse)<=(1-x/obj.x0);

            % r-rpc Eq 6.13
            elipRatio = 1-(1-x/obj.x0)./(eps+sqrt(ellipse));

            % exp(-((r-rpc)/(2s)).^2 Eq 6.13
            innerTermTmp = squeeze(mmat(permute(cat(4,y,z),[3 4 1 2]),...
                    mmat(inv((((eps+0*(x<=0)) + x* (x>0))/obj.x0).^2*...
                    obj.C*(obj.sigNeutral_x0.^2)),permute(cat(4,y,z),[4 3 1 2]))));
                
            if size(elipRatio,1) == 1 % Vector
                elipRatio = repmat(elipRatio,length(elipRatio),1);
                innerTermTmp = repmat(innerTermTmp,1,length(elipRatio));
            end
            NW_exp = exp(-.5*innerTermTmp.*(elipRatio.^2));

            % Eq 7.2
            varWake = obj.C*((diag([obj.ky obj.kz])*(x-obj.x0))+obj.sigNeutral_x0).^2;

            % FAR WAKE CALCULATIONS
            % exp(-.5*[y z]*inv(SIGMA(x))*[y;z]) Eq 7.1
            FW_exp = exp(-.5*squeeze(mmat(permute(cat(4,y,z),[3 4 1 2]),...
                mmat(inv(varWake),permute(cat(4,y,z),[4 3 1 2])))));

            % boundary is a boolean function telling whether a point (y,z)
            % lies within the wake radius of turbine(i) at distance x
            
            if size(NW_mask,1) == 1 % Vector
                NW_mask = repmat(NW_mask,length(NW_mask),1);
                FW_exp  = repmat(FW_exp, 1,length(FW_exp));
            end
            booleanMap = (NW_mask+  ~NW_mask.*NW_exp.*(x<=obj.x0) + FW_exp.*(x>obj.x0))>0.022750131948179; % Evaluated to avoid dependencies on Statistics Toolbox
        end
        
        function [overlap, RVdef] = deficit_integral(obj, deltax, dy, dz, rotRadius)
            if deltax < obj.x0
                % The downwind turbine is positioned in the near-wake, falling back to numerical method
                [overlap, RVdef] = deficit_integral@velocity_interface(obj, deltax, dy, dz, rotRadius);
            else
                varWake = obj.C*((diag([obj.ky obj.kz])*(deltax-obj.x0))+obj.sigNeutral_x0).^2;
                FW_scalar = 1-sqrt(1-obj.ct.*cos(obj.thrustAngle)*...
                    sqrt(det((obj.C*(obj.sigNeutral_x0.^2))/varWake)));
           
                % Corrections to avoid numerical issues
                if dy == 0
                    dy = eps;
                end
                if dz == 0
                    dz = eps;
                end
                
                Q = obj.bvcdf_wake(dy, dz, rotRadius, varWake, FW_scalar);
                
                % Relative volumetric flowrate through swept area
                RVdef = 1-Q/(pi * rotRadius^2);
                % Estimate the size of the area affected by the wake
                [Y,Z] = meshgrid(linspace(-rotRadius,rotRadius,50),linspace(-rotRadius,rotRadius,50));
                overlap = nnz((hypot(Y,Z)<rotRadius)&...
                    (obj.boundary(deltax, Y+dy, Z+dz)))/nnz(hypot(Y,Z)<rotRadius);
            end
        end
        function Qdef = bvcdf_wake(obj, y, z, bladeR, varWake, FW_scalar)
            %bvcdf_wake uses the bvcdf function to compute the velocity deficit at the
            %swept area of a turbine
            
            [v, e] = eig(varWake);  % Linear transformation to make sigma_y and sigma_z uncorrelated
            sigma_y = sqrt(e(1)); % This is the standard deviation in y'-dir
            sigma_z = sqrt(e(4)); % This is the standard deviation in z'-dir

            Sigma_zn = sigma_z/sigma_y; % Non-dimensionalized sigma_z
            bladeRn  = bladeR/sigma_y;  % Non-dimensionalized circle radius
            dC       = norm([y z]*v)/sigma_y; % Non-dim. distance between circle and biv. dist. mean

            Qdef = FW_scalar*(obj.bvcdf(Sigma_zn, bladeRn, dC, 4)*2*pi*sqrt(det(varWake)));
        end
    end
    methods(Static)
        function series0 = bvcdf(Sigma_norm, R_norm, dS_norm, nMax)
            % function [series0] = bvcdf(Sigma_norm, R_norm, dS_norm, nMax)
            %BVCDF computes the bivariate cumulative distribution function over a
            %circular region
            %
            %   The document:
            %   TECHNICAL REPORT ECOM-2625
            %   TABLES OF OFFSET CIRCLE PROBABILITIES FOR A
            %   NORMAL BIVARIATE ELLIPTICAL DISTRIBUTION
            %   explains how to compute the integral of a bivariate normal distribution
            %   by expanding the integral to a power series. The exact solution uses
            %   nMax = infty but the series converges so a few terms are enough to
            %   accurately approximate the integral
            %
            %   Inputs:
            %   Sigma_norm = Sigma of second dimension normalized by sigma in first
            %   R_norm = normalized radius of the circle by Sigma(1)
            %   dS_norm = normalized distance between circle and mean Gaus by Sigma(1)
            
            t = .5*dS_norm^2;
            a = 4*Sigma_norm*Sigma_norm*t;
            b = Sigma_norm*Sigma_norm-1;
            s = .5*R_norm*R_norm/(Sigma_norm*Sigma_norm);

            series0 = 0;
            for n=0:nMax
                series1 = 0;
                series2 = 0;
                for kj = 0:n
                    series1=series1+(s^kj)/factorial(kj);
                    series2=series2+((-1)^kj)*((b/a)^kj)/(factorial(kj)*factorial(2*(n-kj)));
                end
                series0=series0+(factorial(2*n)/(2^(2*n)*factorial(n)))*...
                (1-exp(-s)*series1)*(a^n)*series2;
            end
            series0 = Sigma_norm*exp(-t)*series0;
        end
    end
end
