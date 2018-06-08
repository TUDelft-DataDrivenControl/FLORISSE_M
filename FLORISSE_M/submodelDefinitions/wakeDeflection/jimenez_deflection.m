classdef jimenez_deflection < deflection_interface
    %JIMINEZ_DEFLECTION A wake centerline deflection model.
    %   This wake centerline deflection model is described in 
    %   :cite:`Jimenez2009`. It uses the rotor misalignment to compute an
    %   intital wake deflection angle. This angle decreases downwin
    %   similarly to the decrease of the wake deficit. Integrating the
    %   tangent of the wake centerline angle yields the deflection.
    
    properties
        zetaInit % Initial wake centerline angle
        wakeDir % Direction into which the wake deflects
        rotorRadius % Length of a turbine blade
        KdY % Deflection decreasing parameter
        ad % lateral wake displacement bias parameter (a*Drotor + bx)
        bd % lateral wake displacement bias parameter (a*Drotor + bx)
        at % vertical wake displacement bias parameter (a*Drotor + bx)
        bt % vertical wake displacement bias parameter (a*Drotor + bx)
    end
    
    methods
        function obj = jimenez_deflection(modelData, turbine, turbineCondition, turbineControl, turbineResult)
            %JIMINEZ_DEFLECTION Instantiate a wake deflection object
            %   store all the relevant variables in the object so that they
            %   can be used in the wake deflection function

            % Initial wake centerline angle
            obj.zetaInit = 0.5*sin(turbineControl.thrustAngle)*turbineResult.ct; % Eq. 8
            
            % Add an initial wakeangle to the zeta
            if modelData.useWakeAngle
                % Rodriques rotation formula to rotate vector 'v', 'th' radians
                % around vector 'k'
                rod = @(v,th,k) v*cos(th)+cross(k,v)*sin(th)+k*dot(k,v)*(1-cos(th));
                % Compute initial direction of wake unadjusted
                initDir = rod([1;0;0],obj.zetaInit,turbineControl.wakeNormal);
                % Initial wake direction adjusted for initial wake angle kd
                floris_rotz = @(x) [cosd(x) -sind(x) 0; sind(x) cosd(x) 0; 0 0 1];
                wakeVector = floris_rotz(rad2deg(modelData.kd))*initDir;
                obj.zetaInit = acos(dot(wakeVector,[1;0;0]));
                % Set the wakeNormal
                if wakeVector(1)==1
                    wakeNormal = [0 0 1].';
                else
                    normalize = @(v) v./norm(v);
                    wakeNormal = normalize(cross([1;0;0],wakeVector));
                end
            else
                wakeNormal = turbineControl.wakeNormal;
            end
            % Direction into which the wake deflects
            obj.wakeDir = [1 0 0;0 0 1;0 -1 0]*wakeNormal;
            obj.rotorRadius = turbine.turbineType.rotorRadius;
            % Deflection decreasing parameter
            obj.KdY = modelData.KdY;

            % Turbine rotation induced linear wake deflection parameters
            obj.ad = modelData.ad;
            obj.bd = modelData.bd;
            obj.at = modelData.at;
            obj.bt = modelData.bt;
        end
        
        function [dy, dz] = deflection(obj, x)
            %DEFLECTION Computes deflection dz and dx based on downwind
            %distance x.

            % Calculate wake displacements as described in Jimenez
            factors       = (obj.KdY*x/obj.rotorRadius)+1;
            displacements = (obj.zetaInit*(15*(factors.^4)+(obj.zetaInit^2))./ ...
                ((15*obj.KdY*(factors.^5))/obj.rotorRadius))- ...
                (obj.zetaInit*obj.rotorRadius*...
                (15+(obj.zetaInit^2))/(15*obj.KdY));

            % Determine wake centerline position of this turbine at location x
            dy = obj.wakeDir(2)*displacements + ...  % initial position + yaw induced offset
                (obj.ad*(2*obj.rotorRadius) + x * obj.bd); % bladerotation-induced lateral offset

            dz = obj.wakeDir(3)*displacements + ...  % initial position + yaw*tilt induced offset
                (obj.at*(2*obj.rotorRadius) + x * obj.bt); % bladerotation-induced vertical offset
        end
    end
end

