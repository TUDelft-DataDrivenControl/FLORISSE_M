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
                
                case {'yawAndPowerDerating'}
                    loadedData = load('dtu10mw_database.mat');
                    structLUT.wsRange    = loadedData.wind;
                    structLUT.yawRange   = deg2rad(loadedData.yaw);
                    structLUT.servoRange = loadedData.servo; % Percentage of power extraction
                    structLUT.lutCp      = loadedData.mean_Cp;
                    structLUT.lutCt      = loadedData.mean_Ct;
                                    
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
                case {'yawAndPowerDerating'}
                    out = struct(); % Do nothing
                otherwise
                    error(['Control methodology with name: "' obj.controlMethod '" not defined']);
            end
        end
        
        
        % Interpolation functions to go from LUT to actual values
        function [cp,ct,adjustCpCtYaw] = calculateCpCt(obj,condition,turbineControl)
            controlMethod = obj.controlMethod;
            structLUT     = obj.structLUT;
            
            switch controlMethod                     
                case {'yawAndPowerDerating'}
                    cp = interp3(structLUT.wsRange, structLUT.servoRange, structLUT.yawRange, structLUT.lutCp, ...
                                 condition.avgWS, turbineControl.servoSetpoint  ,turbineControl.yawAngle);
                    ct = interp3(structLUT.wsRange, structLUT.servoRange, structLUT.yawRange, structLUT.lutCt, ...
                                 condition.avgWS, turbineControl.servoSetpoint  ,turbineControl.yawAngle);
                    adjustCpCtYaw = false; % do function call 'adjust_cp_ct_for_yaw' after this func.
                    
                otherwise
                    error('Control methodology with name: "%s" not defined', obj.controlMethod);
            end
            
        end
        
    end
end
