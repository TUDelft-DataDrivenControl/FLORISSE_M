% function [outputArg1] = instantiateClasses()
%instantiateClasses This function instantiates a few classes
%   Try to generate c-code from this function to see if the current code is
%   compatible with the matlab coder, use: > codegen instantiateClasses

% Instantiate a layout without ambientInflow conditions
layout = generic_4_turb;

% Use the heigth from the first turbine type as reference heigth for theinflow profile
refHeigth = layout.uniqueTurbineTypes(1).hubHeight;

% Define an inflow struct and use it in the layout, clwindcon9Turb
layout.ambientInflow = ambient_inflow_log('PowerLawRefSpeed', 8, ...
                                          'PowerLawRefHeight', refHeigth, ...
                                          'windDirection', 13*pi/8, ...
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
tic
florisRunner.run
toc
display([florisRunner.turbineResults.power])
tic
optimizeControl(florisRunner)
toc

visTool = visualizer(florisRunner);
visTool.plot2dWF()
visTool.plot2dIF()
visTool.plot3dWF()
visTool.plot3dIF()

tic; visTool.plot2dWF(); toc;

% tic
% florisRunner.run
% toc
% tic
% florisRunner.run
% toc
% outputArg1 = florisRunner.layout.locWf;
% end
