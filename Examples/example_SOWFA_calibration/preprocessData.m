clear all; close all; clc;
addpath('bin')

% Show time-averaged slices
plotFigures = 'none'; % options: 'none', 'hor' (horizontal slice), 'all'
sampleStruct.xCutOff = [-Inf Inf]; % [-Inf Inf]
sampleStruct.yCutOff = [-Inf Inf]; %[1000 2000];
sampleStruct.zCutOff = [0 500];    % [-Inf Inf]

% Flow sampling for downstream slices
sampleStruct.sampleFlow = true;
[sampleStruct.vertSlice_Y,sampleStruct.vertSlice_Z] = meshgrid(1000:25:2000,5:25:350);

% Virtual turbine sampling
sampleStruct.sampleVirtualTurbine = false;
sampleStruct.virtTurb.yRange = 1200:50:1800;
sampleStruct.virtTurb.HH = 119.0; % hub height
sampleStruct.virtTurb.Drotor = 178.3;
sampleStruct.virtTurb.sqrtNrPoints = 100; % Number of points in one direction used to generate 2D grid


% Initialize empty cell arrays
sourceFolders = {};
outputFiles = {};

% Uniform inflow simulation (neutral ABL, 0% TI)
for yaw = [-30:10:30];
    % Post-processing folders, shell command:
    %  for i in {230..310..10}; do for j in {400..1000..5}; do mv piso_yaw$i/postProcessing/sliceDataInstantaneous/$j piso_yaw$i/postProcessing/sliceDataAvg/.; done; done
    sourceFolders{end+1} = ['/home/bmdoekemeijer/OpenFOAM/bmdoekemeijer-2.4.0/simulationCases/WE2019/runs/piso_1turb_yaw' num2str(270-yaw) '/postProcessing/sliceDataAvg'];
    outputFiles{end+1}   = ['./processedData/10MW_piso_1turb_yaw' num2str(yaw) '.mat'];
end
for yaw = [-30:10:30];
    % Post-processing folders, shell command:
    %  for i in {240..300..10}; do mkdir wps_yaw$i/postProcessing/sliceDataAvg; for j in {20400..21000..5}; do mv wps_yaw$i/postProcessing/sliceDataInstantaneous/$j wps_yaw$i/postProcessing/sliceDataAvg/.; done; done
    sourceFolders{end+1} = ['/home/bmdoekemeijer/OpenFOAM/bmdoekemeijer-2.4.0/simulationCases/WE2019/runs/wps_1turb_lowTI_yaw' num2str(270-yaw) '/postProcessing/sliceDataAvg'];
    outputFiles{end+1}   = ['./processedData/10MW_wps_1turb_lowTI_yaw' num2str(yaw) '.mat'];
end

% for i = 1:length(sourceFolders)
parfor i = 1:length(sourceFolders)
    preprocessSowfaData(sourceFolders{i},outputFiles{i},...
        sampleStruct, plotFigures);
end