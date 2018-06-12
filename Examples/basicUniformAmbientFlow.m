%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


% Instantiate a layout without ambientInflow conditions
layout = wind_tunnel_3_turb;

% Define an inflow struct and use it in the layout, wind_tunnel_3_turb
layout.ambientInflow = ambient_inflow_uniform('windSpeed', 5, ...
                                              'windDirection', pi/2, ...
                                              'TI0', .01);

% Make a controlObject for this layout
controlSet = control_set(layout, 'tipSpeedRatio');

% Define subModels
subModels = model_definition('deflectionModel', 'rans',...
                             'velocityDeficitModel', 'selfSimilar',...
                             'wakeCombinationModel', 'quadraticRotorVelocity',...
                             'addedTurbulenceModel', 'crespoHernandez');
florisRunner = floris(layout, controlSet, subModels);
florisRunner.run
display([florisRunner.turbineResults.power])

% visTool = visualizer(florisRunner);
% visTool.plot2dWF()
