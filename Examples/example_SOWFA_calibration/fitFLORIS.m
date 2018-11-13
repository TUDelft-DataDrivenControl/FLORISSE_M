function [xopt] = fitFLORIS(parpoolSize)
% % USER SETTINGS
plotFigures = 'none';
fileNames = {};
dirList = [dir('processedData/uniformInflow/pitch*.mat');...
           dir('processedData/uniformInflow/yaw*.mat');...
		   dir('processedData/turbInflow/pitch*.mat');...
		   dir('processedData/turbInflow/yaw*.mat')];
for i = 1:length(dirList)
    fileNames{end+1} = [dirList(i).folder filesep dirList(i).name];
end


% Set-up
format long
addpath(genpath('../../FLORISSE_M'));
addpath('bin');
tic;

% Load measurements
disp('Setting up measurements and FLORIS objects.');
for i = 1:length(fileNames)
    loadedData = load(fileNames{i});
    timeAvgData{i} = loadedData.timeAvgData;
    inflowCurve{i} = loadedData.inflowCurve;
    measurementSet{i} = loadedData.measurementSet;
end

for i = 1:11
	measurementSet{i}.estimParams = {'ad','bd','beta','kb'};
end

for i = 12:22
	measurementSet{i}.estimParams = {'ad','bd','alpha','ka'};
end

% Initialize FLORIS objects
subModels = model_definition('deflectionModel','rans',...
                             'velocityDeficitModel', 'selfSimilar',...
                             'wakeCombinationModel', 'quadraticRotorVelocity',...
                             'addedTurbulenceModel', 'crespoHernandez');

turbines = struct('turbineType', nrel5mw() , ...
                      'locIf', {[1000, 1500]});

for i = 1:11
    layout{i} = layout_class(turbines, 'fitting_1turb');
    layout{i}.ambientInflow = ambient_inflow_uniform('windSpeed', 8., ...
                                              'windDirection', 0.0, ...
                                              'TI0', .00);    
    controlSet{i} = control_set(layout{i}, 'pitch');
end
for i = 12:22
    layout{i} = layout_class(turbines, 'fitting_1turb'); 
    layout{i}.ambientInflow = ambient_inflow_myfunc('Interpolant', inflowCurve{i},...
													'HH',90,'windDirection', 0, 'TI0', .06);
    controlSet{i} = control_set(layout{i}, 'pitch');
end

for i = [1 12]
	controlSet{i}.pitchAngleArray = deg2rad([1.0]); i=i+1;
	controlSet{i}.pitchAngleArray = deg2rad([2.0]); i=i+1;
	controlSet{i}.pitchAngleArray = deg2rad([3.0]); i=i+1;
	controlSet{i}.pitchAngleArray = deg2rad([4.0]); i=i+1;
	controlSet{i}.yawAngleWFArray  = deg2rad([-10.0]); i=i+1;
	controlSet{i}.yawAngleWFArray = deg2rad([-20.0]); i=i+1;
	controlSet{i}.yawAngleWFArray = deg2rad([-30.0]); i=i+1;
	controlSet{i}.yawAngleWFArray = deg2rad([0.0]); i=i+1;
	controlSet{i}.yawAngleWFArray = deg2rad([10.0]); i=i+1;
	controlSet{i}.yawAngleWFArray = deg2rad([20.0]); i=i+1;
	controlSet{i}.yawAngleWFArray = deg2rad([30.0]);
end

for i = 1:length(fileNames)
    florisObjSet{i} = floris(layout{i}, controlSet{i}, subModels);
    if strcmp(plotFigures,'all')
        showFit(timeAvgData{i},florisObjSet{i});
    elseif strcmp(plotFigures,'hor')
        horIndx = find(~cellfun('isempty',regexp({timeAvgData{i}.name},...
            regexptranslate('wildcard','*horiz*'))));
        showFit(timeAvgData{i}(horIndx),florisObjSet{i});
    end
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

x0 = [-4.5/126.4,  2.32, -0.01, .154, .3837, .0037];
lb = min([x0/4; x0*4]);
ub = max([x0/4; x0*4]);
ub(1) =  1.0; 
lb(1) = -1.0;
disp(lb); disp(ub)

xopt_con = estTool.gaEstimation(lb, ub)  % Use GA for constrained optimization
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
        title([ num2str(DD_array(DDi)) 'D, yaw = ' num2str(rad2deg(controlSet{i}.yawAngleWFArray)) ' deg']);
    end
end
end