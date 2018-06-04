classdef crespo_hernandez < added_ti_interface
    %CRESPO_HERNANDEZ Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TIa
        TIb
        TIc
        TId
        TI0Test
        axialInd
        rotorRadius
        TIthresholdMult
    end
    
    methods
        function obj = crespo_hernandez(modelData, turbine, turbineCondition, turbineControl, turbineResult)
            %CRESPO_HERNANDEZ Construct an instance of this class
            %   Detailed explanation goes here

            obj.TIa = modelData.TIa;
            obj.TIb = modelData.TIb;
            obj.TIc = modelData.TIc;
            obj.TId = modelData.TId;
%             obj.TI0Test = turbineCondition.TI;
            obj.axialInd = turbineResult.axialInduction;
            obj.rotorRadius = turbine.turbineType.rotorRadius;
            obj.TIthresholdMult = modelData.TIthresholdMult;
        end
        
        function TI_out = added_TI(obj, x, TI0)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
%             TI0 = obj.TI0Test;
            if (x < obj.rotorRadius*obj.TIthresholdMult)
                % Determine effects of turbulence intensity
                TI_out = obj.TIa*(obj.axialInd^obj.TIb)*...
                    (TI0^obj.TIc)*((x/(2*obj.rotorRadius))^obj.TId);
            else
                TI_out = 0;
            end
        end
    end
end

