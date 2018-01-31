function [ centerLine ] = floris_wakeCenterLinePosition( wakeModel,turbine,x )
% Calculate wake locations at downstream turbines
deltaxs           = x-turbine.LocWF(1);
[displ_y,displ_z] = wakeModel.deflection(deltaxs,turbine);

% Write the results to the wake struct
centerLine      = zeros(3,length(x));
centerLine(1,:) = x;
centerLine(2,:) = displ_y;
centerLine(3,:) = displ_z;
end