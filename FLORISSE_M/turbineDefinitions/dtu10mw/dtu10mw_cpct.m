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
                case {'yaw'}
                    loadedData = load('dtu10mw_database.mat');
                    zeroYawIdx = find(abs(loadedData.yaw)<1e-6); % Extract zero yaw Cp-Ct values
                    zeroDeratingIdx = find(abs(loadedData.servo-100) < 1e-6); % Extract zero derating Cp-Ct values
                    structLUT.wsRange = loadedData.wind;
                    structLUT.lutCp = squeeze(loadedData.mean_Cp(:,zeroDeratingIdx,zeroYawIdx))';
                    structLUT.lutCt = squeeze(loadedData.mean_Ct(:,zeroDeratingIdx,zeroYawIdx))';   
                    
                case {'yawAndRelPowerSetpoint'}
                    loadedData = load('dtu10mw_database.mat');
                    structLUT.wsRange       = loadedData.wind;
                    structLUT.yawRange      = deg2rad(loadedData.yaw);
                    structLUT.setpointRange = loadedData.servo/100; % Ratio of power extraction (1=greedy)
                    structLUT.lutCp         = loadedData.mean_Cp;
                    structLUT.lutCt         = loadedData.mean_Ct;
                    
                    % Format to monotonically increasing relPowerSetpoint
                    structLUT.setpointRange = structLUT.setpointRange(end:-1:1);
                    structLUT.lutCp = structLUT.lutCp(:,end:-1:1,:);
                    structLUT.lutCt = structLUT.lutCt(:,end:-1:1,:);
                    
                    % Create interpolants
                    [X,Y,Z] = ndgrid(structLUT.wsRange,structLUT.setpointRange,structLUT.yawRange);
                    structLUT.cpFun = griddedInterpolant(X,Y,Z, structLUT.lutCp,'linear','none'); % Linear interpolation, no extrapolation
                    structLUT.ctFun = griddedInterpolant(X,Y,Z, structLUT.lutCt,'linear','none'); % Linear interpolation, no extrapolation
                    
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
                case {'yaw'}
                    out = struct('yawAngleWF',0); % Initialize default values                
                case {'yawAndRelPowerSetpoint'}
                    out = struct('yawAngleWF',0,'relPowerSetpoint',1); % Initialize default values
                otherwise
                    error(['Control methodology with name: "' obj.controlMethod '" not defined']);
            end
        end
        
        
        % Interpolation functions to go from LUT to actual values
        function [cp,ct,adjustCpCtYaw] = calculateCpCt(obj,condition,turbineControl)
            controlMethod = obj.controlMethod;
            structLUT     = obj.structLUT;
            
            switch controlMethod     
                case {'yaw'}
                    if condition.avgWS < 4.0 || condition.avgWS > 24.0 % Cut-in/cut out wind speed
                        cp = 0.0;
                        ct = 2*eps; % eps to avoid numerical issues
                        adjustCpCtYaw = false; % do function call 'adjust_cp_ct_for_yaw' after this func.
                    else
                        cp = interp1(structLUT.wsRange,structLUT.lutCp,condition.avgWS);
                        ct = interp1(structLUT.wsRange,structLUT.lutCt,condition.avgWS);
                        adjustCpCtYaw = true; % do function call 'adjust_cp_ct_for_yaw' after this func.
                    end
                    
                case {'yawAndRelPowerSetpoint'}
                    if condition.avgWS < 4.0 || condition.avgWS > 24.0 % Cut-in/cut out wind speed
                        cp = 0.0;
                        ct = 2*eps; % eps to avoid numerical issues
                    elseif condition.avgWS * cos(turbineControl.yawAngleWF)^2 >= 11.4 % rated wind speed
                        cp = 10e6/(0.5*condition.rho*0.25*pi*178.3^2*(condition.avgWS^3.0)*1.08);
                        ct = structLUT.ctFun(condition.avgWS,turbineControl.relPowerSetpoint,turbineControl.yawAngleWF);
                    else
                        cp = structLUT.cpFun(condition.avgWS,turbineControl.relPowerSetpoint,turbineControl.yawAngleWF) ...
                             / cos(turbineControl.yawAngleWF)^1.2 ;
                        ct = structLUT.ctFun(condition.avgWS,turbineControl.relPowerSetpoint,turbineControl.yawAngleWF);
                    end
                    
                    adjustCpCtYaw = false; % do function call 'adjust_cp_ct_for_yaw' after this func.

                otherwise
                    error('Control methodology with name: "%s" not defined', obj.controlMethod);
            end
            
            if ct >= 1.0
                %disp(['WARNING: According to LUT, Ct = ' num2str(ct) '. Thresholding at Ct = 1.']);
                ct = 1.0;
            end
            
        end
        
    end
end
