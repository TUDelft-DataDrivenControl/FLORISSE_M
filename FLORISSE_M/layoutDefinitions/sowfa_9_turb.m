function layout_obj = sowfa_9_turb()
%SOWFA_9_TURB Summary of this class goes here
%   Detailed explanation goes here

NREL5MWTurbType = nrel5mw();
locIf = {[868.0  1120.8];
         [868.0  1500.0];
         [868.0  1879.2];
         [1500.0 1120.8];
         [1500.0 1500.0];
         [1500.0 1879.2];
         [2132.0 1120.8];
         [2132.0 1500.0];
         [2132.0 1879.2]};

% Put all the turbines in a struct array
turbines = struct('turbineType', NREL5MWTurbType , ...
                      'locIf',         locIf);
layout_obj = layout_class(turbines, 'sowfa_9_turb');
end

