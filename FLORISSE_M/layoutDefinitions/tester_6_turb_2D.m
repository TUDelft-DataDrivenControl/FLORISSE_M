function layout_obj = tester_6_turb_2D()
%TESTER_6_TURB_2D Summary of this class goes here
%   Detailed explanation goes here

NREL5MWTurbType = nrel5mw();
D = 2*NREL5MWTurbType.rotorRadius;

locIf = {[300,    D];
         [300,    3*D];
         [300,    5*D];
         [1000,   D];
         [1000,   3*D];
         [1000,   5*D]};

% Put all the turbines in a struct array
turbines = struct('turbineType', NREL5MWTurbType , ...
                      'locIf',         locIf);
layout_obj = layout_class(turbines, 'tester_6_turb_2D');
end

