function [xopt] = fitFLORIS(parpoolSize)

tic;

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
    layout{i}.ambientInflow = ambient_inflow_myfunc('Interpolant', inflowCurve{i},...
                                                    'HH',90,'windDirection', 0, 'TI0', .05);
    controlSet{i} = control_set(layout{i}, 'greedy');
end
controlSet{1}.yawAngleArray = deg2rad([-20.0]); % Overwrite yaw angle
controlSet{2}.yawAngleArray = deg2rad([0.0]);   % Overwrite yaw angle
controlSet{3}.yawAngleArray = deg2rad([10.0]);  % Overwrite yaw angle
controlSet{4}.yawAngleArray = deg2rad([30.0]);  % Overwrite yaw angle

for i = 1:length(fileNames)
    florisObjSet{i} = floris(layout{i}, controlSet{i}, subModels);
%     showFit(timeAvgData{i},florisObjSet{i})
end



% Estimate parameters
disp('Using genetic algorithms to minimize the error between LES and FLORIS.');
estTool = estimator(florisObjSet,measurementSet);

if isempty(gcp('nocreate'))
    if nargin < 1
        parpool()
    else
        parpool(parpoolSize)
    end
end

% x0   = [1.5 0.1 0.7 0.002]; %[2.32, 0.154, 0.3837, 0.0037];
% xopt = estTool.gaEstimation(x0)  % Use GA for constrained optimization
xopt = estTool.gaEstimation(); % Use GA for unconstrained optimization
% xopt = [-1.3008    0.9587   -1.3700    0.0755]; % unconstrained
% xopt = [2.3428    0.2754    0.1918    0.0022]; % constrained
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
tmpInterpolant = scatteredInterpolant(timeAvgData{1}(1).cellCenters(:,1),...
                                      timeAvgData{1}(1).cellCenters(:,2),...
                                      timeAvgData{1}(1).UData);
for i = 1:length(fileNames)
    % Show vertical cut-throughs of all SOWFA data: detailed plots
    showFit(timeAvgData{i},florisObjSet{i},florisObjSetOpt{i})
    
    Yq = [1000:5:2000];
    tmpInterpolant.Values = timeAvgData{i}(1).UData;
    
    figure('Position',[143.4000 218.6000 1.1592e+03 521.6000]);          
    DD_array = [3 5 7 9];
    for DDi = 1:length(DD_array) % Downstream distance in rotor diameters
        Xq = (1000 + DD_array(DDi)*126.4) * ones(size(Yq));
        subplot(1,length(DD_array),DDi)
        wakeSOWFA  = tmpInterpolant(Xq,Yq);
        wakeFLORISold = compute_probes(florisObjSet{i},Xq,Yq,90.0*ones(size(Xq)),false);
        wakeFLORISopt = compute_probes(florisObjSetOpt{i},Xq,Yq,90.0*ones(size(Xq)),false);
        
        plot(Yq,wakeSOWFA,'k-');
        hold on
        plot(Yq,wakeFLORISold,'b--');
        hold on
        plot(Yq,wakeFLORISopt,'r--');
        legend('SOWFA','FLORIS_{old}','FLORIS_{opt}','Location','se');
        grid on; ylim([3 9]);
        ylabel('Wind speed (m/s)'); xlabel('y (m)');
        title([ num2str(DD_array(DDi)) 'D, yaw = ' num2str(rad2deg(controlSet{i}.yawAngleArray)) ' deg']);
    end
end


% Compare fit using horizontal plane


end