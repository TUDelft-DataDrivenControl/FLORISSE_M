function layout_obj = wind_tunnel_3_turb()
%scaled_2_turb Summary of this class goes here
%   Detailed explanation goes here

MWT12TurbType = mwt12();

% Wind turbine location in inertial frame [x, y], multiplied with D
locIf = {[0,  0];
         [.5, 0];
         [1,  0]};

% Put all the turbines in a struct array with their type and
% location specified
turbines = struct('turbineType', MWT12TurbType, ...
                      'locIf',         locIf);
layout_obj = layout_class(turbines, 'wind_tunnel_3_turb');
end

