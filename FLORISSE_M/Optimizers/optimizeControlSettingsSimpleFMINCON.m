function [xopt,P_bl,P_opt] = optimizeControlSettingsSimpleFMINCON(...
    florisRunner, ~, yawOpt, ~, pitchOpt, ~, axialOpt, ...
    turbIdxsToOptimize,optVerbose)
%OPTIMIZECONTROLSETTINGS Turbine control optimization algorithm
%
%   This function is an example case of how to optimize the yaw and/or
%   blade pitch angles/axial induction factors of the turbines inside the
%   wind farm using the FLORIS model.
%

% In this code, WD_std = 5 [deg] is set, but it is not used in the actual
% code. For stability issues, it has to be set to a nonzero value. It does
% not affect the actual outcome.
if nargin < 8
    [xopt,P_bl,P_opt] = optimizeControlSettingsRobustFMINCON(florisRunner, ' ', ...
        yawOpt, ' ', pitchOpt, ' ', axialOpt, 5*pi/180, 1);
elseif nargin < 9
    [xopt,P_bl,P_opt] = optimizeControlSettingsRobustFMINCON(florisRunner, ' ', ...
        yawOpt, ' ', pitchOpt, ' ', axialOpt, 5*pi/180, 1, turbIdxsToOptimize);
else
    [xopt,P_bl,P_opt] = optimizeControlSettingsRobustFMINCON(florisRunner, ' ', ...
        yawOpt, ' ', pitchOpt, ' ', axialOpt, 5*pi/180, 1, turbIdxsToOptimize, optVerbose);
end
end
