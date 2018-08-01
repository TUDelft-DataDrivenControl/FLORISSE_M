function layout_obj = clwindcon_3_turb()
%CLWINDCON_3_TURB Summary of this class goes here
%   Detailed explanation goes here

DTU10mwTurbType = dtu10mw;
D = 2*DTU10mwTurbType.rotorRadius;
locIf = {[0.5,    10.0];
         [0.5,    5.0];
         [0,      0.0]};
locIf = cellfun(@(loc) D*loc, locIf, 'UniformOutput', false);

% Put all the turbines in a struct array
turbines = struct('turbineType', DTU10mwTurbType , ...
                  'locIf',       locIf);

layout_obj = layout_class(turbines, 'clwindcon_3_turb');
end


