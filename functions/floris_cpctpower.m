function turbine = floris_cpctpower(model,rho,turb_type,turbine)
% This function computes Cp and Ct based on the axialInductionFactor or it
% computes Cp, Ct and the axialInductionFactor based on the inlet windspeed
% After this the current power of the turbine is computed.

    % Calculate Ct and Cp either by approximation or interpolation
    if model.axialIndProvided
        ai = turbine.axialInd;
        % calculate Ct and Cp by approximation using AIF
        turbine.Ct = 4*ai*(1-ai);
        turbine.Cp = 4*ai*(1-ai)^2;
    else
        wind_speed_ax = turbine.windSpeed*cosd(turbine.YawWF)^(model.pP/3.0);
        % calculate Ct and Cp from CCblade data
        turbine.Ct = turb_type.Ct_interp(wind_speed_ax);
        turbine.Cp = turb_type.Cp_interp(wind_speed_ax);
    end

    % Correct Cp and Ct if they need correcting
    if (model.CTcorrected == false); turbine.Ct = turbine.Ct * cosd(turbine.YawWF)^2; end;
    if (model.CPcorrected == false); turbine.Cp = turbine.Cp * cosd(turbine.YawWF)^model.pP; end;    

    % Calculate axial induction factor if neccesary
    if ~model.axialIndProvided
        if turbine.Ct > 0.96 % Glauert condition
            turbine.axialInd = 0.143+sqrt(0.0203-0.6427*(0.889-turbine.Ct));
        else
            turbine.axialInd = 0.5*(1-sqrt(1-turbine.Ct));
        end;
    end
    
    % Compute turbine power
    turbine.power = (0.5*rho*turb_type.rotorArea*turbine.Cp)*(turbine.windSpeed^3.0)*turb_type.generator_efficiency;
end