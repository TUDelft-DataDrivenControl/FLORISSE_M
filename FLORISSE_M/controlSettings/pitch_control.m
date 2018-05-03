classdef pitch_control < control_prototype
    %pitch_control Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function obj = pitch_control(layout)
            %pitch_control Construct an instance of this class
            %   Detailed explanation goes here
            obj = obj@control_prototype(length(layout.turbines));
            controlType = 'pitch';
            
            % The turbinetypes provide handles and do this not have to be
            % returned to the layout to be changed.
            for turbine = layout.uniqueTurbineTypes
                turbine.controlMethod = controlType;
            end
            % Set the controlType in the current control set
            obj.set_control_type(controlType);
        end
    end
end

