clear all; close all; clc;

addpath(genpath('../../FLORISSE_M'));
fileNames = {'processedData/yaw-20.mat'; 'processedData/yaw+0.mat'; ...
             'processedData/yaw+10.mat'; 'processedData/yaw+30.mat' };

% Load measurements
for i = 1:length(fileNames)
    loadedData = load(fileNames{i});
    timeAvgData{i} = loadedData.timeAvgData;
    inflowCurve{i} = loadedData.inflowCurve;
    measurementSet{i} = loadedData.measurementSet;
    measurementSet{i}.estimParams = {'alpha','beta','ka','kb'};
end
clear loadedData

% Initialize FLORIS objects
subModels = model_definition('deflectionModel','rans',...
                             'velocityDeficitModel', 'selfSimilar',...
                             'wakeCombinationModel', 'quadraticRotorVelocity',...
                             'addedTurbulenceModel', 'crespoHernandez');

turbines = struct('turbineType', nrel5mw() , ...
                      'locIf', {[1000, 1500]});

for i = 1:length(fileNames)
    layout{i} = layout_class(turbines, 'fitting_1turb');
    layout{i}.ambientInflow = ambient_inflow_myfunc('Interpolant', inflowCurve{i},'HH',90,'windDirection', 0, 'TI0', .05);
    controlSet{i} = control_set(layout{i}, 'greedy');
end
controlSet{1}.yawAngles = deg2rad([-20.0]); % Overwrite yaw angle
controlSet{2}.yawAngles = deg2rad([0.0]);   % Overwrite yaw angle
controlSet{3}.yawAngles = deg2rad([10.0]);  % Overwrite yaw angle
controlSet{4}.yawAngles = deg2rad([30.0]);  % Overwrite yaw angle

for i = 1:length(fileNames)
    florisObjSet{i} = floris(layout{i}, controlSet{i}, subModels);
end

% Initial comparison
for i = 1:length(fileNames)
%     showFit(timeAvgData{i},copy(florisObjSet{i}))
end

% Estimate parameters
estTool = estimator(florisObjSet,measurementSet);
x0 = [2.32, 0.154, 0.3837, 0.0037];
xopt_con = estTool.gaEstimation(x0); % Use GA for constrained optimization
% xopt_uncon = estTool.gaEstimation();