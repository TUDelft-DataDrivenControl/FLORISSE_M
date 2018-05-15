% function [outputArg1] = instantiateClasses()
%instantiateClasses This function instantiates a few classes
%   Try to generate c-code from this function to see if the current code is
%   compatible with the matlab coder, use: > codegen instantiateClasses

% Instantiate a layout without ambientInflow conditions
% clwindcon9Turb = clwindcon_9_turb;
clwindcon9Turb = generic_6_turb;

% Use the heigth us the first turbine type as reference heigth for theinflow profile
refHeigth = clwindcon9Turb.uniqueTurbineTypes(1).hubHeight;
% Define an inflow struct and use it in the layout, clwindcon9Turb
clwindcon9Turb.ambientInflow = ambient_inflow('PowerLawRefSpeed', 8, ...
                                              'PowerLawRefHeight', refHeigth, ...
                                              'windDirection', pi/2, ...
                                              'TI0', .01);

% Make a controlObject for this layout
% controlSet = control_set(clwindcon9Turb, 'axialInduction');
controlSet = control_set(clwindcon9Turb, 'pitch');
controlSet.yawAngles(6) = deg2rad(10);
controlSet.tiltAngles(6) = deg2rad(10);

% Define subModels
subModels = model_definition('deflectionModel', 'jimenez',...
                             'velocityDeficitModel', 'Jensen',...
                             'wakeCombinationModel', 'quadratic',...
                             'addedTurbulenceModel', 'crespoHernandez');
florisRunner = floris(clwindcon9Turb, controlSet, subModels);

florisRunner.run

% end
