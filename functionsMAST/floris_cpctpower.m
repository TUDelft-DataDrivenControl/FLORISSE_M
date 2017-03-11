function [ Ct, Cp, axialInd, power ] = floris_cpctpower(model,rho,turb,windspeed,yawAngle_wf,var_in )
% Calculate/import axial induction factor
if model.axialIndProvided
    axialInd = var_in; % input is axial induction factor
    Ct       = 4*axialInd*(1-axialInd);
    Cp       = 4*axialInd*(1-axialInd)^2;    
    
    % Correct Cp and Ct
    if model.CTcorrected == false
        Ct = Ct * cosd(yawAngle_wf)^2; % Partially Eq. 8
    end;
    if model.CPcorrected == false
        Cp = Cp * cosd(yawAngle_wf)^model.pP;
    end;

else
    Ct       = var_in.Ct; % input is Ct/Cp
    Cp       = var_in.Cp; % input is Ct/Cp
    
    % Correct Cp and Ct
    if model.CTcorrected == false
        Ct = Ct * cosd(yawAngle_wf)^2; % Partially Eq. 8
    end;
    if model.CPcorrected == false
        Cp = Cp * cosd(yawAngle_wf)^model.pP;
    end;    
    
    if Ct > 0.96 % Glauert condition
        axialInd = 0.143+sqrt(0.0203-0.6427*(0.889-Ct));
    else
        axialInd = 0.5*(1-sqrt(1-Ct));
    end;
end;

power = (0.5*rho*turb.rotorArea*Cp)*(windspeed^3.0)*turb.generator_efficiency; 
end