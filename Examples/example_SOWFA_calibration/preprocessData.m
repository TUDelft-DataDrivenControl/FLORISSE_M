clear all; close all; clc;
addpath('bin')

% Show time-averaged slices
plotFigures = 'all'; % options: 'none', 'hor' (horizontal slice), 'all'
xCutOff     = [-Inf Inf];  % [-Inf Inf]
yCutOff     = [-Inf Inf];  %[1000 2000];
zCutOff     = [0 250];     % [-Inf Inf]

% Sampling for downstream slices
[vertSlice_Y,vertSlice_Z] = meshgrid(1000:25:2000,50:25:175);

% Initialize empty cell arrays
sourceFolders = {};
outputFiles = {};

% Uniform inflow simulation (neutral ABL, 0% TI)
for yaw = [-30:10:30];
    sourceFolders{end+1} = ['/home/bmdoekemeijer/OpenFOAM/bmdoekemeijer-2.4.0/simulationCases/ACC2019/1turb_calibration/1turb_uniPrec_runs/yaw' num2str(270-yaw) '/postProcessing/sliceDataAvg'];
    outputFiles{end+1}   = ['./processedData/uniformInflow/yaw' num2str(yaw) '.mat'];
end
for pitch = [1:4];
    sourceFolders{end+1} = ['/home/bmdoekemeijer/OpenFOAM/bmdoekemeijer-2.4.0/simulationCases/ACC2019/1turb_calibration/1turb_uniPrec_runs/pitch' num2str(pitch) '/postProcessing/sliceDataAvg'];
    outputFiles{end+1}   = ['./processedData/uniformInflow/pitch' num2str(pitch) '.mat'];
end

% Simulation with turbulent inflow, neutral ABL, 6% TI
for yaw = [-30:10:30];
    sourceFolders{end+1} = ['/home/bmdoekemeijer/OpenFOAM/bmdoekemeijer-2.4.0/simulationCases/ACC2019/1turb_calibration/1turb_neutralPrec_runs/yaw' num2str(270-yaw) '/postProcessing/sliceDataAvg'];
    outputFiles{end+1}   = ['./processedData/turbInflow/yaw' num2str(yaw) '.mat'];
end

for pitch = [1:4];
    sourceFolders{end+1} = ['/home/bmdoekemeijer/OpenFOAM/bmdoekemeijer-2.4.0/simulationCases/ACC2019/1turb_calibration/1turb_neutralPrec_runs/pitch' num2str(pitch) '/postProcessing/sliceDataAvg'];
    outputFiles{end+1}   = ['./processedData/turbInflow/pitch' num2str(pitch) '.mat'];
end

parfor i = 1:length(sourceFolders)
    preprocessSowfaData(sourceFolders{i},outputFiles{i},...
        xCutOff,yCutOff,zCutOff,vertSlice_Y,vertSlice_Z, ...
        plotFigures);
end