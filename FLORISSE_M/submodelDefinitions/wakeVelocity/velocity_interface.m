classdef velocity_interface
    %VELOCITY_INTERFACE This superclass defines the methods that must be
    %implemented to create a valid wake_velocity_deficit obbject
    
    methods (Abstract)
        deficit(obj, U, x, y, z)
        boundary(obj, x, y, z)
    end
end
