function [modelData] = jimenez_params(modelData)
%JIMENEZPARAMS Summary of this function goes here
%   Detailed explanation goes here

% Parameters specific for the Jimenez model
modelData.KdY = 0.17; % Wake deflection recovery factor
modelData.useWakeAngle = true; % define initial wake displacement and angle (not determined by yaw angle)
modelData.kd = deg2rad(1.5);   % initialWakeAngle in X-Y plane

end

