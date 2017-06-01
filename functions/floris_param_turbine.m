function [ turb_type ] = floris_param_turbine( name )
switch lower(name)
    case 'nrel5mw'
        turb_type.rotorDiameter           = 126.4;
        turb_type.rotorArea               = pi*(turb_type.rotorDiameter/2)^2;
        turb_type.generator_efficiency    = 0.944;
        turb_type.hub_height              = 90.0;
        
        % Determine Cp and Ct interpolation functions as functions of velocity
        load('NREL5MWCPCT.mat'); % converted from .p file
        
        
%         turb_type.Ct_interp = fit(NREL5MWCPCT.wind_speed',  NREL5MWCPCT.CT', 'linearinterp');
%         turb_type.Cp_interp = fit(NREL5MWCPCT.wind_speed',  NREL5MWCPCT.CP', 'linearinterp');
        
        % Dirty way to prevent very negative windspeed when the windspeeds
        % before a turbine become negative
        % TODO: Fix negative windspeeds properly
        turb_type.Ct_interp = fit([-5 NREL5MWCPCT.wind_speed].',[.6 NREL5MWCPCT.CT].','linearinterp');
        turb_type.Cp_interp = fit([-5 NREL5MWCPCT.wind_speed].',[0 NREL5MWCPCT.CP].','linearinterp');
    otherwise
        error(['Turbine parameters with name "' name '" not defined']);
end;
end