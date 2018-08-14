function [xopt] = fitFLORIS(parpoolSize)

tic;
if nargin < 1
    parpoolSize = [];
end

addpath(genpath('../../FLORISSE_M'));
addpath('bin');

fileNames = {'processedData/yaw-20.mat'; 'processedData/yaw+0.mat'; ...
             'processedData/yaw+10.mat'; 'processedData/yaw+30.mat' };

% Load measurements
disp('Setting up measurements and FLORIS objects.');
for i = 1:length(fileNames)
    loadedData = load(fileNames{i});
    timeAvgData{i} = loadedData.timeAvgData;
    inflowCurve{i} = loadedData.inflowCurve;
    measurementSet{i} = loadedData.measurementSet;
    measurementSet{i}.estimParams = {'alpha','beta','ka','kb'};
end

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
%     showFit(timeAvgData{i},florisObjSet{i})
end



% Estimate parameters
disp('Using genetic algorithms to minimize the error between LES and FLORIS.');
estTool = estimator(florisObjSet,measurementSet);

if isempty(gcp('nocreate'))
    parpool(parpoolSize)
end

% x0   = [2.32, 0.154, 0.3837, 0.0037];
% xopt = estTool.gaEstimation(x0)  % Use GA for constrained optimization
xopt = estTool.gaEstimation(); % Use GA for unconstrained optimization
% xopt = [2.3428    0.2754    0.1918    0.0022];
toc

% Generate a FLORIS object set with optimal x-settings
for i = 1:length(florisObjSet)
    florisObjSetOpt{i} = copy(florisObjSet{i});
    for ji = 1:length(estTool.estimParamsAll)
        % Update parameter iff is tuned for measurement set [i]
        if ismember(estTool.estimParamsAll{ji},measurementSet{i}.estimParams)
            florisObjSetOpt{i}.model.modelData.(estTool.estimParamsAll{ji}) = xopt(ji);
        end
    end
end

% Compare initial fit (x0) and optimal fit (xopt)
for i = 1:length(fileNames)
    showFit(timeAvgData{i},florisObjSet{i},florisObjSetOpt{i})
end


end