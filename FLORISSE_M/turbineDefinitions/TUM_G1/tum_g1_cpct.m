classdef tum_g1_cpct < handle
    
    properties
        controlMethod % The controlMethod that is being used in this turbine
        structLUT % Struct() containing all the preloaded LUT info
    end
    
    methods
        
        % Initialization of the Cp-Ct mapping (LUTs)
        function obj = tum_g1_cpct(controlMethod)
            %TURBINE_TYPE Construct an instance of this class
            %   The turbine characters are saved as properties
            obj.controlMethod = controlMethod;
            
            % Initialize LUTs
            switch controlMethod
                % use pitch angles and Cp-Ct LUTs for pitch and WS,
                case {'pitch'}
                    % Load the lookup tables for cp and ct as a function of windspeed and pitch
                    tmpCsvCp             = csvread('g1_cpPitch.csv');
                    tmpCsvCt             = csvread('g1_ctPitch.csv');
                    structLUT.pitchRange = tmpCsvCp(2:end,1);
                    structLUT.wsRange    = tmpCsvCp(1,2:end);
                    structLUT.lutCp      = tmpCsvCp(2:end,2:end);
                    structLUT.lutCt      = tmpCsvCt(2:end,2:end);
                 
                case {'greedy'}
                    % Load the lookup table for cp and ct as a function of windspeed
                    structLUT.wsRange = [1.96,2.06,2.16,2.26,2.36,2.46,2.56,2.66,2.76,2.86,2.96,3.06,3.16,3.26,3.36,3.46,3.56,3.66,3.76,3.86,3.96,4.06,4.16,4.26,4.36,4.46,4.56,4.66,4.76,4.86,4.96,5.06,5.16,5.26,5.36,5.46,5.56,5.66,5.76,5.86,5.87,5.96,6.06,6.16,6.26,6.36,6.46,6.56,6.66,6.76,6.86,6.96,7.06,7.56,8.06,8.56,9.06,9.56,10.06,10.56,11.06,11.56,12.06,12.56];
                    structLUT.lutCp   = [0.25,0.26,0.27,0.28,0.29,0.29,0.3,0.31,0.31,0.32,0.32,0.33,0.33,0.34,0.34,0.35,0.35,0.36,0.36,0.36,0.37,0.37,0.37,0.38,0.38,0.38,0.38,0.38,0.38,0.38,0.38,0.38,0.38,0.38,0.38,0.38,0.38,0.38,0.38,0.38,0.38,0.38,0.38,0.36,0.34,0.33,0.31,0.3,0.28,0.27,0.26,0.25,0.24,0.19,0.16,0.13,0.11,0.1,0.08,0.07,0.06,0.05,0.05,0.04];
                    structLUT.lutCt   = [0.73,0.73,0.73,0.74,0.74,0.74,0.74,0.75,0.75,0.75,0.75,0.75,0.76,0.76,0.76,0.76,0.76,0.77,0.77,0.77,0.78,0.78,0.78,0.78,0.78,0.78,0.78,0.78,0.78,0.78,0.78,0.79,0.79,0.79,0.79,0.79,0.79,0.8,0.8,0.81,0.81,0.81,0.82,0.71,0.66,0.61,0.57,0.54,0.51,0.48,0.46,0.43,0.41,0.33,0.27,0.22,0.19,0.16,0.14,0.13,0.11,0.1,0.09,0.09];
                    
                case {'axialInduction'}
                    % No preparation needed
                    structLUT = struct();
                    
                otherwise
                    error('Control methodology with name: "%s" not defined for the TUM G1 turbine', controlMethod);
            end
            
            obj.structLUT = structLUT;
        end
        
        
        % Initial values when initializing the turbines
        function [out] = initialValues(obj)
            switch obj.controlMethod
                case {'pitch'}
                    out = struct('pitchAngle',0);
                case {'greedy'}
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
                case {'pitch'}
                    cp = interp2(structLUT.wsRange, deg2rad(structLUT.pitchRange),...
                        structLUT.lutCp, condition.avgWS, turbineControl.pitchAngle,'linear',0.00);
                    ct = interp2(structLUT.wsRange, deg2rad(structLUT.pitchRange),...
                        structLUT.lutCt, condition.avgWS, turbineControl.pitchAngle,'linear',1e-5);
                    adjustCpCtYaw = true; % do function call 'adjust_cp_ct_for_yaw' after this func.
                    
                case {'greedy'}
                    cp = interp1(structLUT.wsRange, structLUT.lutCp, condition.avgWS,'linear',0.00);
                    ct = interp1(structLUT.wsRange, structLUT.lutCt, condition.avgWS,'linear',1e-5);
                    adjustCpCtYaw = true; % do function call 'adjust_cp_ct_for_yaw' after this func.
                    
                otherwise
                    error('Control methodology with name: "%s" not defined', obj.controlMethod);
            end
            
        end
        
    end
end
