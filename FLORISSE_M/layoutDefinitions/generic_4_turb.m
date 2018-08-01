function layout_obj = generic_4_turb()
%GENERIC_6_TURB Summary of this class goes here
%   Detailed explanation goes here

NREL5MWTurbType = nrel5mw();
locIf = {[-250,   -200];
         [250,    -200];
         [-250,   200];
         [250,    200]};

% Put all the turbines in a struct array
turbines = struct('turbineType', NREL5MWTurbType , ...
                      'locIf',         locIf);
layout_obj = layout_class(turbines, 'generic_4_turb');
end

