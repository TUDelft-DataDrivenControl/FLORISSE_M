classdef mwt12_cpct < handle
    
    properties
        controlMethod % The controlMethod that is being used in this turbine
        structLUT % Struct() containing all the preloaded LUT info
    end
    
    methods
        
        % Initialization of the Cp-Ct mapping (LUTs)
        function obj = mwt12_cpct(controlMethod)
            %TURBINE_TYPE Construct an instance of this class
            %   The turbine characters are saved as properties
            obj.controlMethod = controlMethod;
            
            % Initialize LUTs
            switch controlMethod
                
                case {'tipSpeedRatio'}
                    % Load the lookup table for cp and ct as a function of windspeed
                    structLUT.tsrRange =  [1.0000, 1.5000, 2.0000, 2.5000, 3.0000, 3.5000, 4.0000, 4.5000, 5.0000, 5.5000, 6.0000, 6.5000];
                    structLUT.lutCp    =  [0.0520, 0.0940, 0.1650, 0.2450, 0.3270, 0.3670, 0.3780, 0.3610, 0.3370, 0.2880, 0.2010, 0.0768];
                    structLUT.lutCt    =  [0.4500, 0.5220, 0.5980, 0.6610, 0.7180, 0.7540, 0.7850, 0.8010, 0.8120, 0.8050, 0.7920, 0.7790];
                                    
                case {'axialInduction'}
                    % No preparation needed
                    structLUT = struct();
                    
                otherwise
                    error('Control methodology with name: "%s" not defined for the minit. 12cm turbine', controlMethod);
            end
            
            obj.structLUT = structLUT;
        end
        
        
        % Initial values when initializing the turbines
        function [out] = initialValues(obj)
            switch obj.controlMethod
                case {'tipSpeedRatio'}
                    out = struct('tipSpeedRatio',4.5);
                otherwise
                    error(['Control methodology with name: "' obj.controlMethod '" not defined']);
            end
        end
        
        
        % Interpolation functions to go from LUT to actual values
        function [cp,ct,adjustCpCtYaw] = calculateCpCt(obj,condition,turbineControl)
            controlMethod = obj.controlMethod;
            structLUT     = obj.structLUT;
            
            switch controlMethod                     
                case {'tipSpeedRatio'}
                    cp = interp1(structLUT.tsrRange, structLUT.lutCp, turbineControl.tipSpeedRatio,'linear',0.00);
                    ct = interp1(structLUT.tsrRange, structLUT.lutCt, turbineControl.tipSpeedRatio,'linear',1e-5);
                    adjustCpCtYaw = true;
                    
                otherwise
                    error('Control methodology with name: "%s" not defined', obj.controlMethod);
            end
            
        end
        
    end
end
