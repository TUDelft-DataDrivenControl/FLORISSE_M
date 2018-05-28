classdef added_ti_interface
    %ADDED_TI_INTERFACE This class defines the functions that classes
    %which describe an added turbulence model have to implement
    
    methods (Abstract)
        added_TI(obj, x, TI0)
        % Computes added turbulence caused by rotor at downwind distance x
    end
end
