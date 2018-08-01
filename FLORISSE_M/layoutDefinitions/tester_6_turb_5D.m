function layout_obj = tester_6_turb_5D()
%TESTER_6_TURB_5D Summary of this class goes here
%   Detailed explanation goes here

NREL5MWTurbType = nrel5mw();
D = 2*NREL5MWTurbType.rotorRadius;

locIf = {[300,    D];
         [300,    6*D];
         [300,    11*D];
         [1000,   D];
         [1000,   6*D];
         [1000,   11*D]};
% Put all the turbines in a struct array
turbines = struct('turbineType', NREL5MWTurbType , ...
                      'locIf',         locIf);
layout_obj = layout_class(turbines, 'tester_6_turb_5D');
end

