% SIMULATIONUNIFORMINFLOW.M
% Summary: This script demonstrates how to perform an (open-loop)
% simulation with the FLORIS model under uniform ambient inflow conditions.

clearvars

% Instantiate a layout without ambientInflow conditions
% layout = wind_tunnel_3_turb;
layout = layout_class('Test Farm');

% Define an inflow struct and use it in the layout, wind_tunnel_3_turb
layout.ambientInflow = ambient_inflow_uniform('windSpeed', 5, ...
                                              'windDirection', 0, ...
                                              'TI0', .01);

% Make a controlObject for this layout
controlSet = control_set(layout, 'greedy');

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
visTool.plot3dIF()

% Note that other options for visualization are:
%   visTool.plot_layout() % Plot the layout
%   visTool.plot2dWF()    % Plot the 2D top-view in the wind-aligned frame
%   visTool.plot2dIF()    % Plot the 2D top-view in the inertial frame
%   visTool.plot3dWF()    % Plot the 3D flowfield in the wind-aligned frame
%   visTool.plot3dIF()    % Plot the 3D flowfield in the inertial frame
