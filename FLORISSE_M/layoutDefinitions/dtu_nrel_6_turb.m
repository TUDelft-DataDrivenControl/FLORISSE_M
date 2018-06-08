function layout_obj = dtu_nrel_6_turb()
%dtu_nrel_6_turb Summary of this class goes here
%   Detailed explanation goes here

NREL5MWTurbType = nrel5mw;
DTU10mwTurbType = dtu10mw;
locIf = {[300,    100.0];
         [300,    300.0];
         [300,    500.0];
         [1000,   100.0];
         [1000,   300.0];
         [1000,   500.0]};
% Form the turbine struct array with the first turbineType on the
% first three positions and the second turbineType on the last
% positions
turbines = struct('turbineType', NREL5MWTurbType, ...
                      'locIf',         locIf);
for i = [3 4 6]
    turbines(i).turbineType = DTU10mwTurbType;
end
layout_obj = layout_class(turbines, 'dtu_nrel_6_turb');
end

