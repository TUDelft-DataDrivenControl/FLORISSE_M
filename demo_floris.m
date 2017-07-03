clear all; close all; clc;
% Optimize yaw angles
FLORIS = floris();  % Initialize FLORIS class. Default: floris('default','NREL5MW','9turb');
FLORIS.inputData.yawAngles = zeros(1,9); % Set all yaw angles to 0 for baseline calculation
FLORIS.optimizeYaw(); % Optimization for yaw angles