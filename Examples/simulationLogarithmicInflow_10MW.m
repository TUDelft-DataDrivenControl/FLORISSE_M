%
% SIMULATIONLOGARITHMICINFLOW.M
% Summary: This script demonstrates how to perform an (open-loop)
% simulation with the FLORIS model under uniform ambient inflow conditions.
%

% Instantiate a layout without ambientInflow conditions
layout = clwindcon_9_turb;

% Use the height from the first turbine type as reference height for the inflow profile
refheight = layout.uniqueTurbineTypes(1).hubHeight;

% Define an inflow struct and use it in the layout, clwindcon9Turb
layout.ambientInflow = ambient_inflow_uniform('windSpeed', 6, ...
                                              'windDirection', 0, ...
                                              'TI0', .1);
                                          
% Make a controlObject for this layout
controlSet = control_set(layout, 'yawAndRelPowerSetpoint');

% Define subModels
subModels = model_definition('deflectionModel',      'rans',...
                             'velocityDeficitModel', 'selfSimilar',...
                             'wakeCombinationModel', 'quadraticRotorVelocity',...
                             'addedTurbulenceModel', 'crespoHernandez');
                         
% Initialize the FLORIS object and run the simulation                         
florisRunner = floris(layout, controlSet, subModels);
florisRunner.run
display([florisRunner.turbineResults.power])

% Visualize the results
visTool = visualizer(florisRunner);
visTool.plot2dIF()

% Note that other options for visualization are:
%   visTool.plot_layout() % Plot the layout
%   visTool.plot2dWF()    % Plot the 2D top-view in the wind-aligned frame
%   visTool.plot2dIF()    % Plot the 2D top-view in the inertial frame
%   visTool.plot3dWF()    % Plot the 3D flowfield in the wind-aligned frame
%   visTool.plot3dIF()    % Plot the 3D flowfield in the inertial frame
