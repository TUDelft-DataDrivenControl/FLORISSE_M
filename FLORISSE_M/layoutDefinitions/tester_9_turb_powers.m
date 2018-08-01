function layout_obj = tester_9_turb_powers()
%TESTER_9_TURB_POWERS Summary of this class goes here
%   Detailed explanation goes here

NREL5MWTurbType = nrel5mw();
locIf = {[300,    100.0];
         [300,    300.0];
         [300,    500.0];
         [1000,   100.0];
         [1000,   300.0];
         [1000,   500.0];
         [1600,   100.0];
         [1600,   300.0];
         [1600,   500.0]};
% Put all the turbines in a struct array
turbines = struct('turbineType', NREL5MWTurbType , ...
                      'locIf',         locIf);
layout_obj = layout_class(turbines, 'tester_9_turb_powers');
end

