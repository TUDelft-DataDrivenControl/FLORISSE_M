function [xopt] = calibrateModelWithLES(parpoolSize)
addpath(genpath('../../../FLORISSE_M'));
addpath('../bin');
tic;

% Visualization settings
plotFigures_1 = 'none'; % Plot before fitting: 'none', 'hor','all'
plotFigures_2 = 'all'; % Compare before and after fitting: 'none', 'hor','all'

% Create list with timeAvgData files
dirList = dir('../10MW_data/10MW_*.mat');
fileNames = {};
for i = 1:length(dirList)
    fileNames{end+1} = [dirList(i).folder filesep dirList(i).name];
end

% Load measurements
disp('Setting up measurements and FLORIS objects.');
for i = 1:length(fileNames)
    loadedData = load(fileNames{i});
    timeAvgData{i} = loadedData.timeAvgData;
    inflowCurve{i} = loadedData.inflowCurve;
    measurementSet{i} = loadedData.measurementSet;  
    
%     if any(strcmp(fieldnames(measurementSet{i}),'virtTurb'))
%         measurementSet{i}.virtTurb.stdev = [2 2 1 1];
%     end

    % List of to-be-estimated model parameters
    measurementSet{i}.estimParams = {'TIa','TIb','TIc','TId',...
                                     'ad','alpha','bd','beta','ka','kb'};
%     measurementSet{i}.estimParams = {'ad','alpha','bd','beta','ka','kb'};                                 
end

% Initialize FLORIS objects
subModels = model_definition(...
    'deflectionModel', 'rans',...
    'velocityDeficitModel', 'selfSimilar',...
    'wakeCombinationModel', 'quadraticRotorVelocity',...
    'addedTurbulenceModel', 'crespoHernandez');
turbines = struct('turbineType',dtu10mw(),'locIf', {[1000, 1500]});

% Setup a layout and a controlSet for each separate case
HH = 119.0;
Drot = 178.3;
for i = 1:7
    layout{i} = layout_class(turbines, 'zero TI fitting_1turb');
    layout{i}.ambientInflow = ambient_inflow_myfunc('Interpolant', inflowCurve{i},...
        'HH',HH,'windDirection', 0.0, 'TI0', 0.0); % Zero TI runs
    controlSet{i} = control_set(layout{i}, 'yawAndRelPowerSetpoint');
end
for i = 8:14
    layout{i} = layout_class(turbines, 'high TI fitting_1turb');
    layout{i}.ambientInflow = ambient_inflow_myfunc('Interpolant', inflowCurve{i},...
        'HH',HH,'windDirection', 0, 'TI0', .12); % High TI runs
    controlSet{i} = control_set(layout{i}, 'yawAndRelPowerSetpoint');
end
for i = 15:21
    layout{i} = layout_class(turbines, 'low TI fitting_1turb');
    layout{i}.ambientInflow = ambient_inflow_myfunc('Interpolant', inflowCurve{i},...
        'HH',HH,'windDirection', 0, 'TI0', .06); % Low TI runs
    controlSet{i} = control_set(layout{i}, 'yawAndRelPowerSetpoint');
end

% Set the appropriate control variables for each case
for i = [1 8 15]
    controlSet{i}.yawAngleWFArray  = deg2rad([-10.0]); i=i+1;
    controlSet{i}.yawAngleWFArray = deg2rad([-20.0]); i=i+1;
    controlSet{i}.yawAngleWFArray = deg2rad([-30.0]); i=i+1;
    controlSet{i}.yawAngleWFArray = deg2rad([0.0]); i=i+1;
    controlSet{i}.yawAngleWFArray = deg2rad([10.0]); i=i+1;
    controlSet{i}.yawAngleWFArray = deg2rad([20.0]); i=i+1;
    controlSet{i}.yawAngleWFArray = deg2rad([30.0]);
end

% Create each object and plot figures (if applicable)
for i = 1:length(fileNames)
    florisObjSet{i} = floris(layout{i}, controlSet{i}, subModels);
    if strcmp(plotFigures_1,'all')
        showFit(timeAvgData{i},florisObjSet{i});
    elseif strcmp(plotFigures_1,'hor')
        horIndx = find(~cellfun('isempty',regexp({timeAvgData{i}.name},...
            regexptranslate('wildcard','*horiz*'))));
        showFit(timeAvgData{i}(horIndx),florisObjSet{i});
    end
    florisObjSet{i}.clearOutput()
end

