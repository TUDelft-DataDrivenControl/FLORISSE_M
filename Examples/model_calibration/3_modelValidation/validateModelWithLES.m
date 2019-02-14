clear all; close all; clc
addpath(genpath('../../../FLORISSE_M'));
addpath('../bin');
tic;

% % USER SETTINGS
plotFigures_1 = 'none'; % Plot before fitting: 'none', 'hor','all'
plotFigures_2 = 'none'; % Compare before and after fitting: 'none', 'hor','all'
dirList = dir('10MW_data/10MW_piso_3turb_*.mat');
set(groot, 'defaultAxesTickLabelInterpreter','latex');
set(groot, 'defaultLegendInterpreter','latex');

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
end

% Initialize FLORIS objects
subModels = model_definition('deflectionModel','rans',...
    'velocityDeficitModel', 'selfSimilar',...
    'wakeCombinationModel', 'quadraticRotorVelocity',...
    'addedTurbulenceModel', 'crespoHernandez');
turbines = struct('turbineType',dtu10mw_v2(),'locIf', {[608.5 544.575]; [1500, 544.575];[2391.5 455.425] });

HH = 119.0;
Drot = 178.3;
for i = 1:length(fileNames)
    layout{i} = layout_class(turbines, 'fitting_1turb');
    layout{i}.ambientInflow = ambient_inflow_myfunc('Interpolant', inflowCurve{i},...
        'HH',HH,'windDirection', 0, 'TI0', .06);
    controlSet{i} = control_set(layout{i}, 'yawAndRelPowerSetpoint');
end

controlSet{1}.yawAngleWFArray  = [20 20 0] * pi/180;
controlSet{2}.yawAngleWFArray =  [0  0  0] * pi/180;
controlSet{3}.yawAngleWFArray = -[20 20 0] * pi/180;

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

% Estimate parameters
disp('Using genetic algorithms to minimize the error between LES and FLORIS.');
for i = 1:length(florisObjSet)
    measurementSet{i} = struct();
    measurementSet{i}.estimParams = {...
        'TIa','TIb','TIc','TId',...
        'ad','alpha','bd','beta','ka','kb'};
end
estTool = estimator(florisObjSet,measurementSet);

x0 = [subModels.modelData.TIa subModels.modelData.TIb subModels.modelData.TIc ...
    subModels.modelData.TId subModels.modelData.ad   subModels.modelData.alpha ...
    subModels.modelData.bd  subModels.modelData.beta subModels.modelData.ka ...
    subModels.modelData.kb];
% x0 = [subModels.modelData.ad   subModels.modelData.alpha subModels.modelData.bd ...
%       subModels.modelData.beta subModels.modelData.ka    subModels.modelData.kb];

xopt_con =[ 7.841152377297512   4.573750238535804   0.431969955023207 ...
    -0.246470535856333   0.001117233213458   1.087617055657293 ...
    -0.007716521497980   0.221944783863084   0.536850894208880 ...
    -0.000847912134732]; % uFlow with highTI, Jopt = 10.28

