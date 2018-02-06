function [TI_out] = wakeTurbulenceModels(modelData,TI_0,turbineDw,turbineUw,wakeUw,turbLocIndex,deltax)
%% Turbine-induced added turbulence models

% Turbine-induced turbulence method
switch modelData.turbulenceModel
    case 'PorteAgel'
        % Herein we calculate the overlap area of the wake with
        % the rotor area by generating many sample points
        % (meshgrid) at a resolution of 1m x 1m, and counting
        % the number of points that lie in both the wake and
        % the rotor plane.
        if (deltax < turbineUw.rotorRadius*modelData.TIthresholdMult)
            R = round(turbineDw.rotorRadius+1);
            [Y,Z]=meshgrid(-R:R,-R:R); % Generating grid points
            
            % Determine overlap ratio by counting number of
            % elements that coincide with both planes.
            overlapRatio = nnz((hypot(Y,Z)<turbineDw.rotorRadius)&...
                (wakeUw.boundary(deltax,Y+turbineDw.LocWF(2)-wakeUw.centerLine(2,turbLocIndex),...
                Z+turbineDw.LocWF(3)-wakeUw.centerLine(3,turbLocIndex))))/...
                nnz(hypot(Y,Z)<turbineDw.rotorRadius);
            
            % Determine effects of turbulence intensity
            TI_calc = modelData.TIa*(turbineUw.axialInd^modelData.TIb)*...
                (TI_0^modelData.TIc)*((deltax/(2*turbineUw.rotorRadius))^modelData.TId);
            
            TI_out = overlapRatio*TI_calc;
        else
            TI_out = 0;
        end
        
    otherwise
        % do nothing
        TI_out = [];
end
end