% Generate the estimator/calibration object
disp('Using genetic algorithms to minimize the error between LES and FLORIS.');
estTool = estimator(florisObjSet,measurementSet);

% % Create parallel object
% if isempty(gcp('nocreate'))
%     if nargin < 1
%         parpool()
%     else
%         parpool(parpoolSize)
%     end
% end

% Set initial parameters
x0 = [subModels.modelData.TIa subModels.modelData.TIb subModels.modelData.TIc ...
      subModels.modelData.TId subModels.modelData.ad   subModels.modelData.alpha ...
      subModels.modelData.bd  subModels.modelData.beta subModels.modelData.ka ...
      subModels.modelData.kb];
% x0 = [subModels.modelData.ad   subModels.modelData.alpha subModels.modelData.bd ...
%       subModels.modelData.beta subModels.modelData.ka    subModels.modelData.kb];
[J0,structJ0] = estTool.costWeightedRMSE(x0)

% if any(strcmp(fieldnames(measurementSet{i}),'virtTurb')) && strcmp(plotFigures_1,'all')
%     compareAvgWS(measurementSet,structJ0); % Plot
% end

% Optimization bounds
% lb = [-1    0.5     -0.1   0.03    0.05     -0.01];
% ub = [+1    10      +0.1   0.60    1.5      +0.02];
lb = [0.07 0.08 0.001 -5.0   -1    0.5     -0.1   0.03    0.05     -0.01];
ub = [10.0 10.0 0.50  -0.01  +1    10      +0.1   0.60    1.5      +0.02];

% Do model calibration
format long
% [xopt_con,Jopt] = estTool.gaEstimation(lb, ub)  % Use GA for constrained optimization

% ACC 2019 Doekemeijer et al.
% xopt_con = [-1.34e-3 3.16 -2.68e-3 3.28e-1 1.74e-1 9.69e-4]; 

% WE 2019 Doekemeijer et al.
xopt_con =[ 7.841152377297512   4.573750238535804   0.431969955023207 ...
           -0.246470535856333   0.001117233213458   1.087617055657293 ...
           -0.007716521497980   0.221944783863084   0.536850894208880 ...
           -0.000847912134732];

[Jopt,structJopt] = estTool.costWeightedRMSE(xopt_con)


% if any(strcmp(fieldnames(measurementSet{i}),'virtTurb'))
%     compareAvgWS(measurementSet,structJ0,structJopt); % Plot
% end

format short
toc

% Plot bounds
figure
bar(1:length(lb),(xopt_con-lb)./(ub-lb)); 
ylim([-0.1 1.1]); 
ylabel('Normalized xopt'); 
grid on

% Generate a FLORIS object set with optimal x-settings
xopt = xopt_con;
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
    if strcmp(plotFigures_2,'all')
        % Show vertical cut-throughs of all SOWFA data: detailed plots
        showFit(timeAvgData{i},florisObjSet{i},florisObjSetOpt{i});
    elseif strcmp(plotFigures_2,'hor')
        horIndx = find(~cellfun('isempty',regexp({timeAvgData{i}.name},...
            regexptranslate('wildcard','*horiz*'))));
        showFit(timeAvgData{i}(horIndx),florisObjSet{i},florisObjSetOpt{i});
    end
end

% function [] = compareAvgWS(measurementSet,structJ,structJopt)
%     if nargin <= 2
%         legendName = {'SOWFA','FLORIS'};
%     else
%         legendName = {'SOWFA','FLORIS','FLORIS OPT'};
%     end
%     for iii = 1:length(measurementSet)
%         figure('Position',[1.6634e+03 236.2000 560 868]);
%         Nx = size(structJ(iii).UAvg_est,1);
%         for ix = 1:Nx
%             subplot(Nx,1,ix)
%             plot(measurementSet{iii}.virtTurb.y(ix,:), measurementSet{iii}.virtTurb.UAvg(ix,:),'k');
%             hold on
%             plot(measurementSet{iii}.virtTurb.y(ix,:), structJ(iii).UAvg_est(ix,:),'--');
%             if nargin > 2
%                 hold on
%                 plot(measurementSet{iii}.virtTurb.y(ix,:), structJopt(iii).UAvg_est(ix,:),'--');
%             end
%             xlabel('Virtual turbine centre y-position (m)')
%             ylabel('Rotor-equiv. wind speed (m/s)')
%             ylim([0 8])
%             grid on
%         end
%         legend('True',legendName,'Location','se')
%     end
% end

end