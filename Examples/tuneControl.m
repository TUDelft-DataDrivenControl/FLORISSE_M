% Instantiate a layout without ambientInflow conditions
layout = generic_9_turb;
% layout = generic_1_turb;
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
florisRunner = floris(layout, controlSet, subModels);
% florisRunner.layout.ambientInflow.windDirection = pi/2;
florisRunner.run
display([florisRunner.turbineResults.power])

optimizeControl(florisRunner, 'Yaw Optimizer', 1, ...
                              'Pitch Optimizer', 0, ...
                              'Axial induction Optimizer', 0)
optimizeControl(florisRunner, 'Yaw Optimizer', 1, ...
                              'Pitch Optimizer', 0, ...
                              'Axial induction Optimizer', 1)

visTool = visualizer(florisRunner);
visTool.plot2dWF()
