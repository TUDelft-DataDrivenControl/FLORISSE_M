function layout_obj = generic_6_turb()
%GENERIC_6_TURB Summary of this class goes here
%   Detailed explanation goes here

NREL5MWTurbType = nrel5mw();
locIf = {[300,    100.0];
         [300,    500.0];
         [300,    900.0];
         [1000,   100.0];
         [1000,   500.0];
         [1000,   900.0]};

% Put all the turbines in a struct array
turbines = struct('turbineType', NREL5MWTurbType , ...
                      'locIf',         locIf);
layout_obj = layout_class(turbines, 'generic_6_turb');
end

