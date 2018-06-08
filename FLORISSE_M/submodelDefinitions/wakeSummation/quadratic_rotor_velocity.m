function [out] = quadratic_rotor_velocity(U_inf,U_uw,Vni)
%QUADRATIC_ROTOR_VELOCITY Function that defines how wakes are added
%   Square the relative volumetric flowrate deficit and multiply the
%   average velocity of the upstream rotor with that value to compute the
%   velocity deficit
out = (U_uw*(1-Vni)).^2;
end
