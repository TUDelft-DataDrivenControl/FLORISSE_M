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
                
                case {'yawAndRelPowerSetpoint'}
                    loadedData = load('dtu10mw_database.mat');
                    structLUT.wsRange       = loadedData.wind;
                    structLUT.yawRange      = deg2rad(loadedData.yaw);
                    structLUT.setpointRange = loadedData.servo/100; % Ratio of power extraction (1=greedy)
                    structLUT.lutCp         = loadedData.mean_Cp;
                    structLUT.lutCt         = loadedData.mean_Ct;
                    
                    % Format to monotonically increasing relPowerSetpoint
                    structLUT.setpointRange = structLUT.setpointRange(end:-1:1);
                    lutCp = structLUT.lutCp(:,end:-1:1,:);
                    lutCt = structLUT.lutCt(:,end:-1:1,:);
                    
                    % Create interpolants
                    [X,Y,Z] = ndgrid(structLUT.wsRange,structLUT.setpointRange,structLUT.yawRange);
                    structLUT.cpFun = griddedInterpolant(X,Y,Z, structLUT.lutCp);
                    structLUT.ctFun = griddedInterpolant(X,Y,Z, structLUT.lutCt);
                    
                case {'axialInduction'}
                    % No preparation needed
                    structLUT = struct();
                    
                otherwise
                    error('Control methodology with name: "%s" not defined for the DTU 10MW turbine', controlMethod);
            end
            
            obj.structLUT = structLUT;
        end
        
        
        % Initial values when initializing the turbines
        function [out] = initialValues(obj)
            switch obj.controlMethod
                case {'yawAndRelPowerSetpoint'}
                    out = struct('yawAngle',0,'relPowerSetpoint',1); % Initialize default values
                otherwise
                    error(['Control methodology with name: "' obj.controlMethod '" not defined']);
            end
        end
        
        
        % Interpolation functions to go from LUT to actual values
        function [cp,ct,adjustCpCtYaw] = calculateCpCt(obj,condition,turbineControl)
            controlMethod = obj.controlMethod;
            structLUT     = obj.structLUT;
            
            switch controlMethod                     
                case {'yawAndRelPowerSetpoint'}
                    cp = structLUT.cpFun(condition.avgWS,turbineControl.relPowerSetpoint,turbineControl.yawAngle);
                    ct = structLUT.ctFun(condition.avgWS,turbineControl.relPowerSetpoint,turbineControl.yawAngle);
                    adjustCpCtYaw = false; % do function call 'adjust_cp_ct_for_yaw' after this func.
                    
                otherwise
                    error('Control methodology with name: "%s" not defined', obj.controlMethod);
            end
            
        end
        
    end
end
