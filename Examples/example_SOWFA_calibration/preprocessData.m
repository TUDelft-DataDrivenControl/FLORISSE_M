clear all; close all; clc;

% Show time-averaged slices
plotFigures = false;
xCutOff     = [-Inf Inf];  % [-Inf Inf]
yCutOff     = [1000 2000]; % [-Inf Inf]
zCutOff     = [0 200];     % [-Inf Inf]

% Sampling for downstream slices
[vertSlice_Y,vertSlice_Z] = meshgrid(1350:50:1650,50:50:200);

sourceFolders = {'./rawData/yaw-20';'./rawData/yaw+0';...
                 './rawData/yaw+10';'./rawData/yaw+30'};
outputFiles   = {'yaw-20.mat'; 'yaw+0'; 'yaw+10'; 'yaw+30'};

for i = 1:length(sourceFolders)
    preprocessSowfaData(sourceFolders{i},outputFiles{i},...
        xCutOff,yCutOff,zCutOff,vertSlice_Y,vertSlice_Z, ...
        plotFigures);
end