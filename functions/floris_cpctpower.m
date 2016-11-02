function [ Ct, Cp, axialInduction_out, power ] = floris_cpctpower(model,rho,turb,windspeed,yawAngle_wf,axialInduction_in )
% Calculate/import axial induction factor
if model.axialIndProvided
    axialInduction_out = axialInduction_in;
else
    error('Currently unsupported. Should be an easy fix, but need to generate Ct values somewhere.');
%     if Ct > 0.96 % Glauert condition
%         axialInd = 0.143+sqrt(0.0203-0.6427*(0.889-Ct));
%     else
%         axialInd = 0.5*(1-sqrt(1-Ct));
%     end;
end;

% Calculate Cp and Ct from a
Cp = 4*axialInduction_out*(1-axialInduction_out)^2;
Ct = 4*axialInduction_out*(1-axialInduction_out);

% Correct Cp and Ct
if model.CTcorrected == false
    Ct = Ct * cosd(yawAngle_wf)^2; % Partially Eq. 8
end;
if model.CPcorrected == false
    Cp = Cp * cosd(yawAngle_wf)^model.pP;
end;

power = (0.5*rho*turb.rotorArea*Cp)*(windspeed^3.0)*turb.generator_efficiency; 
end