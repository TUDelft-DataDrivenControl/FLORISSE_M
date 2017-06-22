function [inputData] = floris_loadSettings(modelType,turbType,siteType)
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
               
        % Atmospheric settings
        inputData.uInfIf   = 12;       % x-direction flow speed inertial frame (m/s)
        inputData.vInfIf   = 4;        % y-direction flow speed inertial frame (m/s)
        inputData.airDensity = 1.1716; % Atmospheric air density (kg/m3)      
    otherwise
        error(['Site type with name "' siteType '" not defined']);
end;
       
%% Turbine settings
switch lower(turbType)
    case 'nrel5mw'
        nTurbs                          = size(inputData.LocIF,1);
        inputData.rotorDiameter         = 126.4 * ones(1,nTurbs);
        inputData.generator_efficiency  = 0.944 * ones(1,nTurbs);
        inputData.hub_height            = 90.0  * ones(1,nTurbs);
        
        % Control settings
        inputData.yawAngles = deg2rad([-27 10 -30 -30 -20 -15 0 10 0]);
        inputData.axialInd  = 1/3 * ones(1,nTurbs);
        
        % Determine Cp and Ct interpolation functions as functions of velocity
        load('NREL5MWCPCT.mat'); % converted from .p file        
    otherwise
        error(['Turbine type with name "' turbType '" not defined']);
end;
       
%% FLORIS model settings        
switch lower(modelType)
    case 'default'  %% original tuning parameters
        inputData.pP                = 1.88; % yaw power correction parameter
        inputData.Ke                = 0.05; % wake expansion parameters
        % inputData.KeCorrArray     = 0.0; % array-correction factor: NOT YET IMPLEMENTED!
        inputData.KeCorrCT          = 0.0; % CT-correction factor
        inputData.baselineCT        = 4.0*(1.0/3.0)*(1.0-(1.0/3.0)); % Baseline CT for ke-correction
        inputData.me                = [0.5, -0.78, 1.0]; % relative expansion of wake zones
        inputData.KdY               = 0.17; % Wake deflection recovery factor
        
        % define initial wake displacement and angle (not determined by yaw angle)
        inputData.useWakeAngle      = true;
        inputData.kd                = deg2rad(1.5);  % initialWakeAngle in X-Y plane
        inputData.ad                = -4.5; % initialWakeDisplacement
        inputData.bd                = -0.01;
        
        % correction recovery coefficients with yaw
        inputData.useaUbU           = true;
        inputData.aU                = 12.0; % units: degrees
        inputData.bU                = 1.3;
        
        inputData.MU               = [0.5, 1.0, 5.5];
        inputData.axialIndProvided = true;
        
        % adjust initial wake diameter to yaw
        inputData.adjustInitialWakeDiamToYaw = false;
    otherwise
        error(['Model type with name: "' modelType '" not defined']);
end;


%% Post-processing
for i = 1:nTurbs
    inputData.rotorArea(i) = pi*inputData.rotorDiameter(i)*inputData.rotorDiameter(i)/4.0;
end; 

% Dirty way to prevent negative ws problems. TODO: Fix negative windspeeds properly
inputData.Ct_interp = fit([-5 NREL5MWCPCT.wind_speed].',[.6 NREL5MWCPCT.CT].','linearinterp');
inputData.Cp_interp = fit([-5 NREL5MWCPCT.wind_speed].',[0 NREL5MWCPCT.CP].','linearinterp');