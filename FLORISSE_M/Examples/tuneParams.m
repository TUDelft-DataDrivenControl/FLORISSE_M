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
controlSet = control_set(layout, 'pitch');

% Define subModels
subModels = model_definition('deflectionModel',      'rans',...
                             'velocityDeficitModel', 'selfSimilar',...
                             'wakeCombinationModel', 'quadraticRotorVelocity',...
                             'addedTurbulenceModel', 'crespoHernandez');
florisRunner = floris(layout, controlSet, subModels);
% florisRunner.layout.ambientInflow.windDirection = pi/2;
florisRunner.run
display([florisRunner.turbineResults.power])

% Load a powerset that was generated with ka = 0.4
load('powerDataka4')
% Use FLORIS to retrieve the parameter.
calibrateParameters(florisRunner, florisPower)

% Show the end result
visTool = visualizer(florisRunner);
visTool.plot2dWF()
