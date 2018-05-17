clear all; clc; close all;
%% Run a single simulation without optimization
disp('Running a single simulation...');
FLORIS_sim = floris('generic_9turb','nrel5mw','uniform','pitch',...
                    'PorteAgel','PorteAgel','Katic',...
                    'PorteAgel','PorteAgel_default'); % Initialize FLORIS class with specific settings
FLORIS_sim.run();            % Run a single simulation with the settings 'FLORIS.inputData'
FLORIS_sim.visualize(0,1,0,'WF'); % Generate a 2D visualization and a 3D visualization in wind-aligned frame
disp(' '); disp(' ');

%% Optimize the turbine yaw angles
disp('Performing yaw optimization ...');
FLORIS_optYaw = floris();  % Initialize FLORIS class with default configuration
FLORIS_optYaw.inputData.yawAngles = zeros(1,9); % Set all turbines in baseline case to greedy
FLORIS_optYaw.inputData.bladePitch = zeros(1,9); % Set all turbines in baseline case to greedy 
FLORIS_optYaw.optimize(true,false);             % Optimization for yaw angles: same as .optimizeYaw()
FLORIS_optYaw.visualize(0,1,0,'WF');            % Generate a 2D visualization only (in inertial frame)
disp(' '); disp(' ');

%% Optimize the turbine blade pitch angles
disp('Performing blade pitch optimization ...');
FLORIS_optAx = floris();  % Initialize FLORIS class with default configuration
FLORIS_optAx.inputData.yawAngles  = zeros(1,9); % Set all turbines in baseline case to greedy
FLORIS_optAx.inputData.bladePitch = zeros(1,9); % Set all turbines in baseline case to greedy 
FLORIS_optAx.optimize(false,true);              % Optimization for axial ind: same as FLORIS.optimizeAxInd()
FLORIS_optAx.visualize(0,1,0,'IF');             % Generate a 2D visualization only (by default: inertial frame)
disp(' '); disp(' ');

%% Optimize both yaw angles and blade pitch angles
disp('Performing combined (yaw & blade pitch) optimization ...');
FLORIS_opt = floris();  % Initialize FLORIS class with default configuration
FLORIS_opt.inputData.yawAngles = zeros(1,9);  % Set all turbines in baseline case to greedy
FLORIS_opt.inputData.bladePitch = zeros(1,9); % Set all turbines in baseline case to greedy 
FLORIS_opt.optimize(true,true);               % Optimization for yaw angles and axial induction
FLORIS_opt.visualize(0,1,0,'IF');             % Generate a 2D visualization only (by default: inertial frame)

%% Optimize both yaw angles and blade pitch angles on the first three turbines
disp('Performing combined (yaw & blade pitch) optimization ...');
FLORIS_opt = floris();  % Initialize FLORIS class with default configuration
FLORIS_opt.inputData.yawAngles = zeros(1,9);  % Set all turbines in baseline case to greedy
FLORIS_opt.inputData.bladePitch = zeros(1,9); % Set all turbines in baseline case to greedy 
FLORIS_opt.optimize(true,true, [1 2 3]);       % Optimization for yaw angles and axial induction
FLORIS_opt.visualize(0,1,0,'IF');             % Generate a 2D visualization only (by default: inertial frame)