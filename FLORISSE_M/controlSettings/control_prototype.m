classdef control_prototype < handle
    %LAYOUTPROTOTYPE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        nTurbs
    end
    properties
        yawAngles
        tiltAngles
        pitchAngles
        axialInductions
    end
    
    % The turbineControls property wil hold a struct array where each
    % struct holds the control prpoerties for one turbine.
    properties (Access = private)
        turbineControls_
        yawAngles_
        tiltAngles_
    end
    properties (Dependent)
        turbineControls
    end
    
    methods
        function obj = control_prototype(nTurbs)
            obj.nTurbs = nTurbs;
            obj.yawAngles_ = zeros(obj.nTurbs, 1);
            obj.tiltAngles_ = zeros(obj.nTurbs, 1);
            initStruct = struct('yawAngle',  {0} , ...
                                'tiltAngle',       {0} , ...
                                'thrustDirection', {[0; 0; 0]} , ...
                                'thrustAngle',     {0} , ...
                                'wakeNormal',      {[0; 0; 0]} , ...
                                'pitchAngle',      {0} , ...
                                'axialInduction',  {0});
            obj.turbineControls_ = repmat(initStruct, 6, 1);
        end
        
        function set_default_controls(obj, controlType)
            switch controlType
                case {'pitch'}
                    obj.pitchAngles     = zeros(1,obj.nTurbs); % Blade pitch angles, by default set to greedy
                    obj.axialInductions = nan*ones(1,obj.nTurbs); % Axial inductions  are set to NaN
                case {'greedy'}
                    obj.pitchAngles     = nan*ones(1,obj.nTurbs); % Blade pitch angles are set to NaN
                    obj.axialInductions = nan*ones(1,obj.nTurbs); % Axial inductions  are set to NaN
                case {'axialInduction'}
                    obj.pitchAngles     = nan*ones(1,obj.nTurbs); % Blade pitch angles are set to NaN
                    obj.axialInductions = 1/3*ones(1,obj.nTurbs); % Axial induction factors, by default set to greedy
                    
                otherwise
                    error(['Control methodology with name: "' controlType '" not defined']);
            end
        end
        
        function set.yawAngles(obj, value)
            checkValue(value, obj.nTurbs)
            obj.yawAngles_ = value;
            obj.setTurbineControlsStruct()
        end
        
        function set.tiltAngles(obj, value)
            checkValue(value, obj.nTurbs)
            obj.tiltAngles_ = value;
            obj.setTurbineControlsStruct()
        end
        
        function set.pitchAngles(obj, value)
            checkValue(value, obj.nTurbs)
            obj.pitchAngles = value;
            for i = 1:obj.nTurbs
                obj.turbineControls_(i).pitchAngle = obj.pitchAngles(i);
            end
        end
        
        function set.axialInductions(obj, value)
            checkValue(value, obj.nTurbs)
            obj.axialInductions = value;
            for i = 1:obj.nTurbs
                obj.turbineControls_(i).axialInduction = obj.axialInductions(i);
            end
        end
        
        function setTurbineControlsStruct(obj)
            % Define an empty structarray that will hold individual turbine controls
            
            for i = 1:obj.nTurbs
                obj.turbineControls_(i).yawAngle = obj.yawAngles(i);
                obj.turbineControls_(i).tiltAngle = obj.tiltAngles(i);
                obj.turbineControls_(i).thrustDirection = floris_eul2rotm(-[obj.yawAngles(i) obj.tiltAngles(i) 0],'ZYZ')*-[1;0;0];
                obj.turbineControls_(i).thrustAngle = acos(dot(obj.turbineControls_(i).thrustDirection,-[1;0;0]));

                % Determine the unit vector orthogonal to the mean wake plane
                % (for tilt = 0 rad, this means [0 0 1], e.g. the z-axis)
                if abs(obj.turbineControls_(i).thrustDirection(1))==1
                    obj.turbineControls_(i).wakeNormal = [0 0 1].';
                else
                    normalize = @(v) v./norm(v); % Normalization function
                    obj.turbineControls_(i).wakeNormal = normalize(cross([1;0;0],obj.turbineControls_(i).thrustDirection));
                end
            end
        end

        function td = get.turbineControls(obj)
            td = obj.turbineControls_;
        end
        
        function ya = get.yawAngles(obj)
            ya = obj.yawAngles_;
        end
        
        function ya = get.tiltAngles(obj)
            ya = obj.tiltAngles_;
        end
    end
end

function checkValue(x, reqLength)
    if ~isa(x, 'double') || ~(length(x)==reqLength)
        error('value must be an array of doubles.');
    end
end