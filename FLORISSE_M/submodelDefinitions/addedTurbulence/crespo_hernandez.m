classdef crespo_hernandez < added_ti_interface
    %CRESPO_HERNANDEZ Added Turbuelence Intensity object,
    %   The paper :cite:`Niayifar2015` describes several turbulence
    %   intensity models. The Crespo-Hernandez one is found to be the most
    %   accurate in their situation.
    
    properties
        TIa 
        TIb
        TIc
        TId
        TI0
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
            
            % Set ambient turbulence intensity to the TI at the rotor
            obj.TI0 = turbineCondition.TI;
            obj.axialInd = turbineResult.axialInduction;
            obj.rotorRadius = turbine.turbineType.rotorRadius;
            obj.TIthresholdMult = modelData.TIthresholdMult;
        end
        
        function TI_out = added_TI(obj, x)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if (x < obj.rotorRadius*obj.TIthresholdMult)
                % Estimate effects of turbulence intensity
                TI_out = obj.TIa*(obj.axialInd^obj.TIb)*...
                    (obj.TI0^obj.TIc)*((x/(2*obj.rotorRadius))^obj.TId);
            else
                TI_out = 0;
            end
        end
    end
end

