function layout_obj = sowfa_2_turb()
%SOWFA_2_TURB Summary of this class goes here
%   Detailed explanation goes here

NREL5MWTurbType = nrel5mw();
locIf = {[1226.3, 1342.0];
         [1773.7, 1658.0]};

% Put all the turbines in a struct array
turbines = struct('turbineType', NREL5MWTurbType , ...
                      'locIf',         locIf);
layout_obj = layout_class(turbines, 'sowfa_2_turb');
end

