classdef greedy_control < control_prototype
    %greedy_control Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function obj = greedy_control(layout)
            %greedy_control Construct an instance of this class
            %   Detailed explanation goes here
            obj = obj@control_prototype(length(layout.turbines));
            controlType = 'greedy';
            
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

