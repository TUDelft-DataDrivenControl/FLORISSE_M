clear all; close all; clc;

% Baseline calculations
disp('Performing baseline calculations...');
FLORIS = floris();  % Initialize FLORIS class 
FLORIS.init();      % Initialize model settings. Default: FLORIS.init('default','NREL5MW','9turb');
FLORIS.run();       % Run FLORIS with default settings
FLORIS.visualize(1,1,0); % Plot FLORIS results. Options: visualize(Plot layout (T/F), plot 2D (T/F), plot 3D (T/F))
P_bl = sum(FLORIS.outputData.power);
disp(['Baseline power: ' num2str(P_bl/10^6) ' MW']);

% Optimization for yaw angles
disp('Performing optimization for yaw...');
FLORIS.optimizeYaw();
FLORIS.run()
FLORIS.visualize(0,1,0)
P_opt = sum(FLORIS.outputData.power);
disp(['Optimized power: ' num2str(P_opt/10^6) ' MW']);
disp(['Relative increase: ' num2str((P_opt/P_bl-1)*100) '%.'])