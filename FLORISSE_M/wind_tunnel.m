%instantiateClasses This function instantiates a few classes
%   Try to generate c-code from this function to see if the current code is
%   compatible with the matlab coder, use: > codegen instantiateClasses

% Instantiate a layout without ambientInflow conditions
layout = wind_tunnel_3_turb;

% Define an inflow struct and use it in the layout, wind_tunnel_3_turb
layout.ambientInflow = ambient_inflow_uniform('windSpeed', 4, ...
                                              'windDirection', pi/2, ...
                                              'TI0', .01);

% Make a controlObject for this layout
controlSet = control_set(layout, 'tipSpeedRatio');

% Define subModels
subModels = model_definition('deflectionModel', 'rans',...
                             'velocityDeficitModel', 'selfSimilar',...
                             'wakeCombinationModel', 'quadratic',...
                             'addedTurbulenceModel', 'crespoHernandez');
florisRunner = floris(layout, controlSet, subModels);
layout.ambientInflow.windDirection = pi/2 + deg2rad(5)
tic
florisRunner.run
toc
display([florisRunner.turbineResults.power])
optimizeControl(florisRunner)
windDirections = -13:.5:13;
yawOpts = zeros(length(windDirections), 3);
for i = 1:length(windDirections)
    layout.ambientInflow.windDirection = pi/2 + deg2rad(windDirections(i));
    if i ==28
        florisRunner.controlSet.yawAngles = deg2rad([30 20 0]);
    end
    yawOpts(i,:) = optimizeControl(florisRunner);
end