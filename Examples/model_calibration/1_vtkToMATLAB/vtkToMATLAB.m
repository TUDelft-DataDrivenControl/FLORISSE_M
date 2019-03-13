clear all; close all; clc;
addpath('../bin')

plotFigures = 'all'; % options: 'none', 'hor' (horizontal slice), 'all'
ss.xCutOff = [-Inf Inf]; % [-Inf Inf]
ss.yCutOff = [-Inf Inf]; %[1000 2000];
ss.zCutOff = [0 200];    % [-Inf Inf]

% Sample inflow profile
ss.inflowCurve.export = 1;
ss.inflowCurve.vtkFileformat = '*U_Plane_0.vtk'; % Generic template for inflowCurve file (can also be exact name)

% Flow sampling for downstream slices
ss.vertSlices.sampleFlow = true;
ss.vertSlices.vtkFileformat = '*U_Plane_*.vtk';
[ss.vertSlices.Y,ss.vertSlices.Z] = meshgrid(1000:25:2000,5:25:150);

% % Virtual turbine sampling [REQUIRES ATTENTION]
% sampleStruct.sampleVirtualTurbine = false;
% sampleStruct.virtTurb.yRange = 1200:50:1800;
% sampleStruct.virtTurb.HH = 119.0; % hub height
% sampleStruct.virtTurb.Drotor = 178.3;
% sampleStruct.virtTurb.sqrtNrPoints = 100; % Number of points in one direction used to generate 2D grid

% Initialize empty cell arrays
sourceFolders = {};
outputFiles = {};

% Create sourceFolder and outputFile database
for yaw1 = [240]
    for yaw2 = [230:10:270]
        sourceFolders{end+1} = ['X:\averagedVTKs\yaw' num2str(yaw1) 'yaw' num2str(yaw2) '\*.vtk']; % Make sure to append with '*.vtk' or similar
        outputFiles{end+1}   = ['yaw' num2str(yaw1) 'yaw' num2str(yaw2) '.mat']; % Make sure to append with '.mat' or similar
    end
end


parfor i = 1:length(sourceFolders)
    preprocessData_core(sourceFolders{i},outputFiles{i}, ss, plotFigures);
end