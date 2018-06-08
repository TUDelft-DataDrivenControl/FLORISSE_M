% Create a florisRunner object that holds settings for the windtunnel
florisRunner = create_wind_tunnel_floris();
% Time a testrun
% tic
% florisRunner.run
% toc
% display([florisRunner.turbineResults.power])

% Create a lookup table with optimal yaw angles for different wind inflow directions
% windDirections = -13:.5:13;
% yawOpts = zeros(length(windDirections), 3);
% for i = 1:length(windDirections)
%     layout.ambientInflow.windDirection = deg2rad(windDirections(i));
%     % Force the wind turbines to have a positive yaw misalignment
%     if i ==28
%         florisRunner.controlSet.yawAngles = deg2rad([30 20 0]);
%     end
%     yawOpts(i,:) = optimizeControl(florisRunner);
% end

% Example for live optimization
florisRunner.layout.ambientInflow.windDirection = deg2rad(5);
% florisRunner.layout.ambientInflow.Vref;
florisRunner.controlSet.tipSpeedRatios = [5 3 3.5];
tic
optYaws = optimizeControl(florisRunner);
toc
rad2deg(optYaws)
% visTool = visualizer(florisRunner);