function [inputData] = floris_loadSettings(siteType,turbType,atmoType,controlType,wakeType,deflType)

inputData.airDensity = 1.1716; % Atmospheric air density (kg/m3)
inputData.deflType = deflType;
inputData.wakeType = wakeType;
inputData.atmoType = atmoType;

%% Site and topology settings
switch siteType
    case '9turb'
        % Wind turbine locations in inertial frame 
        inputData.LocIF = [300,    100.0;
                           300,    300.0;
                           300,    500.0;
                           1000,   100.0;
                           1000,   300.0;
                           1000,   500.0;
                           1600,   100.0;
                           1600,   300.0;
                           1600,   500.0];
        nTurbs          = size(inputData.LocIF,1);
        inputData.nTurbs                = nTurbs;
        
        % Control settings
%         inputData.yawAngles   = zeros(1,nTurbs);     % Set default as greedy
        inputData.yawAngles   = deg2rad([-30 10 -10 -30 -20 -15 0 10 0]);
%         inputData.tiltAngles  = zeros(1,nTurbs);     % Set default as greedy
        inputData.tiltAngles  = deg2rad([30 0 0 0 0 0 0 0 0]);
   
        % Atmospheric settings
        inputData.uInfIf   = 12;       % x-direction flow speed inertial frame (m/s)
        inputData.vInfIf   = 4;        % y-direction flow speed inertial frame (m/s)
    case '1turb'
        % Wind turbine locations in inertial frame 
        inputData.LocIF = [0 0];
        nTurbs          = size(inputData.LocIF,1);
        inputData.nTurbs                = nTurbs;
        
        inputData.yawAngles   = deg2rad([ 25 ]);
        inputData.tiltAngles  = deg2rad([ 0 ]);
   
        % Atmospheric settings
        inputData.uInfIf   = 12;       % x-direction flow speed inertial frame (m/s)
        inputData.vInfIf   = 4;        % y-direction flow speed inertial frame (m/s)
    otherwise
        error(['Site type with name "' siteType '" not defined']);
end

% Compute windDirection and magnitude
inputData.windDirection = atand(inputData.vInfIf/inputData.uInfIf); % Wind dir in degrees (inertial frame)
inputData.uInfWf        = hypot(inputData.uInfIf,inputData.vInfIf); % axial flow speed in wind frame

%% Turbine characteristics
switch lower(turbType)
    case 'nrel5mw'
        inputData.rotorRadius           = (126.4/2) * ones(1,nTurbs);
        inputData.generator_efficiency  = 0.944     * ones(1,nTurbs);
        inputData.hub_height            = 90.0      * ones(1,nTurbs);
        
        inputData.LocIF(:,3)            = inputData.hub_height;
        inputData.rotorArea             = pi*inputData.rotorRadius.^2;
    otherwise
        error(['Turbine type with name "' turbType '" not defined']);
end

%% Atmosphere type
switch inputData.atmoType
    case 'boundary'
        inputData.shear       = .12;      % shear exponent (0.14 -> neutral)
        % initialize the flow field used in the 3D model based on shear using the power log law
        inputData.Ufun = @(z) inputData.uInfWf.*(z./inputData.hub_height(1)).^inputData.shear;
    case 'uniform'
        inputData.Ufun = @(z) inputData.uInfWf;
    otherwise
        error(['Atmosphere type with name "' atmoType '" not defined']);
end

%% Deflection type
switch inputData.deflType
    case 'Jimenez'
        % correction recovery coefficients with yaw
        inputData.KdY               = 0.17; % Wake deflection recovery factor
        
        % define initial wake displacement and angle (not determined by yaw angle)
        inputData.useWakeAngle      = true;
        inputData.kd                = deg2rad(1.5);  % initialWakeAngle in X-Y plane
        inputData.ad                = -4.5; % initialWakeDisplacement
        inputData.bd                = -0.01;
        
    case 'PorteAgel'
        inputData = IPD_PorteAgel(inputData);
    otherwise
        error(['Deflection type with name "' deflType '" not defined']);
end

%% Velocity model type
% Adjust the intial swept surface overlap
inputData.adjustInitialWakeDiamToYaw = false;
% turbulence intensity [-] ex: 0.1 is 10% turbulence intensity
inputData.TI_0        = .2;

