clear all; clc
addpath(genpath('../../FLORISSE_M'))

%% Setup
wdTrue_range = [0.1*pi pi];
WS = 8.0;
TI = 0.05;
nWdTrue = 121; % Discretization of 360 degrees wind rose. Recommended to be uneven number.
locIf = {};
locIf{end+1} = {[0, 0]; [5, 0]}; % 2-turbine case
locIf{end+1} = {[0, 0]; [5, 0]; [10 0]; [0 3]; [5 3]; [10 3]}; % Structured 6 turb case
locIf{end+1} = {[4, 8]; [9, 9]; [4, 13]; [0,6];[12 11]; [13 6]; [8 4]; [4 0]}; % Unstructured 8-turbine case


% Construct farm
D = 178.3;

for i = 1:length(locIf)
    locIf{i} = cellfun(@(loc) D*loc, locIf{i}, 'UniformOutput', false);
    turbines{i} = struct('turbineType', dtu10mw_v2(),'locIf',locIf{i});
    layout{i} = layout_class(turbines{i}, 'sensitivity_layout_10mw');
    
    refheight(i) = layout{i}.uniqueTurbineTypes(1).hubHeight; % Use the height from the first turbine type as reference height for the inflow profile
    layout{i}.ambientInflow = ambient_inflow_uniform('windSpeed', WS,'windDirection', 0, 'TI0', TI);
    
    % Make a controlObject for this layout
    controlSet{i} = control_set(layout{i}, 'yawAndRelPowerSetpoint');
    
    % Define subModels
    subModels = model_definition('deflectionModel','rans',...
        'velocityDeficitModel', 'selfSimilar',...
        'wakeCombinationModel', 'quadraticRotorVelocity',...
        'addedTurbulenceModel', 'crespoHernandez');
    
    subModels.modelData.TIa = 7.841152377297512;
    subModels.modelData.TIb = 4.573750238535804;
    subModels.modelData.TIc = 0.431969955023207;
    subModels.modelData.TId = -0.246470535856333;
    subModels.modelData.ad = 0.001117233213458;
    subModels.modelData.alpha = 1.087617055657293;
    subModels.modelData.bd = -0.007716521497980;
    subModels.modelData.beta = 0.221944783863084;
    subModels.modelData.ka = 0.536850894208880;
    subModels.modelData.kb = -0.000847912134732;
    
    % Initialize the FLORIS object and run the simulation
    florisRunner{i} = floris(layout{i}, controlSet{i}, subModels);
    
end

nWdEst = nWdTrue - 1; % Recommended due to numerical stability

if rem(nWdTrue,2) == 0
    disp('WARNING: RECOMMENDED TO USE AN UNEVEN NUMBER FOR ''nWdTrue''.')
end

tic

for WDi = 1:length(wdTrue_range)
    wdTrue = wdTrue_range(WDi);
    for i = 1:length(locIf)
        florisRunnerLocal = copy(florisRunner{i});
        
        % Calculate true power from FLORIS
        powerTrue = evalForWD(florisRunnerLocal,wdTrue);
        
        % Estimation
        WD_range = linspace(0,2*pi,nWdEst+1);
        WD_range = WD_range(1:end-1);
        J{WDi,i} = zeros(1,nWdEst);
        for WDii = 1:nWdEst
            WD = WD_range(WDii);
            if WD < 0; WD = WD + 2*pi; end
            if WD >= 2*pi; WD = WD - 2*pi; end
            powerOut = evalForWD(florisRunnerLocal,WD);
            J{WDi,i}(WDii) = sqrt(mean((powerOut-powerTrue).^2)) * 1e-6;
        end
    end
end

figure
set(gcf,'Position',[371.4000 293 843.2000 256.8000]);
%% Plot results
clf
linestyles = {'k-','k-.','k--'};
for i = 1:length(locIf)
    subplot(1,length(locIf),i);
    hold all;
    for WDi = 1:length(wdTrue_range)
        wdTrue = wdTrue_range(WDi);
        plot(WD_range,J{WDi,i},linestyles{WDi},'Color',.25*[1 1 1],'displayName',['$\phi^\ast = ' num2str(wdTrue) '$ rad'])
        hold on
        plot(wdTrue,0,'k.','MarkerSize',10,'MarkerEdgeColor',[0 0 0],'HandleVisibility','off')  
        plot(wdTrue,0,'ko','MarkerSize',10,'MarkerEdgeColor',[0 0 0],'HandleVisibility','off') 
    end
    xlim([0 2*pi])
    grid on
    axis tight
    xlim([-0.05*pi 2.05*pi])
    ylim([-0.05 max(J{WDi,i})*1.05])
    box on
    %         ax{i} = gca;
    if i == 1
        ylabel('Power RMSE (MW)','FontSize',14,'interpreter','latex')
    else
        set(gca,'YTickLabel','')
    end
    set(gca,'XTick',[0 pi 2*pi])
    set(gca,'XTickLabel',{'0'; '\pi'; '2 \pi'})
    set(gca,'FontSize',13)
    ax{i} = gca;
    ax{i}.Position(4) = 0.6; % Change height
    ax{i}.Position(2) = 0.22; % Change height
    xlabel('$\phi$ (rad)','interpreter','latex','FontSize',14)
    
    if i == 2 % legend
        lgd = legend({'$\phi^\ast = 0.10 \pi$~~~~';'$\phi^\ast = \pi$'} ,'Location','north');
        lgd.Interpreter = 'latex';
        lgd.Orientation = 'horizontal';
        lgd.Position = [0.4074 0.8751 0.2191 0.0752];
    end
end


%     addpath('D:\bmdoekemeijer\My Documents\MATLAB\WFSim\libraries\export_fig')
%     export_fig 'costfun_example.pdf' -transparent
function powerOut = evalForWD(florisRunnerIn,windDirection,noiseYawAngles,noisePower)
% Default noise values
if nargin < 3
    noiseYawAngles = 0.0;
end
if nargin < 4
    noisePower = 0.0;
end

% Update and run
florisRunnerLocal = copy(florisRunnerIn);
florisRunnerLocal.clearOutput();
florisRunnerLocal.layout.ambientInflow.windDirection = windDirection;

% Maintain same relative yaw angle in wind-aligned frame
florisRunnerLocal.controlSet.yawAngleWFArray = ...
    florisRunnerLocal.controlSet.yawAngleWFArray + ...
    noiseYawAngles * randn(1,florisRunnerLocal.layout.nTurbs);

% Run and export power
florisRunnerLocal.run();
powerOut = [florisRunnerLocal.turbineResults.power] + ...
    noisePower * randn(1,florisRunnerLocal.layout.nTurbs);
end