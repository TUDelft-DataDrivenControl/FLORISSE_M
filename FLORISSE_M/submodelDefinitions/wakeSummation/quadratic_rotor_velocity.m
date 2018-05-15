function [out] = quadratic_rotor_velocity(U_inf,U_uw,Vni)
%QUADRATIC_ROTOR_VELOCITY Summary of this function goes here
%   Detailed explanation goes here
out = (U_uw*(1-Vni)).^2;
end
