function [modelData] = crespo_hernandez_params(modelData)
%ZONEDPARAMS Summary of this function goes here
%   Detailed explanation goes here

modelData.TIthresholdMult = 30; % threshold distance of turbines to include in \"added turbulence\"
modelData.TIa   = .73;      % magnitude of turbulence added
modelData.TIb   = .8325;    % contribution of turbine operation
modelData.TIc   = .0325;    % contribution of ambient turbulence intensity
modelData.TId   = -.32;     % contribution of downstream distance from turbine

end
