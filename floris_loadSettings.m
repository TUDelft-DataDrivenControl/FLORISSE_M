function [inputData] = floris_loadSettings(siteType,turbType,atmoType,controlType,wakeType,deflType)
inputData.deflType   = deflType; % Write deflection  model choice to inputData
inputData.wakeType   = wakeType; % Write single wake model choice to inputData
inputData.atmoType   = atmoType; % Write atmospheric model choice to inputData

%% Site and topology characteristics
% This set of options define the turbine locations, freestream wind speed
% and wind direction, and the (default) turbine control settings.
switch siteType
    case '9turb'
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
        inputData.yawAngles   = deg2rad([-30 10 -10 -30 -20 -15 0 10 0]); % Turbine yaw angles (radians, w.r.t. freestream wind)
        inputData.tiltAngles  = deg2rad([0 0 0 0 0 0 0 0 0]); % Turbine tilt angles (radians, w.r.t. ground)
   
        % Atmospheric settings
        inputData.uInfIf   = 12; % x-direction flow speed inertial frame (m/s)
        inputData.vInfIf   = 4;  % y-direction flow speed inertial frame (m/s)
        inputData.airDensity = 1.1716; % Atmospheric air density (kg/m3)
    case '1turb'
        % Wind turbine locations in inertial frame 
        inputData.LocIF = [0 0];% Wind turbine location in inertial frame [x, y]
        nTurbs          = size(inputData.LocIF,1); % Number of turbines
        inputData.nTurbs = nTurbs; % Save to inputData for usage outside of this function
        
        inputData.yawAngles   = deg2rad([ 30 ]); % Turbine yaw angles (radians, w.r.t. freestream wind)
        inputData.tiltAngles  = deg2rad([ 0 ]); % Turbine tilt angles (radians, w.r.t. ground)
        
        % Atmospheric settings
        inputData.uInfIf   = 12; % x-direction flow speed inertial frame (m/s)
        inputData.vInfIf   = 4;  % y-direction flow speed inertial frame (m/s)
        inputData.airDensity = 1.1716; % Atmospheric air density (kg/m3)
    otherwise
        error(['Site type with name "' siteType '" not defined']);
end

% Compute windDirection in the inertial frame, and the wind-aligned flow speed (uInfWf)
inputData.windDirection = atan(inputData.vInfIf/inputData.uInfIf); % Wind dir in radians (inertial frame)
inputData.uInfWf        = hypot(inputData.uInfIf,inputData.vInfIf); % axial flow speed in wind frame


%% Turbine characteristics
% This set of options define the turbine properties such as rotor radius,
% generator efficiency, hub height, and rotor swept area.
switch lower(turbType)
    case 'nrel5mw'
        inputData.rotorRadius           = (126.4/2) * ones(1,nTurbs);
        inputData.generator_efficiency  = 0.944     * ones(1,nTurbs);
        inputData.hub_height            = 90.0      * ones(1,nTurbs);
        
        inputData.LocIF(:,3)            = inputData.hub_height;
        inputData.rotorArea             = pi*inputData.rotorRadius.^2;
        
        % See https://www.nrel.gov/docs/fy09osti/38060.pdf for a more
        % detailed explanation of the NREL 5MW reference wind turbine.
        
    otherwise
        error(['Turbine type with name "' turbType '" not defined']);
end


%% Atmosphere characteristics
% Herein we define whether we have a fully uniform inflow ('uniform'),
% where we neglect the ground shear layer. Alternatively, we can include
% the ground shear layer by assuming a logarithmic inflow profile in
% z-direction, using the option 'boundary'.
switch inputData.atmoType
    case 'boundary'
        inputData.shear = .12; % shear exponent (0.14 -> neutral)
        % initialize the flow field used in the 3D model based on shear using the power log law
        inputData.Ufun = @(z) inputData.uInfWf.*(z./inputData.hub_height(1)).^inputData.shear;
    case 'uniform'
        inputData.Ufun = @(z) inputData.uInfWf;
    otherwise
        error(['Atmosphere type with name "' atmoType '" not defined']);
end


%% Wake deflection model choice
% Herein we define the wake deflection model we want to use, which can be
% either from Jimenez et al. (2009) with doi:10.1002/we.380, or from 
% Bastankah and Porte-Agel (2016) with doi:10.1017/jfm.2016.595. The
% traditional FLORIS uses Jimenez, while the new FLORIS model presented
% by Annoni uses Porte-Agel's deflection model.

% Define rotor blade induced wake displacement
inputData.ad = -4.5;   % lateral wake displacement bias parameter (a + bx)
inputData.bd = -0.01;  % lateral wake displacement bias parameter (a + bx)
inputData.at = 0.0;    % vertical wake displacement bias parameter (a + bx)
inputData.bt = 0.0;    % vertical wake displacement bias parameter (a + bx)
switch inputData.deflType
    case 'Jimenez'
        % For a more detailed explanation of these parameters, see the
        % paper with doi:10.1002/we.1993 by Gebraad et al. (2016).
        % correction recovery coefficients with yaw
        inputData.KdY = 0.17; % Wake deflection recovery factor
        % define initial wake displacement and angle (not determined by yaw angle)
        inputData.useWakeAngle = true;
        inputData.kd = deg2rad(1.5);  % initialWakeAngle in X-Y plane
    case 'PorteAgel'
        inputData = IPD_PorteAgel(inputData);
        
    otherwise
        error(['Deflection type with name "' deflType '" not defined']);
end

