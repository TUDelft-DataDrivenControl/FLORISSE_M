%
% CONTROLOPTIMIZATIONSIMPLE.M
% Summary: This script demonstrates how one could optimize turbine control
% settings offline or in real time for the FLORIS model using a known
% ambient condition (wind speed, direction, TI). In this example case,
% first the yaw angles are optimized under greedy torque control, and
% secondly the yaw angles are optimized in combination with the turbine
% axial induction factors.
%

% Instantiate a layout without ambientInflow conditions
layout = generic_9_turb;

% Use the height from the first turbine type as reference height for theinflow profile
refheight = layout.uniqueTurbineTypes(1).hubHeight;

% Define an inflow struct and use it in the layout, clwindcon9Turb
layout.ambientInflow = ambient_inflow_log('PowerLawRefSpeed', 8, ...
    'PowerLawRefHeight', refheight, ...
    'windDirection', 0, ...
    'TI0', .05);

% Make a controlObject for this layout
controlSet = control_set(layout, 'axialInduction');

% Define subModels
subModels = model_definition('deflectionModel',      'rans',...
    'velocityDeficitModel', 'selfSimilar',...
    'wakeCombinationModel', 'quadraticRotorVelocity',...
    'addedTurbulenceModel', 'crespoHernandez');

% Run the baseline case
florisRunner = floris(layout, controlSet, subModels);
florisRunner.run
% display([florisRunner.turbineResults.power])

% Optimize the control variables; using nonlinear optimization techniques
optimizeControlSettingsSimpleFMINCON(florisRunner, 'Yaw Optimizer', 1, ...
    'Pitch Optimizer', 0, 'Axial induction Optimizer', 1, [1:6]) % Only turbines 1-6
% optimizeControlSettingsSimpleFMINCON(florisRunner, 'Yaw Optimizer', 1, ...
%     'Pitch Optimizer', 0, 'Axial induction Optimizer', 1) % Optimize all turbines; 1-9

% Visualize the outputs
visTool = visualizer(florisRunner);
visTool.plot2dWF()
