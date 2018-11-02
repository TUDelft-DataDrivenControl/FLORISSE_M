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
        hubHeight % height of the turbine nacelle
        pP % Fitting parameter to adjust CP down for a turbine angle
        cpctMapObj
        allowableControlMethods
    end
    properties (SetAccess = immutable)
        description % Short description of the turbine
    end
    properties (Access = private)
        cpctMapFunc
        structLUT
    end
    
    methods
        function obj = turbine_type(rotorRadius, genEfficiency, hubHeight, pP, cpctMapFunc, allowableControlMethods, description)
            %TURBINE_TYPE Construct an instance of this class
            %   The turbine characters are saved as properties 
            obj.controlMethod = nan;
            obj.cpctMapFunc = cpctMapFunc;
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
                error('This turbine_type does not support the control method: "%s".', controlMethod)
            end
            
            % Load the function that defines the cp and ct mappings
            obj.controlMethod = controlMethod;
            obj.cpctMapObj    = obj.cpctMapFunc(controlMethod);
        end
        
        function turbineResult = cPcTpower(obj, condition, turbineControl, turbineResult)
            %cPcTpower returns a struct with the computed turbine characteristics 
            %   Computes the power coefficient for this turbine depending
            %   on the condition at the rotor area and the controlset of
            %   the turbine
   
            % The axialInduction control method is available for all
            % turbines by default. If a different control method is
            % specified, it should have been defined in the corresponding
            % cp-ct mapping object as a function, "cpctMapObj.calculateCpCt".
            if strcmp(obj.controlMethod,'axialInduction')
                turbineResult.axialInduction = turbineControl.axialInduction;
                turbineResult.ct = 4*turbineControl.axialInduction*(1-turbineControl.axialInduction);
                turbineResult.cp = 4*turbineControl.axialInduction*(1-turbineControl.axialInduction)^2;
                turbineResult = obj.adjust_cp_ct_for_yaw(turbineControl, turbineResult);
            else
                % Calculate Cp and Ct for turbine using arbitrary function/LUT
                [turbineResult.cp,turbineResult.ct,adjustCpCtYaw] = obj.cpctMapObj.calculateCpCt(condition,turbineControl);
                if adjustCpCtYaw
                    turbineResult = obj.adjust_cp_ct_for_yaw(turbineControl, turbineResult);
                end
                turbineResult.axialInduction = obj.calc_axial_induction(turbineResult.ct);
            end
            if isnan(turbineResult.ct) || isnan(turbineResult.cp)
                error('cPcTpower:valueError', 'CT or CP is nan. This means that the windspeed (or pitchangle) dropped below the values listed in the lookup table of this turbine, and no extrapolation method has been selected.');
            end
            turbineResult.power = (0.5*condition.rho*obj.rotorArea*turbineResult.cp)*(condition.avgWS^3.0)*obj.genEfficiency;
        end
        
        function turbineResult = adjust_cp_ct_for_yaw(obj, turbineControl, turbineResult)
            % Correct Cp and Ct for rotor misallignment
            turbineResult.ct = turbineResult.ct * cos(turbineControl.thrustAngle)^2;
            turbineResult.cp = turbineResult.cp * cos(turbineControl.thrustAngle)^obj.pP;
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
