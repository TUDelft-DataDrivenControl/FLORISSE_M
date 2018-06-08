function layout_obj = clwindcon_9_turb()
%CLWINDCON_9_TURB Summary of this class goes here
%   Detailed explanation goes here

DTU10mwTurbType = dtu10mw;
D = 2*DTU10mwTurbType.rotorRadius;
locIf = {[19,    10.0];
         [14,    10.0];
         [9,     10.0];
         [19,    5.0];
         [14,    5.0];
         [9,     5.0];
         [19,    0.0];
         [14,    0.0];
         [9,     0.0]};
locIf = cellfun(@(loc) D*loc, locIf, 'UniformOutput', false);

% Put all the turbines in a struct array
turbines = struct('turbineType', DTU10mwTurbType , ...
                  'locIf',       locIf);

layout_obj = layout_class(turbines, 'clwindcon_9_turb');
end


