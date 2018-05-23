% function [outputArg1] = instantiateClasses()
%instantiateClasses This function instantiates a few classes
%   Try to generate c-code from this function to see if the current code is
%   compatible with the matlab coder, use: > codegen instantiateClasses

% Instantiate a layout without ambientInflow conditions
% layout = clwindcon_9_turb;
layout = generic_6_turb;

% Use the heigth from the first turbine type as reference heigth for theinflow profile
refHeigth = layout.uniqueTurbineTypes(1).hubHeight;
% Define an inflow struct and use it in the layout, clwindcon9Turb
layout.ambientInflow = ambient_inflow('PowerLawRefSpeed', 8, ...
                                      'PowerLawRefHeight', refHeigth, ...
                                      'windDirection', 0, ...
                                      'TI0', .01);

% Make a controlObject for this layout
% controlSet = control_set(layout, 'axialInduction');
controlSet = control_set(layout, 'pitch');
controlSet.yawAngles(6) = deg2rad(10);
controlSet.tiltAngles(6) = deg2rad(10);

% Define subModels
subModels = model_definition('deflectionModel', 'rans',...
                             'velocityDeficitModel', 'selfSimilar',...
                             'wakeCombinationModel', 'quadratic',...
                             'addedTurbulenceModel', 'crespoHernandez');
florisRunner = floris(layout, controlSet, subModels);
% florisRunner.layout.ambientInflow.windDirection = pi/2;
tic
florisRunner.run
toc
% tic
% florisRunner.run
% toc
% tic
% florisRunner.run
% toc
% outputArg1 = florisRunner.layout.locWf;
% end
