classdef control_set < handle
    %CONTROL_SET The control_set class generates object that are used to
    %control the turbines in a situation.
    %   A situation or layout object holds an array of turbines, this class
    %   holds a struct with the control settings for each turbines. It has
    %   several vector inputs, namely, yaw, tilt, pitch and axial induction
    %   These are dynamically linked to the control struct via dependent
    %   properties. This class also checks that control settings are valid
    %   in the sense that they have to contain arrays of doubles.
    
    properties
        controlMethod
    end
    % The layout can be set during construction but is not allowed to be
    % changed afterwards. (SetAccess = immutable)
    properties (SetAccess = immutable)
        layout
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
        function obj = control_set(layout, controlMethod)
            % CONTROL_SET constructs the function by instantiating the yaw
            % and tilt angles for each turbine at 0. And creating an empty
            % struct that will hold all relevant control settings for each
            % turbine
            obj.layout = layout;
            obj.yawAngles_ = zeros(1, obj.layout.nTurbs);
            obj.tiltAngles_ = zeros(1, obj.layout.nTurbs);
            % initStruct is the struct that is send to the CP/CT function of a turbine
            controlStruct = struct('yawAngle',        {0} , ...
                                   'tiltAngle',       {0} , ...
                                   'thrustDirection', {[0; 0; 0]} , ...
                                   'thrustAngle',     {0} , ...
                                   'wakeNormal',      {[0; 0; 0]} , ...
                                   'pitchAngle',      {nan} , ...
                                   'axialInduction',  {nan});
            % The turbineControls property wil hold a struct array with one struct per turbine.
            obj.turbineControls_ = repmat(controlStruct, obj.layout.nTurbs, 1);
            
            % Set the controlType in the current control set
            obj.controlMethod = controlMethod;
        end
        
        function set.controlMethod(obj, controlMethod)
            % CONTROLMETHOD The controlMethod specifies what method of
            % turbine control will be used. Currently this can be either
            % pitch control, greedy control (which has optimal pitch) or
            % axial induction control.
            
            obj.controlMethod = controlMethod;
            % The turbinetypes are handle objects and due to this they do
            % not have to be returned to the layout to be changed, they can
            % simply be set to the correct controlType
%             keyboard
%             for turbine = 1:length(obj.layout.uniqueTurbineTypes)
%                 turbine{1}.controlMethod = controlMethod;
%             end
            obj.layout.uniqueTurbineTypes{1}.controlMethod = controlMethod;
            switch controlMethod
                case {'pitch'}
                    obj.pitchAngles_     = zeros(1,obj.layout.nTurbs);    % Blade pitch angles, by default set to greedy
                    obj.axialInductions_ = nan*ones(1,obj.layout.nTurbs); % Axial inductions  are set to NaN
                case {'greedy'}
                    obj.pitchAngles_     = nan*ones(1,obj.layout.nTurbs); % Blade pitch angles are set to NaN
                    obj.axialInductions_ = nan*ones(1,obj.layout.nTurbs); % Axial inductions  are set to NaN
                case {'axialInduction'}
                    obj.pitchAngles_     = nan*ones(1,obj.layout.nTurbs); % Blade pitch angles are set to NaN
                    obj.axialInductions_ = 1/3*ones(1,obj.layout.nTurbs); % Axial induction factors, by default set to greedy
                otherwise
                    error(['Control methodology with name: "' controlMethod '" not defined']);
            end
            for i = 1:obj.layout.nTurbs
                obj.turbineControls_(i).axialInduction = obj.axialInductions(i);
                obj.turbineControls_(i).pitchAngle = obj.pitchAngles(i);
            end
        end

        % Define setter and getter methods with value checking and
        % controlstruct updating
        function set.yawAngles(obj, array)
            obj.check_doubles_array(array)
            obj.check_angles_in_rad(array)
            obj.yawAngles_ = array;
            obj.updateTurbineControlsStruct()
        end
        function yaws = get.yawAngles(obj)
            yaws = obj.yawAngles_;
        end
        
        function set.tiltAngles(obj, array)
            obj.check_doubles_array(array)
            obj.check_angles_in_rad(array)
            obj.tiltAngles_ = array;
            obj.updateTurbineControlsStruct()
        end
        function tilts = get.tiltAngles(obj)
            tilts = obj.tiltAngles_;
        end
        
        function set.pitchAngles(obj, array)
            obj.check_doubles_array(array)
            obj.pitchAngles_ = array;
            for i = 1:obj.layout.nTurbs
                obj.turbineControls_(i).pitchAngle = obj.pitchAngles(i);
            end
        end
        function pitches = get.pitchAngles(obj)
            pitches = obj.pitchAngles_;
        end
        
        function set.axialInductions(obj, array)
            obj.check_doubles_array(array)
            obj.axialInductions_ = array;
            for i = 1:obj.layout.nTurbs
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
            for i = 1:obj.layout.nTurbs
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
        
        function check_doubles_array(obj, x)
            % check_doubles_array is a function that checks if an array with
            % control settings is of the right length and type
            if ~isa(x, 'double') || ~all(size(x)==[1, obj.layout.nTurbs])
                error('check_doubles_array:valueError', 'value must be a column vector of doubles with length %d', obj.layout.nTurbs);
            end
        end
        function check_angles_in_rad(obj, x)
            % check_angles_in_rad is a function that checks if an array with
            % control settings only holds values in between -90 and +90
            % degrees in rad
            if any(x<-pi/2) || any(x>pi/2)
                error('check_angles_in_rad:valueError', 'angle values must be specified in radians and face into the wind, angle>pi/2 || angle<pi/2');
            end
        end
    end
end
