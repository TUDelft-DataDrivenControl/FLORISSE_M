classdef deflection_interface
    %DEFLECTION_INTERFACE This class defines the functions that classes
    %which describe wake centerline deflection have to implement.
    
    methods (Abstract)
        deflection(obj, x) % Computes deflection based on downwind distance x
    end
end
