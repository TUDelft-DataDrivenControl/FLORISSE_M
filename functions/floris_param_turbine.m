function [ turb ] = floris_turbine( name )
switch lower(name)
    case 'nrel5mw'
        turb.rotorDiameter           = 126.4;
        turb.rotorArea               = pi*turb.rotorDiameter(1)*turb.rotorDiameter(1)/4.0;
        turb.generator_efficiency    = 0.944;
        turb.hub_height              = 90.0;
        
        % Determine Cp and Ct interpolation functions as functions of velocity
%         load('NREL5MWCPCT.mat'); % converted from .p file
%         Ct_interpl = fit(NREL5MWCPCT.wind_speed',  NREL5MWCPCT.CT', 'linearinterp');
%         Cp_interpl = fit(NREL5MWCPCT.wind_speed',  NREL5MWCPCT.CP', 'linearinterp');
    otherwise
        error(['Turbine parameters with name "' turb.name '" not defined']);
end;
end