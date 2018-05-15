classdef jimenez_deflection < deflection_interface
    %JIMINEZ_DEFLECTION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        zetaInit
        wakeDir
        rotorRadius
        KdY
        ad
        bd
        at
        bt
    end
    
    methods
        function obj = jimenez_deflection(modelData, turbine, turbineCondition, turbineControl, turbineResult)
            %JIMINEZ_DEFLECTION Construct an instance of this class
            %   Detailed explanation goes here

            % Jimenez (2014) wake deflection model
            obj.zetaInit = 0.5*sin(turbineControl.thrustAngle)*turbineResult.ct; % Eq. 8
            obj.wakeDir = [1 0 0;0 0 1;0 -1 0]*turbineControl.wakeNormal;
            obj.rotorRadius = turbine.turbineType.rotorRadius;
            obj.KdY = modelData.KdY;

            obj.ad = modelData.ad;
            obj.bd = modelData.bd;
            obj.at = modelData.at;
            obj.bt = modelData.bt;
        end
        
        function [dy, dz] = deflection(obj, dx)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here

            % Calculate wake displacements as described in Jimenez
            factors       = (obj.KdY*dx/obj.rotorRadius)+1;
            displacements = (obj.zetaInit*(15*(factors.^4)+(obj.zetaInit^2))./ ...
                ((15*obj.KdY*(factors.^5))/obj.rotorRadius))- ...
                (obj.zetaInit*obj.rotorRadius*...
                (15+(obj.zetaInit^2))/(15*obj.KdY));

            % Determine wake centerline position of this turbine at location x
            dy = obj.wakeDir(2)*displacements + ...  % initial position + yaw induced offset
                (obj.ad*(2*obj.rotorRadius) + dx * obj.bd); % bladerotation-induced lateral offset

            dz = obj.wakeDir(3)*displacements + ...  % initial position + yaw*tilt induced offset
                (obj.at*(2*obj.rotorRadius) + dx * obj.bt); % bladerotation-induced vertical offset
        end
    end
end

