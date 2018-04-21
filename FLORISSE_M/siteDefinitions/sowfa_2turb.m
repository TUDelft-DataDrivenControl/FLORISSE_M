% Wind turbine locations in inertial frame [x, y]
inputData.LocIF = [1226.3, 1342.0;
                   1773.7, 1658.0];
nTurbs = size(inputData.LocIF,1); % Number of turbines
inputData.nTurbs = nTurbs;        % Save to inputData for usage outside of this function

% Control settings
inputData.yawAngles   = zeros(1,nTurbs); % Set default as greedy
inputData.tiltAngles  = zeros(1,nTurbs); % Set default as greedy

% Atmospheric settings
% Compute windDirection in the inertial frame, and the wind-aligned flow speed (uInfWf)
inputData.windDirection = 0.5236; % Wind dir in radians (inertial frame)
inputData.uInfWf        = 8.0;    % Axial flow speed in wind frame
inputData.TI_0          = .1;     % turbulence intensity [-] ex: 0.1 is 10% turbulence intensity
inputData.airDensity    = 1.1716; % Atmospheric air density (kg/m3)

% Inflow (vertical profile)
inputData.shear = .12; % shear exponent (0.14 -> neutral)
hubHeight = 90.0;
inputData.Ufun = @(z) inputData.uInfWf.*(z./hubHeight).^inputData.shear; % Boundary layer