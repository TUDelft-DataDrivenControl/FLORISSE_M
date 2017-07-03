clear all; close all; clc;
% Optimize yaw angles
FLORIS = floris();  % Initialize FLORIS class. Default: floris('default','NREL5MW','9turb');
FLORIS.inputData.yawAngles = zeros(1,9);     % Set all turbines to greedy
FLORIS.inputData.axialInd  = 0.33*ones(1,9); % Set all turbines to greedy
FLORIS.optimize(true,false)                  % Optimization for yaw angles: same as .optimizeYaw()

% Optimize axial induction factor
FLORIS = floris();  % Initialize FLORIS class. Default: floris('default','NREL5MW','9turb');
FLORIS.inputData.yawAngles = zeros(1,9);     % Set all turbines to greedy
FLORIS.inputData.axialInd  = 0.33*ones(1,9); % Set all turbines to greedy
FLORIS.optimize(false,true);                 % Optimization for axial ind: same as .optimizeAxInd()

% Optimize both axial induction and yaw
FLORIS = floris();  % Initialize FLORIS class. Default: floris('default','NREL5MW','9turb');
FLORIS.inputData.yawAngles = zeros(1,9);     % Set all turbines to greedy
FLORIS.inputData.axialInd  = 0.33*ones(1,9); % Set all turbines to greedy
FLORIS.optimize(true,true);                  % Optimization for yaw angles and axial induction