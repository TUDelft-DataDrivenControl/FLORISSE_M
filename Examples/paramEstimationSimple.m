%
% PARAMESTIMATIONSIMPLE.M
% Summary: This script demonstrates how one could estimate model parameters
% offline or in real time for the FLORIS model using power measurements. In
% this example case, the parameters 'ka' and 'kb' are estimated using power
% measurements obtained from an external source.
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
controlSet = control_set(layout, 'pitch');

% Define subModels
subModels = model_definition('deflectionModel',      'rans',...
                             'velocityDeficitModel', 'selfSimilar',...
                             'wakeCombinationModel', 'quadraticRotorVelocity',...
                             'addedTurbulenceModel', 'crespoHernandez');
                         
% Run the baseline case                         
florisRunner = floris(layout, controlSet, subModels);
florisRunner.run
display([florisRunner.turbineResults.power])

% Retrieve power measurements (Below: Placeholder, FLORIS results with ka = 0.4)
measuredPower= 1e6*[1.7054 1.7054 1.7054 0.5298 0.5298 0.5298 0.7915 0.7915 0.7918];

% Use FLORIS to estimate the parameters 'ka' and 'kb'
calibrateParametersSimple(florisRunner, measuredPower)

% Visualize the outputs 
visTool = visualizer(florisRunner);
visTool.plot2dWF()
