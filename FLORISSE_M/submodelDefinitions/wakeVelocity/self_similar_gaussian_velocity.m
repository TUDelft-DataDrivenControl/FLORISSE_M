classdef self_similar_gaussian_velocity < velocity_interface
    %SELF_SIMILAR_GAUSSIAN_VELOCITY Summary of this class goes here
    %   Detailed explanation goes here
    
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
            % Eq. 7.3, x0 is the start of the far wake
            obj.x0 = D.*(cos(obj.thrustAngle).*(1+sqrt(1-obj.ct*cos(obj.thrustAngle))))./...
                    (sqrt(2)*(modelData.alpha*obj.TI + modelData.beta*(1-sqrt(1-obj.ct))));

            % C0 is the relative velocity deficit in the near wake core
            obj.C0 = 1-sqrt(1-obj.ct.*cos(obj.thrustAngle));

            % Rotation matrix R
            R = floris_eul2rotm(-[turbineControl.yawAngle turbineControl.tiltAngle 0],'ZYZ');
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
            NW_exp = exp(-.5*squeeze(mmat(permute(cat(4,y,z),[3 4 1 2]),...
                mmat(inv((((eps+0*(x<=0)) + x* (x>0))/obj.x0).^2*obj.C*(obj.sigNeutral_x0.^2)),...
                permute(cat(4,y,z),[4 3 1 2])))).*(elipRatio.^2));

            % Eq 7.2
            varWake = obj.C*((diag([obj.ky obj.kz])*(x-obj.x0))+obj.sigNeutral_x0).^2;

            % FAR WAKE CALCULATIONS
            % exp(-.5*[y z]*inv(SIGMA(x))*[y;z]) Eq 7.1
            FW_exp = exp(-.5*squeeze(mmat(permute(cat(4,y,z),[3 4 1 2]),...
                mmat(inv(varWake),permute(cat(4,y,z),[4 3 1 2])))));

            % boundary is a boolean function telling whether a point (y,z)
            % lies within the wake radius of turbine(i) at distance x
            booleanMap = (NW_mask+~NW_mask.*NW_exp.*(x<=obj.x0) + FW_exp.*(x>obj.x0))>0.022750131948179; % Evaluated to avoid dependencies on Statistics Toolbox
        end
    end
end
