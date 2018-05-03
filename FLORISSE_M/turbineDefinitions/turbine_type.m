classdef turbine_type < handle
    %TURBINE_TYPE This class instantiates turbine_type objects.
    %   This class inherits from handle. This means that if multiple
    %   turbines in a layout use the same turbine type they all refer to
    %   the same actual object. Changing the Cp/Ct functions or
    %   controlmethods for the turbine_type will thus immediately make this
    %   same change to turbines that have the same type. A turbine_type
    %   should thus hold a description of a turbine. The parameters that
    %   vary per simulation such as power are stored elsewhere (TODO: explain where)
    
    properties
        controlMethod
        rotorRadius
        genEfficiency
        hubHeight
        pP
    end
    properties (Access = private)
        allowableControlMethods
        dataPath
        cpInterp
        ctInterp
    end
    
    methods
        function obj = turbine_type(rotorRadius, genEfficiency, hubHeight, pP, path, allowableControlMethods)
            %turbine_prototype Construct an instance of this class
            %   The turbine characters are saved as properties
            obj.controlMethod = nan;
            obj.dataPath = path;
            obj.allowableControlMethods = allowableControlMethods;
            
            obj.rotorRadius = rotorRadius;
            obj.genEfficiency = genEfficiency;
            obj.hubHeight = hubHeight;
            obj.pP = pP;
        end
        
        function set.controlMethod(obj, controlMethod)
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
            
            % If the controlMethod is set to nan skip the rest of this function
            if isnan(controlMethod)
                return
            end
            % If the desired controlMethod is not available for this
            % turbine, throw an error.
            if ~any(strcmp(obj.allowableControlMethods, controlMethod))
                error('The turbine_type defined in \n%s,\ndoes not support the control method: "%s".',...
                      obj.dataPath, controlMethod)
            end
            
            obj.controlMethod = controlMethod;
            
            switch controlMethod
                % use pitch angles and Cp-Ct LUTs for pitch and WS,
                case {'pitch'}
                    % Determine Cp and Ct interpolation functions as a
                    % function of WS and blade pitch
                    airfoilDataType = {'cp','ct'};
                    for i = [1, 2]
                        % Load file
                        lut = csvread([obj.dataPath '/' airfoilDataType{i} 'Pitch.csv']);
                        % Wind speed in LUT in m/s
                        lut_ws    = lut(1,2:end);
                        % Blade pitch angle in LUT in radians
                        lut_pitch = deg2rad(lut(2:end,1));
                        % Values of Cp/Ct [dimensionless]
                        lut_value = lut(2:end,2:end);
                        
                        % Define the lookup tables
                        obj.([airfoilDataType{i} 'Interp']) = @(ws,pitch) interp2(lut_ws,lut_pitch,lut_value,ws,pitch);
                    end
                
                % Greedy control: Optimized control settings are determined
                % based on the windspeed
                case {'greedy'}
                    % Determine Cp and Ct interpolation functions as a function of WS
                    lut = load([obj.dataPath '/cpctgreedy.mat']);
                    obj.cpInterp = @(ws) interp1(lut.wind_speed,lut.cp,ws);
                    obj.ctInterp = @(ws) interp1(lut.wind_speed,lut.ct,ws);
                    
                % Directly adjust the axial induction value of each turbine.
                case {'axialInduction'}
                    obj.cpInterp = @(ai) 4*ai*(1-ai);
                    obj.ctInterp = @(ai) 4*ai*(1-ai)^2;
                    
                otherwise
                    error('Control methodology with name: "%s" not defined', controlMethod);
            end
        end
        
        function turbineResults = cPcTpower(obj, condition, controlStruct)
            %CP returns cp value
            %   Computes the power coefficient for this turbine depending
            %   on the condition at the rotor area and the controlset of
            %   the turbine
            turbineResults.cp = obj.cpInterp(condition, controlStruct);
            turbineResults.ct = obj.ctInterp(condition, controlStruct);
        end
    end
end
