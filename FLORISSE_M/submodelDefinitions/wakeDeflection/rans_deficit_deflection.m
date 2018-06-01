classdef rans_deficit_deflection < deflection_interface
    % RANS_DEFICIT_DEFLECTION A wake centerline deflection model.
    %   This wake centerline deflection model is described in [Bastankhah
    %   and Porte-Agel, 2016]. The model assumes a strict distinction
    %   between the near wake and far wake. The near wake is modeled as a
    %   constant velocity core that transforms from a tophat into a
    %   gaussian. When the gaussian is fully formed the far wake starts.
    %   The wake centerline deflection follows this distinction. The wake
    %   centerline in the near wake has a constant angle. The far wake
    %   deflection is computed based on Ct and the wake expansion.
    
    properties
        C % Ellipse covariance matrix
        ky % Horizontal wake expansion parameter
        kz % Vertical wake expansion parameter
        x0 % Start of the far wake
        sigNeutral_x0 % Wake standard deviation in the case of a wind-aligned turbine
        ct % Thrust coefficient
        delta_x0 % Displacement at the end of the near wake
        theta_C0 % Skew angle in near wake
        wakeDir % Direction into which the wake deflects
        rotorRadius % Length of a turbine blade
        ad % lateral wake displacement bias parameter (a*Drotor + bx)
        bd % lateral wake displacement bias parameter (a*Drotor + bx)
        at % vertical wake displacement bias parameter (a*Drotor + bx)
        bt % vertical wake displacement bias parameter (a*Drotor + bx)
    end
    
    methods
        function obj = rans_deficit_deflection(modelData, turbine, turbineCondition, turbineControl, turbineResult)
            %RANS_DEFICIT_DEFLECTION Instantiate a wake deflection object
            %   Compute and store all the variables that are required by
            %   the DEFLECTION function.
            
            % Rotation matrix R
            R = floris_eul2rotm(-[turbineControl.yawAngle turbineControl.tiltAngle 0],'ZYZ');
            % Ellipse covariance matrix
            obj.C = R(2:3,2:3)*(R(2:3,2:3).');
            
            % Wake expansion parameters
            obj.ky = modelData.ka*turbineCondition.TI + modelData.kb;
            obj.kz = modelData.ka*turbineCondition.TI + modelData.kb;
            
          	obj.rotorRadius = turbine.turbineType.rotorRadius;
            D = 2*obj.rotorRadius;
            obj.ct = turbineResult.ct;
            % Eq. 7.3, x0 is the start of the far wake
            obj.x0 = D.*(cos(turbineControl.thrustAngle).*(1+sqrt(1-obj.ct*cos(turbineControl.thrustAngle))))./...
                    (sqrt(2)*(modelData.alpha*turbineCondition.TI + modelData.beta*(1-sqrt(1-obj.ct))));
                
            % sigNeutralx0 is the wake standard deviation in the case of a
            % wind-aligned turbine. This expression uses: Ur./(Uinf+U0) = approx 1/2
            obj.sigNeutral_x0 = eye(2)*obj.rotorRadius*sqrt(1/2);
            
            % skew angle in near wake
            obj.theta_C0 = ((0.3*turbineControl.thrustAngle)./cos(turbineControl.thrustAngle)).*...
                (1-sqrt(1-obj.ct.*cos(turbineControl.thrustAngle)));
            
            % displacement at the end of the near wake
            obj.delta_x0 = tan(obj.theta_C0)*obj.x0;
            
            obj.wakeDir = [1 0 0;0 0 -1;0 1 0]*turbineControl.wakeNormal;

            % Turbine rotation induced linear wake deflection parameters
            obj.ad = modelData.ad;
            obj.bd = modelData.bd;
            obj.at = modelData.at;
            obj.bt = modelData.bt;
        end
        
        function [dy, dz] = deflection(obj, x)
            %DEFLECTION Computes deflection dz and dx based on downwind distance x.
            %   This function is vectorized in the x-direction. That makes
            %   the notation slightly obtuse but the relvant equations can
            %   be found in [Bastankhah and Porte-Agel, 2016]

            varWake = mmat(repmat(obj.C,1,1,length(x)),...
                (  repmat(diag([obj.ky obj.kz]),[1,1,length(x)])...
                .* repmat(reshape((x-obj.x0),1,1,length(x)),2,2,1)...
                +  repmat(obj.sigNeutral_x0,1,1,length(x))).^2); 
            % varWake updated matrix definitions for backwards compatibility. Previously:
            %         varWake = mmat(zeros(2,2,length(x))+C,(repmat(diag([obj.ky obj.kz]) ...
            %         ,[1,1,length(x)]).*reshape((x-x0),1,1,length(x))+sigNeutral_x0).^2);
            vecdet = @(ar) ar(1,1,:).*ar(2,2,:)-ar(1,2,:).*ar(2,1,:);

            % Terms that are used in eq 7.4
            lnInnerTerm = sqrt(sqrt(squeeze(vecdet(mmat(varWake,inv(obj.C*obj.sigNeutral_x0.^2))))));
            lnTerm = log(((1.6+sqrt(obj.ct))*(1.6*lnInnerTerm-sqrt(obj.ct)))./...
                ((1.6-sqrt(obj.ct))*(1.6*lnInnerTerm+sqrt(obj.ct))));

            % Eq. 7.4
            FW_delta = obj.delta_x0+obj.theta_C0*(obj.rotorRadius/7.35)*...
                sqrt(sqrt(det(obj.C/((diag([obj.ky obj.kz])*obj.ct)^2))))*...
                (2.9+1.3*sqrt(1-obj.ct)-obj.ct)*lnTerm.';

            %         FW_delta = @(x) delta_x0+theta_C0*(turbine.rotorRadius/7.35)*...
            %             sqrt(cos(turbine.ThrustAngle)/(inputData.ky(Ti)*inputData.kz(Ti)*Ct))*...
            %             (2.9+1.3*sqrt(1-Ct)-Ct)*lnTerm(x).';

            NW_delta = x*obj.delta_x0/obj.x0;
            displacements = NW_delta.*(x<=obj.x0)+FW_delta.*(x>obj.x0);

            % Determine wake centerline position of this turbine at location x
            dy = obj.wakeDir(2)*displacements + ...  % initial position + yaw induced offset
                (obj.ad*(2*obj.rotorRadius) + x * obj.bd); % bladerotation-induced lateral offset

            dz = obj.wakeDir(3)*displacements + ...  % initial position + yaw*tilt induced offset
                (obj.at*(2*obj.rotorRadius) + x * obj.bt); % bladerotation-induced vertical offset
            
        end
    end
end