[J0,structJ0]     = estTool.costWeightedRMSE(x0);
[Jopt,structJopt] = estTool.costWeightedRMSE(xopt_con);

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
    
    Yq = [0:5:1000];
    tmpInterpolant = scatteredInterpolant(timeAvgData{i}(1).cellCenters(:,1),...
        timeAvgData{i}(1).cellCenters(:,2),...
        timeAvgData{i}(1).UData);
    
    figure('Position',[143.4000 218.6000 1.1592e+03 521.6000]);
    Xq_array = [1000 2000 2500 2900];
    for DDi = 1:length(Xq_array) % Downstream distance in rotor diameters
        Xq = Xq_array(DDi)*ones(size(Yq));
        
        wakeSOWFA  = tmpInterpolant(Xq,Yq);
        wakeFLORISold = compute_probes(florisObjSet{i},Xq,Yq,HH*ones(size(Xq)),false);
        wakeFLORISopt = compute_probes(florisObjSetOpt{i},Xq,Yq,HH*ones(size(Xq)),false);
        
        subplot(1,length(Xq_array),DDi)
        plot(Yq,wakeSOWFA,'k-');
        hold on
        plot(Yq,wakeFLORISold,'k--');
        hold on
        plot(Yq,wakeFLORISopt,'k-.');
        legend('SOWFA','FLORIS_{old}','FLORIS_{opt}','Location','se');
        grid on; ylim([0 9]);
        ylabel('Wind speed (m/s)'); xlabel('y (m)');
        title(['x = ' num2str(Xq_array(DDi)) ' m, yaw (T1,T2) = ' num2str(rad2deg(controlSet{i}.yawAngleWFArray(1))) ' deg']);
    end
    
    set(gcf,'Position',[-1.2534e+03 397.8000 819.2000 181.6000]);
    for iii = 1:length(Xq_array)
        subplot(1,length(Xq_array),iii)
        ylim([2 9])
        delete(findobj('type','legend'))
        if iii == length(Xq_array)
            lgd = legend('SOWFA','FLORIS($\Omega_0$)','FLORIS($\Omega^\star$)');
            %         lgd.Orientation='horizontal'
            lgd.Position = [0.8570 0.3101 0.1213 0.2654];
        end
        if iii == 1
            ylabel('Wind speed (m/s)','interpreter','latex')
        else
            set(gca,'YTickLabel',[])
            ylabel('')
        end
        xlabel('y (m)','interpreter','latex')
        title(['x = ' num2str(Xq_array(iii)) ' m'],'interpreter','latex')
    end
    
    %     addpath('D:\bmdoekemeijer\My Documents\MATLAB\WFSim\libraries\export_fig')
    %     export_fig 'modelFitting_3turb_10MW_Uwake.png' -m5 -transparent
    %     export_fig 'modelFitting_3turb_10MW_Uwake.pdf' -transparent
end


% Make plots for WE2019
for i = [1 2 3]
    horIndx = 1;
    showFit(timeAvgData{i}(horIndx),florisObjSetOpt{i});
    set(gcf,'Position',[1.6658e+03 343.4000 454.4000 469.6000])
    subplot(3,1,1);
    box on
    plotTurbLocal(florisObjSetOpt{i})
    title('$U^{\mathrm{SOWFA}}$','interpreter','latex')
    xlabel(''); ylabel('y (m)','interpreter','latex')
    set(gca,'XTickLabel',[])
    
    subplot(3,1,2);
    box on
    plotTurbLocal(florisObjSetOpt{i})
    title('$U^{\mathrm{FLORIS}}$','interpreter','latex')
    xlabel(''); ylabel('y (m)','interpreter','latex')
    set(gca,'XTickLabel',[])
    
    subplot(3,1,3);
    box on
    plotTurbLocal(florisObjSetOpt{i})
    title('abs $\left( U^{\mathrm{SOWFA}} - U^{\mathrm{FLORIS}} \right)$','interpreter','latex')
    xlabel('x (m)','interpreter','latex')
    ylabel('y (m)','interpreter','latex')
    colormap(jet)
    
    %     addpath('D:\bmdoekemeijer\My Documents\MATLAB\WFSim\libraries\export_fig')
    %     export_fig 'modelFitting_3turb_10MW.png' -m5 -transparent
    %     export_fig 'modelFitting_3turb_10MW.pdf' -transparent
end

function [] = plotTurbLocal(florisObjIn)
locTurb = florisObjIn.layout.locIf;
xTurb = locTurb(:,1);
yTurb = locTurb(:,2);
R = florisObjIn.layout.uniqueTurbineTypes.rotorRadius;
yaw = florisObjIn.controlSet.yawAngleIFArray;
for ii = 1:length(xTurb)
    hold on
    plot3(xTurb(ii)+R*[sin(yaw(ii)) -sin(yaw(ii))],yTurb(ii)+R*[-cos(yaw(ii)) cos(yaw(ii))],[500 500],'k-')
end
end