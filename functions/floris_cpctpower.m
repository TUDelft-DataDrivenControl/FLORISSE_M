function [ Ct, Cp, axialInd, power ] = floris_cpctpower(model,site,turb,windspeed,yawAngle_wf,turb_axialInduction )
% Calculate/import axial induction factor
if model.axialIndProvided
    axialInd = turb_axialInduction;
else
    if Ct > 0.96 % Glauert condition
        axialInd = 0.143+sqrt(0.0203-0.6427*(0.889-Ct));
    else
        axialInd = 0.5*(1-sqrt(1-Ct));
    end;
end;

% Calculate Cp and Ct from a
Cp = 4*axialInd*(1-axialInd)^2;
Ct = 4*axialInd*(1-axialInd);

% Correct Cp and Ct
if model.CTcorrected == false
    Ct = Ct * cosd(yawAngle_wf)^2; % Partially Eq. 8
end;
if model.CPcorrected == false
    Cp = Cp * cosd(yawAngle_wf)^model.pP;
end;

power = (0.5*site.rho*turb.rotorArea*Cp)*(windspeed^3.0)*turb.generator_efficiency; 
end