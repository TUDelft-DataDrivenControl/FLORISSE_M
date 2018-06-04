function [out] = quadratic_ambient_velocity(U_inf,U_uw,Vni)
%QUADRATIC_AMBIENT_VELOCITY Summary of this function goes here
%   Detailed explanation goes here
out = (U_inf.*(1-Vni)).^2;
end
