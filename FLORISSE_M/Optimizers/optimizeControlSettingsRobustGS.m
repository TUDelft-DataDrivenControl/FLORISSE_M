function [xopt, P_bl, P_opt] = optimizeControlSettingsRobustGS(florisRunner, ~, yawOpt, ~, pitchOpt, ~, axialOpt, WD_std, WD_N, optVerbose)
%OPTIMIZECONTROLSETTINGS Turbine control optimization algorithm
%
%   This function is an example case of how to optimize the yaw and/or
%   blade pitch angles/axial induction factors of the turbines inside the
%   wind farm using the FLORIS model. This function includes uncertainty in
%   the incoming wind direction by assuming a Gaussian probability
%   distribution, and optimizing a single yaw angle (or other control
%   setting) for the range of WDs.
%
%   Additional variables:
%    WD_std   -- standard deviation in wind direction (rad)
%    WD_N     -- number of bins to discretize over ( recommended: >=5 )
%

if nargin <= 9 % Add silence/verbose option
    optVerbose = true;
end

[xopt, P_bl, P_opt] = mainfunc_controloptimization(...
    florisRunner, '', yawOpt, '', pitchOpt, '', axialOpt, WD_std, WD_N, ...
    optVerbose, 'gridsearch');
end
