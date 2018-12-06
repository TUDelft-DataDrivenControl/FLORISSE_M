clear all; close all; clc;
addpath('bin')

% Show time-averaged slices
plotFigures = 'all'; % options: 'none', 'hor' (horizontal slice), 'all'
sampleStruct.xCutOff     = [-Inf Inf];  % [-Inf Inf]
sampleStruct.yCutOff     = [-Inf Inf];  %[1000 2000];
sampleStruct.zCutOff     = [0 500];     % [-Inf Inf]

% Flow sampling for downstream slices
sampleStruct.sampleFlow = false;
[sampleStruct.vertSlice_Y,sampleStruct.vertSlice_Z] = meshgrid(1000:25:2000,50:25:175);

% Virtual turbine sampling
sampleStruct.sampleVirtualTurbine = true;
sampleStruct.virtTurb.yRange = 1200:50:1800;
sampleStruct.virtTurb.HH = 119.0; % hub height
sampleStruct.virtTurb.Drotor = 178.3;
sampleStruct.virtTurb.sqrtNrPoints = 100; % Number of points in one direction used to generate 2D grid
loadedData = load('D:\bmdoekemeijer\My Documents\MATLAB\FLORISSE_M\FLORISSE_M\turbineDefinitions\dtu10mw\dtu10mw_database.mat');
sampleStruct.virtTurb.powerFunc = @(u) interp1(loadedData.wind,loadedData.mean_Cp(:,1,9),u,'linear'); % Power map

% Initialize empty cell arrays
sourceFolders = {};
outputFiles = {};
sourceFolders{end+1} = 'C:\Users\bmdoekemeijer\Downloads\sliceDataAvg';
% sourceFolders{end+1} = 'W:\OpenFOAM\bmdoekemeijer-2.4.0\simulationCases\WE2019\runs\wps_yaw270\postProcessing\sliceDataAvg';
outputFiles{end+1}   = './processedData_10MW/turbInflow/tmp.mat';

% Post-processing folders, shell command:
%  for i in {230..310..10}; do for j in {400..1000..5}; do mv piso_yaw$i/postProcessing/sliceDataInstantaneous/$j piso_yaw$i/postProcessing/sliceDataAvg/.; done; done

% % Uniform inflow simulation (neutral ABL, 0% TI)
% for yaw = [-30:10:30];
%     sourceFolders{end+1} = ['/home/bmdoekemeijer/OpenFOAM/bmdoekemeijer-2.4.0/simulationCases/ACC2019/1turb_calibration/1turb_uniPrec_runs/yaw' num2str(270-yaw) '/postProcessing/sliceDataAvg'];
%     outputFiles{end+1}   = ['./processedData/uniformInflow/yaw' num2str(yaw) '.mat'];
% end
% for pitch = [1:4];
%     sourceFolders{end+1} = ['/home/bmdoekemeijer/OpenFOAM/bmdoekemeijer-2.4.0/simulationCases/ACC2019/1turb_calibration/1turb_uniPrec_runs/pitch' num2str(pitch) '/postProcessing/sliceDataAvg'];
%     outputFiles{end+1}   = ['./processedData/uniformInflow/pitch' num2str(pitch) '.mat'];
% end
% 
% % Simulation with turbulent inflow, neutral ABL, 6% TI
% for yaw = [-30:10:30];
%     sourceFolders{end+1} = ['/home/bmdoekemeijer/OpenFOAM/bmdoekemeijer-2.4.0/simulationCases/ACC2019/1turb_calibration/1turb_neutralPrec_runs/yaw' num2str(270-yaw) '/postProcessing/sliceDataAvg'];
%     outputFiles{end+1}   = ['./processedData/turbInflow/yaw' num2str(yaw) '.mat'];
% end
% 
% for pitch = [1:4];
%     sourceFolders{end+1} = ['/home/bmdoekemeijer/OpenFOAM/bmdoekemeijer-2.4.0/simulationCases/ACC2019/1turb_calibration/1turb_neutralPrec_runs/pitch' num2str(pitch) '/postProcessing/sliceDataAvg'];
%     outputFiles{end+1}   = ['./processedData/turbInflow/pitch' num2str(pitch) '.mat'];
% end

for i = 1:length(sourceFolders)
%parfor i = 1:length(sourceFolders)
    preprocessSowfaData(sourceFolders{i},outputFiles{i},...
        sampleStruct, plotFigures);
end