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
%                 R = turbineDw.rotorRadius;
%                 [Y,Z]=meshgrid(linspace(-R,R,50),linspace(-R,R,50)); % Generating grid points
%                 
%                 % Determine overlap ratio by counting number of
%                 % elements that coincide with both planes.
%                 overlapRatio = nnz((hypot(Y,Z)<turbineDw.rotorRadius)&...
%                     (wakeUw.boundary(deltax,Y+turbineDw.LocWF(2)-wakeUw.centerLine(2,turbLocIndex),...
%                     Z+turbineDw.LocWF(3)-wakeUw.centerLine(3,turbLocIndex))))/...
%                     nnz(hypot(Y,Z)<turbineDw.rotorRadius);

                % Determine effects of turbulence intensity
                TI_out = obj.TIa*(obj.axialInd^obj.TIb)*...
                    (TI0^obj.TIc)*((x/(2*obj.rotorRadius))^obj.TId);

%                 TI_out = overlapRatio*TI_out;
            else
                TI_out = 0;
            end
        end
    end
end

