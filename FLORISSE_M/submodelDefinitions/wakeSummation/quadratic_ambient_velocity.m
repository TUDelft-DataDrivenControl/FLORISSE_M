function [out] = quadratic_ambient_velocity(U_inf,U_uw,Vni)
%QUADRATIC_AMBIENT_VELOCITY Function that defines how wakes are added
%   Square the relative volumetric flowrate deficit and multiply the
%   freestream with that value to compute the velocity deficit
out = (U_inf.*(1-Vni)).^2;
end
