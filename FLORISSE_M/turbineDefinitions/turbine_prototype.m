classdef turbine_prototype < handle
    %turbine_prototype This is the superclass for any turbine.
    %   This class inherits from handle. Each turbine object should thus be
    %   considered an immutable description of its characteristics. The
    %   time variable functions of the turbine should not be stored here.
    
    properties
        rotorRadius
        genEfficiency
        hubHeight
        pP
        controlMethod
        dataPath
        cpInterp
        ctInterp
    end
    
    methods
        function obj = turbine_prototype(rotorRadius, genEfficiency, hubHeight,...
                                        pP, path, controlMethod, allowableControlMethods)
            %turbine_prototype Construct an instance of this class
            %   The turbine characters are saved as properties
            obj.rotorRadius = rotorRadius;
            obj.genEfficiency = genEfficiency;
            obj.hubHeight = hubHeight;
            obj.pP = pP;
            
            obj.dataPath = path;
            if ~any(strcmp(allowableControlMethods,controlMethod))
                error(['This turbine does not support control method: "' controlMethod '"']);
            end
            obj.set_cp_and_ct_functions(controlMethod)
        end
        
        function set_cp_and_ct_functions(obj, controlMethod)
            %set_cp_and_ct_functions Create cp and ct functions
            % Herein we define how the turbine are controlled. In the traditional
            % FLORIS model, we directly control the axial induction factor of each
            % turbine. However, to apply this in practise, we still need a mapping to
            % the turbine generator torque and the blade pitch angles. Therefore, we
            % have implemented the option to directly control and optimize the blade
            % pitch angles 'pitch', under the assumption of optimal generator torque
            % control. Additionally, we can also assume fully greedy control, where we
            % cannot adjust the generator torque nor the blade pitch angles ('greedy').
            
            % Choice of how a turbine's axial control setting is determined
            % pitch:          use pitch angles and Cp-Ct LUTs for pitch and WS,
            % greedy:         greedy control   and Cp-Ct LUT for WS,
            % axialInduction: specify axial induction directly.
            obj.controlMethod = controlMethod;
            switch controlMethod
                % use pitch angles and Cp-Ct LUTs for pitch and WS,
                case {'pitch'}
                    % Determine Cp and Ct interpolation functions as a
                    % function of WS and blade pitch
                    for airfoilDataType = {'cp','ct'}
                        % Load file
                        lut       = csvread([obj.dataPath '/' airfoilDataType{1} 'Pitch.csv']);
                        
                        % Wind speed in LUT in m/s
                        lut_ws    = lut(1,2:end);
                        % Blade pitch angle in LUT in radians
                        lut_pitch = deg2rad(lut(2:end,1));
                        % Values of Cp/Ct [dimensionless]
                        lut_value = lut(2:end,2:end);
                        
                        % Define the lookup tables
                        obj.([airfoilDataType{1} 'Interp']) = @(ws,pitch) interp2(lut_ws,lut_pitch,lut_value,ws,pitch);
                    end
                    
                % Greedy control: Optimized control settings are determined
                % based on the windspeed
                case {'greedy'}
                    % Determine Cp and Ct interpolation functions as a function of WS
                    lut                 = load([obj.dataPath '/cpctgreedy.mat']);
                    obj.cpInterp = @(ws) interp1(lut.wind_speed,lut.cp,ws);
                    obj.ctInterp = @(ws) interp1(lut.wind_speed,lut.ct,ws);
                    
                % Directly adjust the axial induction value of each turbine.
                case {'axialInduction'}
                    obj.cpInterp = @(ai) 4*ai*(1-ai);
                    obj.ctInterp = @(ai) 4*ai*(1-ai)^2;
                    
                otherwise
                    error(['Control methodology with name: "' controlMethod '" not defined']);
            end
        end
        
        function cpVal = cp(obj, condition, controlSet)
            %CP returns cp value
            %   Computes the power coefficient for this turbine depending
            %   on the condition at the rotor area and the controlset of
            %   the turbine
            cpVal = obj.cpInterp(condition, controlSet);
        end
        
        function ctVal = ct(obj, condition, controlSet)
            %CT returns ct value
            %   Computes the thrust coefficient for this turbine depending
            %   on the condition at the rotor area and the controlset of
            %   the turbine
            ctVal = obj.ctInterp(condition, controlSet);
        end
    end
end