%% Wake deficit model choice
% Herein we define how we want to model the shape of our wake (looking at
% the y-z slice). The traditional FLORIS model uses three discrete zones,
% 'Zones', but more recently a Gaussian wake profile 'Gauss' has seemed to 
% better capture the wake shape with less tuning parameters. This idea has
% further been explored by Bastankah and Porte-Agel (2016), which led to
% the 'PorteAgel' wake deficit model.
inputData.adjustInitialWakeDiamToYaw = false; % Adjust the intial swept surface overlap
inputData.TI_0 = .1; % turbulence intensity [-] ex: 0.1 is 10% turbulence intensity

switch inputData.wakeType
    case 'Zones'
        inputData.useaUbU       = true; % This flags adjusts wake velocity recovery based on yaw angle:
        % The equation used is: wake.mU = inputData.MU/cos(inputData.aU+inputData.bU*turbine.YawWF)
        inputData.aU            = deg2rad(12.0);
        inputData.bU            = 1.3;
        
        inputData.Ke            = 0.05; % wake expansion parameters
        inputData.KeCorrCT      = 0.0; % CT-correction factor
        inputData.baselineCT    = 4.0*(1.0/3.0)*(1.0-(1.0/3.0)); % Baseline CT for ke-correction
        inputData.me            = [-0.5, 0.22, 1.0]; % relative expansion of wake zones
        inputData.MU            = [0.5, 1.0, 5.5]; % relative recovery of wake zones
        
        % For a more detailed explanation of these parameters, see the
        % paper with doi:10.1002/we.1993 by Gebraad et al. (2016).        
        
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


%% Turbine axial control methodology
% Herein we define how the turbine are controlled. In the traditional
% FLORIS model, we directly control the axial induction factor of each
% turbine. However, to apply this in practise, we still need a mapping to
% the turbine generator torque and the blade pitch angles. Therefore, we
% have implemented the option to directly control and optimize the blade
% pitch angles 'pitch', under the assumption of optimal generator torque
% control. Additionally, we can also assume fully greedy control, where we
% cannot adjust the generator torque nor the blade pitch angles ('greedy').

inputData.pP = 1.88; % yaw power correction parameter
switch controlType
    case {'pitch'}
        % Choice of how a turbine's axial control setting is determined
        % 0: use pitch angles and Cp-Ct LUTs for pitch and WS, 
        % 1: greedy control   and Cp-Ct LUT for WS,
        % 2: specify axial induction directly.
        inputData.axialControlMethod = 0;  
        inputData.pitchAngles = zeros(1,nTurbs); % Blade pitch angles, by default set to greedy
        inputData.axialInd    = nan*ones(1,nTurbs); % Axial inductions  are set to NaN to find any potential errors
        
        % Determine Cp and Ct interpolation functions as a function of WS and blade pitch
        for airfoilDataType = {'cp','ct'}
            lut       = csvread([airfoilDataType{1} 'Pitch.csv']); % Load file
            lut_ws    = lut(1,2:end);          % Wind speed in LUT in m/s
            lut_pitch = deg2rad(lut(2:end,1)); % Blade pitch angle in LUT in radians
            lut_value = lut(2:end,2:end);      % Values of Cp/Ct [dimensionless]
            inputData.([airfoilDataType{1} '_interp']) = @(ws,pitch) interp2(lut_ws,lut_pitch,lut_value,ws,pitch);
        end
        
    % Greedy control: we cannot adjust gen torque nor blade pitch
    case {'greedy'} 
        inputData.axialControlMethod = 1;
        inputData.pitchAngles = nan*ones(1,nTurbs); % Blade pitch angles are set to NaN to find any potential errors
        inputData.axialInd    = nan*ones(1,nTurbs); % Axial inductions  are set to NaN to find any potential errors
        
        % Determine Cp and Ct interpolation functions as a function of WS
        lut                 = load('NREL5MWCPCT.mat');
        inputData.cp_interp = @(ws) interp1(lut.NREL5MWCPCT.wind_speed,lut.NREL5MWCPCT.CP,ws);
        inputData.ct_interp = @(ws) interp1(lut.NREL5MWCPCT.wind_speed,lut.NREL5MWCPCT.CT,ws);
     
    % Directly adjust the axial induction value of each turbine.
    case {'axialInduction'}
        inputData.axialControlMethod = 2;
        inputData.pitchAngles = nan*ones(1,nTurbs); % Blade pitch angles are set to NaN to find any potential errors
        inputData.axialInd    = 1/3*ones(1,nTurbs); % Axial induction factors, by default set to greedy
      
    otherwise
        error(['Model type with name: "' controlType '" not defined']);
end
end

% Porte-agel (2016) wake model parameters
function inputData = IPD_PorteAgel(inputData)
    inputData.alpha = 2.32;     % near wake parameter
    inputData.beta  = .154;     % near wake parameter
    inputData.veer  = 0;        % veer of atmosphere
    inputData.ad    = -4.5;     % lateral wake displacement bias parameter (a + bx)
    inputData.bd    = -.01;     % lateral wake displacement bias parameter (a + bx)

    inputData.TIthresholdMult = 30; % threshold distance of turbines to include in \"added turbulence\"
    inputData.TIa   = .73;      % magnitude of turbulence added
    inputData.TIb   = .8325;    % contribution of turbine operation
    inputData.TIc   = .0325;    % contribution of ambient turbulence intensity
    inputData.TId   = -.32;     % contribution of downstream distance from turbine

    inputData.ka	= .3837;    % wake expansion parameter (ka*TI + kb)
    inputData.kb 	= .0037;    % wake expansion parameter (ka*TI + kb)
    inputData.ky    = @(I) inputData.ka*I + inputData.kb;
    inputData.kz    = @(I) inputData.ka*I + inputData.kb;
    
    % For more information, see the publication from Bastankah and 
    % Porte-Agel (2016) with doi:10.1017/jfm.2016.595.
end
