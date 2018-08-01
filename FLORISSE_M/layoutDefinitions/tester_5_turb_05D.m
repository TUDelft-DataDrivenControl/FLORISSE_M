function layout_obj = tester_5_turb_05D()
%TESTER_5_TURB_05D Summary of this class goes here
%   Detailed explanation goes here

NREL5MWTurbType = nrel5mw();
D = 2*NREL5MWTurbType.rotorRadius;

locIf = {[0,     0];
         [.5*D,  0];
         [1*D,   0];
         [1.5*D, 0];
         [2*D,   0]};

% Put all the turbines in a struct array
turbines = struct('turbineType', NREL5MWTurbType , ...
                      'locIf',         locIf);
layout_obj = layout_class(turbines, 'tester_5_turb_05D');
end

