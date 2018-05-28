function layout_obj = scaled_2_turb()
%scaled_2_turb Summary of this class goes here
%   Detailed explanation goes here

TUMG1TurbType = tum_g1;
D = 2*TUMG1TurbType.rotorRadius;

% Wind turbine location in inertial frame [x, y], multiplied with D
locIf = {[0,    .5];
         [0,    5]};
locIf = cellfun(@(loc) D*loc, locIf, 'UniformOutput', false);

% Put all the turbines in a struct array with their type and
% location specified
turbines = struct('turbineType', TUMG1TurbType, ...
                      'locIf',         locIf);
layout_obj = layout_class(turbines, 'scaled_2_turb');
end

