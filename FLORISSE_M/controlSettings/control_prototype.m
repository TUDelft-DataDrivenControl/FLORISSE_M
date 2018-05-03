classdef control_prototype < handle
    %control_prototype Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        nTurbs
    end
    
    % The pattern used in this object is explained here:
    % https://blogs.mathworks.com/loren/2012/03/26/considering-performance-in-object-oriented-matlab-code/
    % There is a private variable that actually holds the data, the
    % publicly accesable properties are dependent variables that have
    % getter and setter functions defined. Since turbineControls should be
    % fully dependent it only has a getter method
    properties (Access = private)
        turbineControls_
        yawAngles_
        tiltAngles_
        pitchAngles_
        axialInductions_
    end
    
    properties (Dependent)
        turbineControls
        yawAngles
        tiltAngles
        pitchAngles
        axialInductions
    end
    
    methods
        function obj = control_prototype(layout, controlType)
            obj.nTurbs = length(layout.turbines);
            obj.yawAngles_ = zeros(obj.nTurbs, 1);
            obj.tiltAngles_ = zeros(obj.nTurbs, 1);
            % initStruct is the struct that is send to the CP/CT function of a turbine
            controlStruct = struct('yawAngle',        {0} , ...
                                   'tiltAngle',       {0} , ...
                                   'thrustDirection', {[0; 0; 0]} , ...
                                   'thrustAngle',     {0} , ...
                                   'wakeNormal',      {[0; 0; 0]} , ...
                                   'pitchAngle',      {0} , ...
                                   'axialInduction',  {0});
            % The turbineControls property wil hold a struct array with one struct per turbine.
            obj.turbineControls_ = repmat(controlStruct, obj.nTurbs, 1);
            
            % The turbinetypes are handle objects and due to this they do
            % not have to be returned to the layout to be changed.
            for i = 1:length(layout.uniqueTurbineTypes)
                layout.uniqueTurbineTypes{i}.controlMethod = controlType;
            end
            % Set the controlType in the current control set
            obj.set_control_type(controlType);
        end
        
        function set_control_type(obj, controlType)
            
            switch controlType
                case {'pitch'}
                    obj.pitchAngles_     = zeros(1,obj.nTurbs);    % Blade pitch angles, by default set to greedy
                    obj.axialInductions_ = nan*ones(1,obj.nTurbs); % Axial inductions  are set to NaN
                case {'greedy'}
                    obj.pitchAngles_     = nan*ones(1,obj.nTurbs); % Blade pitch angles are set to NaN
                    obj.axialInductions_ = nan*ones(1,obj.nTurbs); % Axial inductions  are set to NaN
                case {'axialInduction'}
                    obj.pitchAngles_     = nan*ones(1,obj.nTurbs); % Blade pitch angles are set to NaN
                    obj.axialInductions_ = 1/3*ones(1,obj.nTurbs); % Axial induction factors, by default set to greedy
                otherwise
                    error(['Control methodology with name: "' controlType '" not defined']);
            end
        end
        
        % Define setter and getter methods with value checking and
        % controlstruct construction
        function set.yawAngles(obj, value)
            checkValue(value, obj.nTurbs)
            obj.yawAngles_ = value;
            obj.updateTurbineControlsStruct()
        end
        function yaws = get.yawAngles(obj)
            yaws = obj.yawAngles_;
        end
        
        function set.tiltAngles(obj, value)
            checkValue(value, obj.nTurbs)
            obj.tiltAngles_ = value;
            obj.updateTurbineControlsStruct()
        end
        function tilts = get.tiltAngles(obj)
            tilts = obj.tiltAngles_;
        end
        
        function set.pitchAngles(obj, value)
            checkValue(value, obj.nTurbs)
            obj.pitchAngles_ = value;
            for i = 1:obj.nTurbs
                obj.turbineControls_(i).pitchAngle = obj.pitchAngles(i);
            end
        end
        function pitches = get.pitchAngles(obj)
            pitches = obj.pitchAngles_;
        end
        
        function set.axialInductions(obj, value)
            checkValue(value, obj.nTurbs)
            obj.axialInductions_ = value;
            for i = 1:obj.nTurbs
                obj.turbineControls_(i).axialInduction = obj.axialInductions(i);
            end
        end
        function ais = get.axialInductions(obj)
            ais = obj.axialInductions_;
        end
        
        % Define update function for controlStructArray, it is called by
        % the other setter methods where relevant
        function updateTurbineControlsStruct(obj)
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
        % Define getter method for public controlStruct
        function td = get.turbineControls(obj)
            td = obj.turbineControls_;
        end
    end
end

function checkValue(x, reqLength)
    if ~isa(x, 'double') || ~all(size(x)==[reqLength, 1])
        error('value must be a column vector of doubles with length %d', reqLength);
    end
end