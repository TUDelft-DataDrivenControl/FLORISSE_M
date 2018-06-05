% function [outputArg1] = instantiateClasses()
%instantiateClasses This function instantiates a few classes
%   Try to generate c-code from this function to see if the current code is
%   compatible with the matlab coder, use: > codegen instantiateClasses

% Instantiate a layout without ambientInflow conditions
layout = tester_9_turb_powers;
refHeigth = layout.uniqueTurbineTypes(1).hubHeight;
layout.ambientInflow = ambient_inflow_log('PowerLawRefSpeed', 12, ...
                                          'PowerLawRefHeight', refHeigth, ...
                                          'windDirection', 0.30, ...
                                          'TI0', .1);

controlSet = control_set(layout, 'pitch');
% controlSet.tiltAngles = deg2rad([0 10 0 0 -10 0 10 0 0]);
% controlSet.yawAngles = deg2rad([-30 10 -10 -30 -20 -15 0 10 0]);
controlSet.tiltAngles = deg2rad([0 0 0 0 0 0 0 0 0]);
controlSet.yawAngles = deg2rad([-30 10 -10 -30 -20 -15 0 10 0]);

% Define subModels
subModels = model_definition('deflectionModel',      'jimenez',...
                             'velocityDeficitModel', 'selfSimilar',...
                             'wakeCombinationModel', 'quadraticAmbientVelocity',...
                             'addedTurbulenceModel', 'crespoHernandez');

florisRunner = floris(layout, controlSet, subModels);
tic
florisRunner.run
toc
% display([florisRunner.turbineResults.power])
% display([florisRunner.turbineConditions.avgWS])
% display([florisRunner.turbineConditions.TI])
% display([florisRunner.turbineResults.axialInduction])
% display([florisRunner.turbineResults.ct])
visTool = visualizer(florisRunner);
