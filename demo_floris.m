clear all; close all; clc;
%% Run a single simulation without optimization
FLORIS = floris();          % Initialize FLORIS class. Default: floris('default','NREL5MW','9turb');
FLORIS.run();               % Run a single simulation with the settings 'FLORIS.inputData'
FLORIS.visualize(1,1,0);    % Calculate and display wind farm layout and top-view plot
FLORIS.visualize(0,0,1);    % 3D visualization of the complete flow in the farm
disp('Press a key to continue...'); pause;

%% Optimize yaw angles
FLORIS = floris();  % Initialize FLORIS class. Default: floris('default','NREL5MW','9turb');
FLORIS.inputData.yawAngles = zeros(1,9);     % Set all turbines to greedy
FLORIS.inputData.axialInd  = 0.33*ones(1,9); % Set all turbines to greedy
FLORIS.optimize(true,false);                 % Optimization for yaw angles: same as .optimizeYaw()
disp('Press a key to continue...'); pause;

%% Optimize axial induction factor
FLORIS = floris();  % Initialize FLORIS class. Default: floris('default','NREL5MW','9turb');
FLORIS.inputData.yawAngles = zeros(1,9);     % Set all turbines to greedy
FLORIS.inputData.axialInd  = 0.33*ones(1,9); % Set all turbines to greedy
FLORIS.optimize(false,true);                 % Optimization for axial ind: same as .optimizeAxInd()
disp('Press a key to continue...'); pause;

%% Optimize both axial induction and yaw
FLORIS = floris();  % Initialize FLORIS class. Default: floris('default','NREL5MW','9turb');
FLORIS.inputData.yawAngles = zeros(1,9);     % Set all turbines to greedy
FLORIS.inputData.axialInd  = 0.33*ones(1,9); % Set all turbines to greedy
FLORIS.optimize(true,true);                  % Optimization for yaw angles and axial induction