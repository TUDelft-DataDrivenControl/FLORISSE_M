% Wind turbine locations in inertial frame [x, y]
inputData.LocIF = 178.3*[0.5,    10.0;
                         0.5,    5.0;
                         0,      0.0];
nTurbs = size(inputData.LocIF,1); % Number of turbines
inputData.nTurbs = nTurbs; % Save to inputData for usage outside of this function

% Control settings
%         inputData.yawAngles   = zeros(1,nTurbs);     % Set default as greedy
%         inputData.tiltAngles  = zeros(1,nTurbs);     % Set default as greedy
inputData.yawAngles   = zeros(1,nTurbs); % Turbine yaw angles (radians, w.r.t. freestream wind)
inputData.tiltAngles  = zeros(1,nTurbs); % Turbine tilt angles (radians, w.r.t. ground)

% Atmospheric settings
% Compute windDirection in the inertial frame, and the wind-aligned flow speed (uInfWf)
inputData.windDirection = deg2rad(270.); % Wind dir in radians (inertial frame)
inputData.uInfWf        = 8.0; % axial flow speed in wind frame
inputData.TI_0          = .1; % turbulence intensity [-] ex: 0.1 is 10% turbulence intensity
inputData.airDensity    = 1.1716; % Atmospheric air density (kg/m3)

% Inflow (vertical profile)
inputData.shear = .14; % shear exponent (0.14 -> neutral)
hubHeight = 119.0;
inputData.Ufun = @(z) inputData.uInfWf.*(z./hubHeight).^inputData.shear; % Boundary layer