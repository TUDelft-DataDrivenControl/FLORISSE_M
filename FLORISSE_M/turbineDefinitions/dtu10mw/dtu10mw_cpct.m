classdef dtu10mw_cpct < handle
    
    properties
        controlMethod % The controlMethod that is being used in this turbine
        structLUT % Struct() containing all the preloaded LUT info
    end
    
    methods
        
        % Initialization of the Cp-Ct mapping (LUTs)
        function obj = dtu10mw_cpct(controlMethod)
            %TURBINE_TYPE Construct an instance of this class
            %   The turbine characters are saved as properties
            obj.controlMethod = controlMethod;
            
            % Initialize LUTs
            switch controlMethod
                
%                 case {'greedy'}
%                     % Load the lookup table for cp and ct as a function of windspeed
%                     structLUT.wsRange = [...];
%                     structLUT.lutCp   = [...];
%                     structLUT.lutCt   = [...];
                                    
                case {'axialInduction'}
                    % No preparation needed
                    structLUT = struct();
                    
                otherwise
                    error('Control methodology with name: "%s" not defined for the DTU 10MW turbine', controlMethod);
            end
            
            obj.structLUT = structLUT;
        end
        
        
        % Initial values when initializing the turbines
        function [pitch,TSR,axInd] = initialValues(obj)
            switch obj.controlMethod
%                 case {'greedy'}
%                     pitch = nan; % Blade pitch angles are set to NaN
%                     TSR   = nan; % Lambdas  are set to NaN
%                     axInd = nan; % Axial inductions  are set to NaN
                otherwise
                    error(['Control methodology with name: "' obj.controlMethod '" not defined']);
            end
        end
        
        
        % Interpolation functions to go from LUT to actual values
        function [cp,ct,adjustCpCtYaw] = calculateCpCt(obj,condition,turbineControl)
            controlMethod = obj.controlMethod;
            structLUT     = obj.structLUT;
            
            switch controlMethod                     
%                 case {'greedy'}
%                     cp = interp1(structLUT.wsRange, structLUT.lutCp, condition.avgWS);
%                     ct = interp1(structLUT.wsRange, structLUT.lutCt, condition.avgWS);
%                     adjustCpCtYaw = true; % do function call 'adjust_cp_ct_for_yaw' after this func.
                    
                otherwise
                    error('Control methodology with name: "%s" not defined', obj.controlMethod);
            end
            
        end
        
    end
end
