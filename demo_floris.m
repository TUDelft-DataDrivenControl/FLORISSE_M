clear all; clc; close all;

%% Run a single simulation without optimization
disp('Running a single simulation...');
FLORIS_sim = floris('9turb','NREL5MW','uniform','pitch','PorteAgel',...
                    'Katic','PorteAgel');  % Initialize FLORIS class with specific settings
FLORIS_sim.run();            % Run a single simulation with the settings 'FLORIS.inputData'
FLORIS_sim.visualize(0,1,1); % Generate a 2D visualization and a 3D visualization
disp(' '); disp(' ');

%% Optimize the turbine yaw angles
disp('Performing yaw optimization ...');
FLORIS_optYaw = floris();  % Initialize FLORIS class with default configuration
FLORIS_optYaw.inputData.yawAngles = zeros(1,9); % Set all turbines in baseline case to greedy
FLORIS_optAx.inputData.bladePitch = zeros(1,9); % Set all turbines in baseline case to greedy 
FLORIS_optYaw.optimize(true,false);             % Optimization for yaw angles: same as .optimizeYaw()
FLORIS_optYaw.visualize(0,1,0);                 % Generate a 2D visualization only
disp(' '); disp(' ');

%% Optimize the turbine blade pitch angles
disp('Performing blade pitch optimization ...');
FLORIS_optAx = floris();  % Initialize FLORIS class with default configuration
FLORIS_optAx.inputData.yawAngles  = zeros(1,9); % Set all turbines in baseline case to greedy
FLORIS_optAx.inputData.bladePitch = zeros(1,9); % Set all turbines in baseline case to greedy 
FLORIS_optAx.optimize(false,true);              % Optimization for axial ind: same as FLORIS.optimizeAxInd()
FLORIS_optAx.visualize(0,1,0);                  % Generate a 2D visualization only
disp(' '); disp(' ');

%% Optimize both yaw angles and blade pitch angles
disp('Performing combined (yaw & blade pitch) optimization ...');
FLORIS_opt = floris();  % Initialize FLORIS class with default configuration
FLORIS_opt.inputData.yawAngles = zeros(1,9);  % Set all turbines in baseline case to greedy
FLORIS_opt.inputData.bladePitch = zeros(1,9); % Set all turbines in baseline case to greedy 
FLORIS_opt.optimize(true,true);               % Optimization for yaw angles and axial induction
FLORIS_opt.visualize(0,1,0);                  % Generate a 2D visualization only