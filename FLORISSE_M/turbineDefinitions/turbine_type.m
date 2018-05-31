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
        controlMethod % The controlMethod that is being used in this turbine
        rotorRadius % Length of a single turbine blade
        rotorArea % Swept area of the rotor
        genEfficiency % Generator efficiency
        hubHeight % Heigth of the turbine nacelle
        pP % Fitting parameter to adjust CP down for a turbine angle
    end
    properties (SetAccess = immutable)
        description % Short description of the turbine
    end
    properties (Access = private)
        allowableControlMethods
        dataPath
        lutCp
        lutCt
        lutGreedy
        lutLambda
    end
    
    methods
        function obj = turbine_type(rotorRadius, genEfficiency, hubHeight, pP, path, allowableControlMethods, description)
            %TURBINE_TYPE Construct an instance of this class
            %   The turbine characters are saved as properties 
            obj.controlMethod = nan;
            obj.dataPath = path;
            obj.allowableControlMethods = allowableControlMethods;
            
            obj.rotorRadius = rotorRadius;
            obj.rotorArea = pi*rotorRadius.^2;
            obj.genEfficiency = genEfficiency;
            obj.hubHeight = hubHeight;
            obj.pP = pP;
            obj.description = description;
        end
        
        function set.controlMethod(obj, controlMethod)
            %set.controlMethod Prepare cp and ct functions
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
            
            % If the controlMethod is set to nan do not prepare any lookup tables
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
                % Load the lookup tables for cp and ct as a function of
                % windspeed and pitch
                    obj.lutCp = csvread([obj.dataPath '/cpPitch.csv']);
                    obj.lutCt = csvread([obj.dataPath '/ctPitch.csv']);
                % The lookup tables are formatted in this way:
                % Wind speed in LUT in m/s
                % lut_ws    = lut(1,2:end);
                % Blade pitch angle in LUT in radians
                % lut_pitch = deg2rad(lut(2:end,1));
                % Values of Cp/Ct [dimensionless]
                % lut_value = lut(2:end,2:end);
                case {'greedy'}
                % Load the lookup table for cp and ct as a function of windspeed
                    obj.lutGreedy = csvread([obj.dataPath '/cpctgreedy.csv']);
                case {'tipSpeedRatio'}
                % Load the lookup table for cp and ct as a function of lambda
                    obj.lutLambda = csvread([obj.dataPath '/cpctlambda.csv']);
                case {'axialInduction'}
                % No preparation needed
                otherwise
                    error('Control methodology with name: "%s" not defined', controlMethod);
            end
        end
        
        function turbineResult = cPcTpower(obj, condition, turbineControl, turbineResult)
            %cPcTpower returns a struct with the computed turbine characteristics 
            %   Computes the power coefficient for this turbine depending
            %   on the condition at the rotor area and the controlset of
            %   the turbine
            switch obj.controlMethod
                case {'pitch'}
                    turbineResult.cp = interp2(obj.lutCp(1,2:end), deg2rad(obj.lutCp(2:end,1)), obj.lutCp(2:end,2:end), ...
                                               condition.avgWS, turbineControl.pitchAngle);
                    turbineResult.ct = interp2(obj.lutCt(1,2:end), deg2rad(obj.lutCt(2:end,1)), obj.lutCt(2:end,2:end), ...
                                               condition.avgWS, turbineControl.pitchAngle);
                    turbineResult.axialInduction = obj.calc_axial_induction(turbineResult.ct);
                case {'greedy'}
                    turbineResult.cp = interp1(obj.lutGreedy(1,:), obj.lutGreedy(2,:), condition.avgWS);
                    turbineResult.ct = interp1(obj.lutGreedy(1,:), obj.lutGreedy(3,:), condition.avgWS);
                    turbineResult.axialInduction = obj.calc_axial_induction(turbineResult.ct);
                case {'tipSpeedRatio'}
                    turbineResult.cp = interp1(obj.lutLambda(1,:), obj.lutLambda(2,:), turbineControl.tipSpeedRatio);
                    turbineResult.ct = interp1(obj.lutLambda(1,:), obj.lutLambda(3,:), turbineControl.tipSpeedRatio);
                    turbineResult.axialInduction = obj.calc_axial_induction(turbineResult.ct);
                case {'axialInduction'}
                    turbineResult.axialInduction = turbineControl.axialInduction;
                    turbineResult.cp = 4*turbineControl.axialInduction*(1-turbineControl.axialInduction);
                    turbineResult.ct = 4*turbineControl.axialInduction*(1-turbineControl.axialInduction)^2;
                otherwise
                    error('Control methodology with name: "%s" not defined', obj.controlMethod);
            end
            
            % Correct Cp and Ct for rotor misallignment
            turbineResult.ct = turbineResult.ct * cos(turbineControl.thrustAngle)^2;
            turbineResult.cp = turbineResult.cp * cos(turbineControl.thrustAngle)^obj.pP;
            if isnan(turbineResult.ct) || isnan(turbineResult.cp)
                error('cPcTpower:valueError', 'CT or CP is nan. This means that the windspeed (or pitchangle) dropped below the values listed in the lookup table of this turbine. Currently FLORIS does not support the below rated region.');
            end
            turbineResult.power = (0.5*condition.rho*obj.rotorArea*turbineResult.cp)*(condition.avgWS^3.0)*obj.genEfficiency;
        end
    end
    methods (Static)
        function axialInd = calc_axial_induction(ct)
            % Calculate axial induction factor
            if ct > 0.96 % Glauert condition
                axialInd = 0.143+sqrt(0.0203-0.6427*(0.889-ct));
            else
                axialInd = 0.5*(1-sqrt(1-ct));
            end
        end
    end
end