switch inputData.wakeType
    case 'Zones'
        inputData.useaUbU       = true;
        inputData.aU            = 12.0; % units: degrees
        inputData.bU            = 1.3;
        
        inputData.Ke            = 0.05; % wake expansion parameters
        inputData.KeCorrCT      = 0.0; % CT-correction factor
        inputData.baselineCT    = 4.0*(1.0/3.0)*(1.0-(1.0/3.0)); % Baseline CT for ke-correction
        inputData.me            = [-0.5, 0.22, 1.0]; % relative expansion of wake zones
        inputData.MU            = [0.5, 1.0, 5.5]; % relative recovery of wake zones
        
    case 'Gauss'
        inputData.Ke            = 0.05; % wake expansion parameters
        inputData.KeCorrCT      = 0.0; % CT-correction factor
        inputData.baselineCT    = 4.0*(1.0/3.0)*(1.0-(1.0/3.0)); % Baseline CT for ke-correction
        
    case 'Larsen'
        inputData.IaLars        = .06; % ambient turbulence
        
    case 'PorteAgel'
        inputData = IPD_PorteAgel(inputData);
    otherwise
        error(['Wake type with name: "' inputData.wakeType '" not defined']);
end

%% Turbine model type
inputData.pP                = 1.88; % yaw power correction parameter
switch controlType
    case {'pitch'}
        % Choice of how a turbine's axial control setting is determined
        % 0: use pitch angles and Cp-Ct LUTs for pitch and WS, 
        % 1: greedy control   and Cp-Ct LUT for WS,
        % 2: specify axial induction directly.
        inputData.axialControlMethod = 0;  
        inputData.pitchAngles = zeros(1,nTurbs);
        inputData.axialInd    = nan*ones(1,nTurbs);
        
        % Determine Cp and Ct interpolation functions as a function of WS and blade pitch
        for airfoilDataType = {'cp','ct'}
            lut        = csvread([airfoilDataType{1} 'Pitch.csv']);
            lut_ws     = lut(1,2:end);          % Wind speed in LUT in m/s
            lut_pitch  = deg2rad(lut(2:end,1)); % Blade pitch angle in LUT in radians
            lut_value  = lut(2:end,2:end);      % Values of Cp/Ct [dimensionless]
            inputData.([airfoilDataType{1} '_interp'])  = @(ws,pitch) interp2(lut_ws,lut_pitch,lut_value,ws,pitch);
        end
        
        
    case {'greedy'}
        inputData.axialControlMethod = 1;
        inputData.pitchAngles = nan*ones(1,nTurbs);
        inputData.axialInd    = nan*ones(1,nTurbs);
        
        % Determine Cp and Ct interpolation functions as a function of WS
        lut                      = load('NREL5MWCPCT.mat');
        inputData.cp_interp      = @(ws) interp1(lut.NREL5MWCPCT.wind_speed,lut.NREL5MWCPCT.CP,ws);
        inputData.ct_interp      = @(ws) interp1(lut.NREL5MWCPCT.wind_speed,lut.NREL5MWCPCT.CT,ws);
     
    
    case {'axialInduction'}  %% original tuning parameters
        inputData.axialControlMethod = 2;
        inputData.pitchAngles = nan*ones(1,nTurbs);
        inputData.axialInd    = 1/3*ones(1,nTurbs);  % Only relevant if inputData.axialControlMethod == 2
      
    otherwise
        error(['Model type with name: "' controlType '" not defined']);
end
end

function inputData = IPD_PorteAgel(inputData)
    inputData.alpha       = 2.32;     % near wake parameter
    inputData.beta        = .154;     % near wake parameter
    inputData.veer        = 0;        % veer of atmosphere
    inputData.ad          = -4.5;     % lateral wake displacement bias parameter (a + bx)
    inputData.bd          = -.01;     % lateral wake displacement bias parameter (a + bx)

    inputData.TIthresholdMult = 30;   % threshold distance of turbines to include in \"added turbulence\"
    inputData.TIa         = .73;      % magnitude of turbulence added
    inputData.TIb         = .8325;    % contribution of turbine operation
    inputData.TIc         = .0325;    % contribution of ambient turbulence intensity
    inputData.TId         = -.32;     % contribution of downstream distance from turbine

    inputData.ka			= .3837;    % wake expansion parameter (ka*TI + kb)
    inputData.kb 			= .0037;     % wake expansion parameter (ka*TI + kb)
    inputData.ky            = @(I) inputData.ka*I + inputData.kb;
    inputData.kz            = @(I) inputData.ka*I + inputData.kb;
end