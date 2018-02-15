% Wind turbine locations in inertial frame [x, y]
inputData.LocIF_D = [0 0; 4 .5];% Wind turbine location in inertial frame [x, y]
inputData.LocIF = inputData.LocIF_D*1.1;

nTurbs = size(inputData.LocIF,1); % Number of turbines
inputData.nTurbs = nTurbs; % Save to inputData for usage outside of this function

% Control settings
inputData.yawAngles   = zeros(1,nTurbs);     % Set default as greedy
inputData.tiltAngles  = zeros(1,nTurbs);     % Set default as greedy

% Atmospheric settings
% Compute windDirection in the inertial frame, and the wind-aligned flow speed (uInfWf)
inputData.windDirection = deg2rad(0); % Wind dir in radians (inertial frame)
inputData.uInfWf        = 5.7; % axial flow speed in wind frame
inputData.TI_0          = .1; % turbulence intensity [-] ex: 0.1 is 10% turbulence intensity
inputData.airDensity    = 1.1716; % Atmospheric air density (kg/m3)

% Inflow (vertical profile)
inputData.Ufun = @(z) inputData.uInfWf; % Uniform inflow