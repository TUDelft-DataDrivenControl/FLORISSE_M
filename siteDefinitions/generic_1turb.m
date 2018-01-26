% Wind turbine locations in inertial frame
inputData.LocIF = [0 0];% Wind turbine location in inertial frame [x, y]
nTurbs          = size(inputData.LocIF,1); % Number of turbines
inputData.nTurbs = nTurbs; % Save to inputData for usage outside of this function

inputData.yawAngles   = deg2rad([ 30 ]); % Turbine yaw angles (radians, w.r.t. freestream wind)
inputData.tiltAngles  = deg2rad([ 0 ]); % Turbine tilt angles (radians, w.r.t. ground)

% Atmospheric settings
inputData.windDirection = 0.30; % Wind dir in radians (inertial frame)
inputData.uInfWf        = 12.0; % axial flow speed in wind frame
inputData.TI_0          = .1; % turbulence intensity [-] ex: 0.1 is 10% turbulence intensity
inputData.airDensity    = 1.1716; % Atmospheric air density (kg/m3)

% Inflow
inputData.atmoType = 'uniform'; % Uniform inflow