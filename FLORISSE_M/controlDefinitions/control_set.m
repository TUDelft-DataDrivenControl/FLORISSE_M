classdef control_set < matlab.mixin.Copyable %handle
    %CONTROL_SET The control_set class generates an object that is used to control the turbines in a layout.
    %   A layout object holds an array of turbines, this class
    %   holds a struct with the control settings for each turbines. It has
    %   several vector inputs, namely, yaw, tilt, pitch and axial induction
    %   These are dynamically linked to the control struct via dependent
    %   properties. This class also checks that control settings are valid.
    
    properties
        controlMethod % ControlMethod used in layout
        verbose
    end
    % The layout can be set during construction but is not allowed to be
    % changed afterwards. (SetAccess = immutable)
    properties (SetAccess = immutable)
        layout % Layout that is controlled by this controlset
    end
    
    % The pattern used in this object is explained here:
    % https://blogs.mathworks.com/loren/2012/03/26/considering-performance-in-object-oriented-matlab-code/
    % There is a private variable that actually holds the data, the
    % publicly accessable properties are dependent variables that have
    % getter and setter functions defined. Since turbineControls should be
    % fully dependent it only has a getter method
    properties (Access = private)
        deratingPropertiesList
        turbineControls_
        
        % Properties for redirection control: must append with 'Array_' (!)
        yawAngleWFArray_
        yawAngleIFArray_
        tiltAngleArray_
        
        % Properties for turbine derating: must append with 'Array_' (!)
        pitchAngleArray_
        tipSpeedRatioArray_
        axialInductionArray_
        relPowerSetpointArray_
        % ... Append here to add more. Do not forget to add .set and .get
        % functions for newly defined derating variables
    end
    
    properties (Dependent)
        turbineControls % A struct array with the controlsettings ordered per turbine
        
        % Properties for redirection control: must append with 'Array_' (!)
        yawAngleWFArray % An array with the yawAngles for each turbine (wind frame)
        yawAngleIFArray % An array with the yawAngles for each turbine (inertial frame)
        tiltAngleArray % An array with the tiltAngles for each turbine
        
        % Properties for turbine derating: must append with 'Array' (!)
        pitchAngleArray % An array with the pitchAngles for each turbine
        tipSpeedRatioArray % An array with the tipSpeedRatios for each turbine
        axialInductionArray % An array with the axialInductions for each turbine
        relPowerSetpointArray % An array with the relative power setpoints (P/Pgreedy) for each turbine
        % ... Append here to add more Do not forget to add .set and .get
        % functions for newly defined derating variables
    end
    
    methods
        function obj = control_set(layout, controlMethod, verbose)
            % CONTROL_SET constructs the function by instantiating the yaw
            % and tilt angles for each turbine at 0. And creating an empty
            % struct that will hold all relevant control settings for each
            % turbine
            
            if nargin < 3 
                verbose = 0; 
            end
            
            obj.verbose = verbose;
            obj.layout  = layout;
            obj.yawAngleWFArray_  = zeros(1, obj.layout.nTurbs);
            obj.yawAngleIFArray_  = layout.ambientInflow.windDirection*ones(1, obj.layout.nTurbs);
            obj.tiltAngleArray_ = zeros(1, obj.layout.nTurbs);
            
            % Collect all properties that are used for derating control
            derPropList = properties(obj);
            nonArrayIndxs = cellfun('isempty',regexp(derPropList,regexptranslate('wildcard','*Array')));
            derPropList(nonArrayIndxs) =[]; % Exclude all variables that do not end with 'Array'
            derPropList(strcmp(derPropList,'yawAngleWFArray'))  =[]; % Exclude yawAngleWFArray for derating control
            derPropList(strcmp(derPropList,'yawAngleIFArray'))  =[]; % Exclude yawAngleIFArray for derating control
            derPropList(strcmp(derPropList,'tiltAngleArray')) =[]; % Exclude tiltAngleArray for derating control
            if verbose; disp(['Variables in control_set.m for derating control: ' strjoin(derPropList,', ') ]); end
            obj.deratingPropertiesList = derPropList;
            
            % controlStruct is the struct that is send to the CP/CT function of a turbine
            controlStruct = struct('yawAngleWF',      {0} , ...
                                   'yawAngleIF',      {layout.ambientInflow.windDirection},...
                                   'tiltAngle',       {0} , ...
                                   'thrustDirection', {[0; 0; 0]} , ...
                                   'thrustAngle',     {0} , ...
                                   'wakeNormal',      {[0; 0; 0]});
            
            % Set all turbine derating variables to NaN by default
            for i = 1:length(obj.deratingPropertiesList)
                fullPropertiesName = obj.deratingPropertiesList{i};
                singleEntryName    = fullPropertiesName(1:end-5); % Exclude last 5 letters ('Array') from string
                controlStruct.(singleEntryName) = {nan};
            end
                               
            % The turbineControls property wil hold a struct array with one struct per turbine.
            obj.turbineControls_ = repmat(controlStruct, obj.layout.nTurbs, 1);
            
            % Set the controlType in the current control set
            obj.controlMethod = controlMethod;
        end
        
        function set.controlMethod(obj, controlMethod)
            % CONTROLMETHOD The controlMethod specifies what method of
            % turbine control will be used. Currently this can be either
            % pitch control, greedy control (which has optimal pitch),
            % axial induction control or tip speed ratio control.
            obj.controlMethod = controlMethod;
            obj.instantiate_control_variables()
        end

        % Define setter and getter methods with value checking and
        % controlstruct updating
        function set.yawAngleWFArray(obj, array)
            obj.check_doubles_array(array)
            obj.check_angles_in_rad(array)
            obj.yawAngleWFArray_ = array;
            obj.yawAngleIFArray_ = array+obj.layout.ambientInflow.windDirection;
            % The orientation of the turbine changed so the dependent
            % properties need to be updated
            obj.update_wake_thrust_direction()
        end
        function yawsWF = get.yawAngleWFArray(obj)
            yawsWF = obj.yawAngleWFArray_;
        end
        
        function set.yawAngleIFArray(obj, array)
            obj.check_doubles_array(array)
            obj.yawAngleIFArray_ = array;
            obj.yawAngleWFArray_ = rem(array-obj.layout.ambientInflow.windDirection,2*pi);
            obj.check_angles_in_rad(obj.yawAngleWFArray_)
            % The orientation of the turbine changed so the dependent
            % properties need to be updated
            obj.update_wake_thrust_direction()
        end
        function yawsIF = get.yawAngleIFArray(obj)
            yawsIF = obj.yawAngleIFArray_;
        end        
        
        function set.tiltAngleArray(obj, array)
            obj.check_doubles_array(array)
            obj.check_angles_in_rad(array)
            obj.tiltAngleArray_ = array;
            % The orientation of the turbine changed so the dependent
            % properties need to be updated
            obj.update_wake_thrust_direction()
        end
        function tilts = get.tiltAngleArray(obj)
            tilts = obj.tiltAngleArray_;
        end
        
        function set.pitchAngleArray(obj, array)
            obj.check_doubles_array(array)
            obj.pitchAngleArray_ = array;
            for i = 1:obj.layout.nTurbs
                obj.turbineControls_(i).pitchAngle = obj.pitchAngleArray_(i);
            end
        end
        function pitches = get.pitchAngleArray(obj)
            pitches = obj.pitchAngleArray_;
        end
        
        function set.tipSpeedRatioArray(obj, array)
            obj.check_doubles_array(array)
            obj.tipSpeedRatioArray_ = array;
            for i = 1:obj.layout.nTurbs
                obj.turbineControls_(i).tipSpeedRatio = obj.tipSpeedRatioArray_(i);
            end
        end
        function tsrs = get.tipSpeedRatioArray(obj)
            tsrs = obj.tipSpeedRatioArray_;
        end
        
        function set.relPowerSetpointArray(obj, array)
            if any(array < 0) || any(array > 1)
                error('Relative power setpoint should be within range [0, 1].');
            end
            obj.relPowerSetpointArray_ = array;
            for i = 1:obj.layout.nTurbs
                obj.turbineControls_(i).relPowerSetpoint = obj.relPowerSetpointArray_(i);
            end
        end
        function setpoints = get.relPowerSetpointArray(obj)
            setpoints = obj.relPowerSetpointArray_;
        end
        
        function set.axialInductionArray(obj, array)
            obj.check_doubles_array(array)
            obj.axialInductionArray_ = array;
            for i = 1:obj.layout.nTurbs
                obj.turbineControls_(i).axialInduction = obj.axialInductionArray_(i);
            end
        end
        function ais = get.axialInductionArray(obj)
            ais = obj.axialInductionArray_;
        end
        
        function td = get.turbineControls(obj)
            td = obj.turbineControls_;
        end
    end
    
    methods (Access = protected)
        function instantiate_control_variables(obj)
            % The turbinetypes are handle objects and due to this they do
            % not have to be returned to the layout to be changed, they can
            % simply be set to the correct controlType
            
            verbose = obj.verbose; % verbose=1 for debugging/understanding the code
            
            for turbine = obj.layout.uniqueTurbineTypes
                turbine.controlMethod = obj.controlMethod;
            end
            
            % Initialize all derating control variables by default as NaN
            for i = 1:length(obj.deratingPropertiesList)
                obj.([obj.deratingPropertiesList{i} '_']) = nan*ones(1,obj.layout.nTurbs);
                if verbose; disp(['Initialized ''' obj.deratingPropertiesList{i} '_'' as NaN.']); end;
            end
            
            % The default control variables for 'axialInduction' are
            % defined as follows
            if strcmp(obj.controlMethod,'axialInduction')
                obj.axialInductionArray_ = 1/3*ones(1,obj.layout.nTurbs); % Axial induction factors, by default set to greedy\
                if verbose; disp(['Initialized '' axialInductionArray_ '' as NaN.']); end
            else
                % If the controlMethod deviates from 'axialInduction', then
                % the user has to have manually specified the initial
                % conditions in the cpctMapObj object, according to the
                % function 'cpctMapObj.initialValues'.
                [initValStruct] = turbine.cpctMapObj.initialValues; % Initial values from function
                propsToOverwrite = fieldnames(initValStruct);
                for i = 1:length(propsToOverwrite)
                    obj.([propsToOverwrite{i} 'Array_']) = initValStruct.(propsToOverwrite{i}) * ones(1,obj.layout.nTurbs);
                    if verbose; disp(['Overwritten ''' propsToOverwrite{i} 'Array_'' as ' num2str(initValStruct.(propsToOverwrite{i})) '.']); end
                end
            end

            % Enforce dependencies between obj.turbineControls_.* and obj.*
            for i = 1:length(obj.deratingPropertiesList)
                for ji = 1:obj.layout.nTurbs
                    % Assumed all plural names have single letter (.e.g, 's') at end
                    pluralName   = obj.deratingPropertiesList{i}; 
                    singularName = pluralName(1:end-5); % Remove 'Array' from end
                    obj.turbineControls_(ji).(singularName) = obj.([pluralName '_'])(ji);
                end
                if verbose; disp(['Linked turbineControls_.' singularName ' to ' pluralName '.']); end
            end
        end
        
        % Define update function for controlStructArray, it is called by
        % the yaw and tilt setter methods
        function update_wake_thrust_direction(obj)
            % For each turbine compute the new wake direction and update
            % the controls struct
            for i = 1:obj.layout.nTurbs
                obj.turbineControls_(i).yawAngleWF = obj.yawAngleWFArray(i);
                obj.turbineControls_(i).yawAngleIF = obj.yawAngleIFArray(i);
                obj.turbineControls_(i).tiltAngle = obj.tiltAngleArray(i);
                obj.turbineControls_(i).thrustDirection = floris_eul2rotm(-[obj.yawAngleWFArray(i) obj.tiltAngleArray(i) 0],'ZYZ')*-[1;0;0];
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
