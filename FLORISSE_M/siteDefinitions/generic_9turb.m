% Wind turbine locations in inertial frame [x, y]
inputData.LocIF = [300,    100.0;
    300,    300.0;
    300,    500.0;
    1000,   100.0;
    1000,   300.0;
    1000,   500.0;
    1600,   100.0;
    1600,   300.0;
    1600,   500.0];
nTurbs = size(inputData.LocIF,1); % Number of turbines
inputData.nTurbs = nTurbs; % Save to inputData for usage outside of this function

% Control settings
%         inputData.yawAngles   = zeros(1,nTurbs);     % Set default as greedy
%         inputData.tiltAngles  = zeros(1,nTurbs);     % Set default as greedy

% Turbine yaw angles (radians, w.r.t. freestream wind)
inputData.yawAngles   = deg2rad([-30 10 -10 -30 -20 -15 0 10 0]);
% Turbine tilt angles (radians, w.r.t. ground)
inputData.tiltAngles  = deg2rad([0 0 0 0 0 0 0 0 0]);

% Atmospheric settings
% Compute windDirection in the inertial frame, and the wind-aligned flow speed (uInfWf)
inputData.windDirection = 0.30; % Wind dir in radians (inertial frame)
inputData.uInfWf        = 12.0; % axial flow speed in wind frame
inputData.TI_0          = .1; % turbulence intensity [-] ex: 0.1 is 10% turbulence intensity
inputData.airDensity    = 1.1716; % Atmospheric air density (kg/m3)

% Inflow (vertical profile)
inputData.Ufun = @(z) inputData.uInfWf; % Uniform inflow