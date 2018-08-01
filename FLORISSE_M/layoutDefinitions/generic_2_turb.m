function layout_obj = generic_2_turb()
%GENERIC_2_TURB Summary of this class goes here
%   Detailed explanation goes here

NREL5MWTurbType = nrel5mw();
locIf = {[400,    400.0];
         [1032.1, 400.1]};

% Put all the turbines in a struct array
turbines = struct('turbineType', NREL5MWTurbType , ...
                      'locIf',         locIf);
layout_obj = layout_class(turbines, 'generic_2_turb');
end

