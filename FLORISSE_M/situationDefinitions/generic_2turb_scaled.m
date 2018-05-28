% Wind turbine locations in inertial frame [x, y]
inputData.LocIF_D = [0 0; 5 +0.5];% Wind turbine location in inertial frame [x, y], in D
% inputData.LocIF_D = [0 0; 5 0.0];% Wind turbine location in inertial frame [x, y], in D
% inputData.LocIF_D = [0 0; 5 -0.5];% Wind turbine location in inertial frame [x, y], in D
inputData.LocIF = inputData.LocIF_D*1.1;

nTurbs = size(inputData.LocIF,1); % Number of turbines
inputData.nTurbs = nTurbs; % Save to inputData for usage outside of this function

% Control settings
inputData.yawAngles   = zeros(1,nTurbs);     
inputData.yawAngles(1)= deg2rad(30);     
inputData.tiltAngles  = zeros(1,nTurbs);     % Set default as greedy

% Atmospheric settings
% Compute windDirection in the inertial frame, and the wind-aligned flow speed (uInfWf)
inputData.windDirection = deg2rad(0); % Wind dir in radians (inertial frame)
inputData.uInfWf        = 5.65; % axial flow speed in wind frame

% Onshore configuration (D3.1, 3.3 Typology of flow within the wind tunnel test chambers)
% inputData.TI_0          = 0.12;
% inputData.shear         = 0.2; 

% Offshore configuration (D3.1, 3.3 Typology of flow within the wind tunnel test chambers)
inputData.TI_0          = 0.06; 
inputData.shear         = 0.079; 

inputData.airDensity    = 1.1770; % Atmospheric air density (kg/m3)

% Inflow (vertical profile)
inputData.Ufun = @(z) inputData.uInfWf.*(z./0.83).^inputData.shear; % Boundary layer
