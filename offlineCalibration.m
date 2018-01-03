clear all; close all; clc;
addpath(genpath('functions'))

%% Script options

% Measurement (LES data) settings
LES.VTKpath = ['K:\dcsc\DataDriven\Data\SOWFA\' ... % Path to VTK files for horizontal flow fields at hub height (SOWFA)
                  'sampleForPODexcitationPRBSpositiveNoPrecursor\horizontal_slices\*.vtk'];
LES.SCOpath = ['K:\dcsc\DataDriven\Data\SOWFA\' ... % Path to SuperCONOUT.csv file for turbine data (SOWFA)     
                  'sampleForPODexcitationPRBSpositiveNoPrecursor\superCONOUT.csv'];
              
% FLORIS settings
FLORIS = floris();

% Estimator settings
N_step = 300; % Perform estimation every [x] discrete timesteps
N_tavg = 10;  % Time-averaging horizon for LES data
N_init = 200; % Time of first estimation (cond.: N_init > N_tavg)
N_end  = 1500; % Stop after discrete time [x]

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
    clear cellData
    
    % Set correct input settings in FLORIS
end