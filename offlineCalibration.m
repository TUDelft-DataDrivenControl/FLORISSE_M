clear all; close all; clc;
addpath(genpath('functions'))

%% Script options

% Measurement (LES data) settings
LES.VTKpath = ['K:\dcsc\DataDriven\Data\SOWFA\' ... % Path to VTK files for horizontal flow fields at hub height (SOWFA)
                  'sampleForPODexcitationPRBSpositiveNoPrecursor\horizontal_slices\*.vtk'];
LES.SCOpath = ['K:\dcsc\DataDriven\Data\SOWFA\' ... % Path to SuperCONOUT.csv file for turbine data (SOWFA)     
                  'sampleForPODexcitationPRBSpositiveNoPrecursor\superCONOUT.csv'];
              
% FLORIS settings
FLORIS = floris('2turb_LES','NREL5MW','boundary','pitch','PorteAgel','Katic','PorteAgel');
paramSet = {'TI_0'}; % Parameters to be estimated in real-time
x0 = [0.05]; % Initial guess for the tuning parameters
lb = [0.00]; % Lower bound for the tuning parameters
ub = [0.25]; % Upper bound for the tuning parameters

% Estimator settings
N_step = 300; % Perform estimation every [x] discrete timesteps
N_tavg = 10;  % Time-averaging horizon for LES data
N_init = 200; % Time of first estimation (cond.: N_init > N_tavg)
N_end  = 1500; % Stop after discrete time [x]

% Other settings
plotFlowFields = true;

%% Core code
% Import and sort LES data numerically
VTK_fileDir = dir(LES.VTKpath);
for iV = 1:length(VTK_fileDir)
    VTK_files{iV} = [VTK_fileDir(iV).folder filesep VTK_fileDir(iV).name];
end
VTK_files = natsortfiles(VTK_files);
[~,cellCenters,cellData] = importVTK(VTK_files{1});
WD = mean(atan(cellData(:,2)./cellData(:,1))); % Wind direction
clear VTK_fileDir iV cellData

% Load SuperCONOUT file
SCO = importSuperCONOUT(LES.SCOpath);
NT  = length(SCO.data);
for iT = 1:NT
    rawData.U(:,iT)     = SCO.data{iT}(:,1); % Wind speed at hub (m/s)
    rawData.power(:,iT) = SCO.data{iT}(:,2); % Generator power (W)
    rawData.omega(:,iT) = SCO.data{iT}(:,3); % Rotor rot. speed (rad/s)
    rawData.pitch(:,iT) = SCO.data{iT}(:,6); % Col. blade pitch angle (rad)
    rawData.yaw(:,iT)   = SCO.data{iT}(:,21)*pi/180; % Turbine yaw angle (rad)
end

% Create interpolants with single input: time vector (in sec.)
fNames = fieldnames(rawData);
for iF = 1:length(fNames)
    rawData.(fNames{iF})  = griddedInterpolant({SCO.time,1:NT},rawData.(fNames{iF}),'nearest');
    turbData.(fNames{iF}) = @(t) rawData.(fNames{iF})({t,[1:NT]}); % Replace by single-input interpolant
end
clear SCO rawData iF iT

%% Perform the (offline) simulation of SOWFA and the estimator
if plotFlowFields
    hFig = figure();
    tri  = delaunay(cellCenters(:,1),cellCenters(:,2));
end
for k = N_init:N_step:N_end
    kAvg_window = (k-N_tavg+1):k ;
    
    % Load and time-average the turbine control variables
    FLORIS.inputData.yawAngles   = WD-mean(turbData.yaw(kAvg_window));
    FLORIS.inputData.pitchAngles = mean(turbData.pitch(kAvg_window));
    
    % Load and time-average LES data
    flowFieldAverage = zeros(size(cellCenters));
    for iV = kAvg_window
        [~,~,cellData]   = importVTK(VTK_files{iV});
        flowFieldAverage = flowFieldAverage + cellData/N_tavg;
    end
    flowSpeedAverage = sqrt(flowFieldAverage(:,1).^2+flowFieldAverage(:,2).^2);
    clear cellData calibrationData
    
    % Define the measurements  
    clear calibrationData
    powerAverage = mean(turbData.power(kAvg_window));
    calibrationData(1).inputData = FLORIS.inputData;
    for iT = 1:NT
        calibrationData(1).power(iT) = struct('turbId',iT,... % Turbine nr. corresponding to measurement
        'value',powerAverage(iT),...  % Measured value (LES/experimental) in W
        'weight',1);                  % Weight in cost function                               
    end
    
    % Plot flow fields
    if plotFlowFields
        set(0,'CurrentFigure',hFig); clf
        subplot(1,2,1);
        trisurf(tri, cellCenters(:,1), cellCenters(:,2), flowSpeedAverage); % Raw SOWFA data
        lighting none; shading flat; colorbar; axis equal;
        light('Position',[-50 -15 29]); view(0,90); hold on;
        plot3(FLORIS.inputData.LocIF(:,1),FLORIS.inputData.LocIF(:,2),...
        FLORIS.inputData.LocIF(:,3),'k.','markerSize',10);
        ylabel('x-direction (m)'); xlabel('y-direction (m)');
        title('RAW $u$ [m/s]','interpreter','latex');
        
        drawnow;
    end
    
    % Perform estimation
    FLORIS.calibrate(paramSet,x0,lb,ub,calibrationData);
end