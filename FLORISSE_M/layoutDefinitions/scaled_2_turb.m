function layout_obj = scaled_2_turb(ambientFlow)
%scaled_2_turb Summary of this class goes here
%   Detailed explanation goes here

TUMG1TurbType = tum_g1;
D = 2*TUMG1TurbType.rotorRadius;

% Wind turbine location in inertial frame [x, y], multiplied with D
locIf = {D*[0,    .5];
         D*[0,    5]};

% Put all the turbines in a struct array with their type and
% location specified
turbines = struct('turbineType', TUMG1TurbType, ...
                      'locIf',         locIf);
layout_obj = layout_class(turbines, ambientFlow);
end

