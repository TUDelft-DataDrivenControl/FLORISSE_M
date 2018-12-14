clear all
addpath(genpath('../../FLORISSE_M'))

D = 178.3;

% Definition of Amalia wind farm
load('centers_Amalia.mat');
x_amalia = (1/80.0) * (Centers_turbine(:,1)-mean(Centers_turbine(:,1)));
y_amalia = (1/80.0) * (Centers_turbine(:,2)-mean(Centers_turbine(:,2)));
for iTurb = 1:length(x_amalia)
    locIf{iTurb,1} = [x_amalia(iTurb)-min(x_amalia) y_amalia(iTurb)-min(y_amalia)];
end

% Definition of generic cases
% locIf = {[0, 0]}; % 1-turbine case
% locIf = {[0, 0]; [5, 0]}; % 2-turbine case
% locIf = {[0, 0]; [5, 0]; [10 0]; [0 3]; [5 3]; [10 3]}; % 6 turb case

% Construct farm
locIf = cellfun(@(loc) D*loc, locIf, 'UniformOutput', false);
turbines = struct('turbineType', dtu10mw_v2() , ...
    'locIf',       locIf);

layout = layout_class(turbines, 'sensitivity_layout_10mw');

% Use the height from the first turbine type as reference height for the inflow profile
refheight = layout.uniqueTurbineTypes(1).hubHeight;

% Define an inflow struct and use it in the layout, clwindcon9Turb
layout.ambientInflow = ambient_inflow_uniform('windSpeed', 8, ...
    'windDirection', 0, ...
    'TI0', .1);

% Make a controlObject for this layout
controlSet = control_set(layout, 'yawAndRelPowerSetpoint');

% Define subModels
subModels = model_definition('deflectionModel','rans',...
    'velocityDeficitModel', 'selfSimilar',...
    'wakeCombinationModel', 'quadraticRotorVelocity',...
    'addedTurbulenceModel', 'crespoHernandez');

xopt_con =[ 7.841152377297512   4.573750238535804   0.431969955023207 ...
    -0.246470535856333   0.001117233213458   1.087617055657293 ...
    -0.007716521497980   0.221944783863084   0.536850894208880 ...
    -0.000847912134732]; % uFlow with highTI, Jopt = 10.28
subModels.modelData.TIa = xopt_con(1);
subModels.modelData.TIb = xopt_con(2);
subModels.modelData.TIc = xopt_con(3);
subModels.modelData.TId = xopt_con(4);
subModels.modelData.ad = xopt_con(5);
subModels.modelData.alpha = xopt_con(6);
subModels.modelData.bd = xopt_con(7);
subModels.modelData.beta = xopt_con(8);
subModels.modelData.ka = xopt_con(9);
subModels.modelData.kb = xopt_con(10);

% Initialize the FLORIS object and run the simulation
florisRunner = floris(layout, controlSet, subModels);

nWdTrue = 41;
nWdEst = nWdTrue - 1; % Recommended due to numerical stability
wdTrue_range = linspace(0,2*pi,nWdTrue);

if rem(nWdTrue,2) == 0
    disp('WARNING: RECOMMENDED TO USE AN UNEVEN NUMBER FOR ''nWdTrue''.')
end

sumJ = zeros(1,nWdTrue); % Initialize empty vector
tic
pb = CmdLineProgressBar('Calculating observability for WDi ');
parfor WDi = 1:nWdTrue
    wdTrue = wdTrue_range(WDi);
    pb.print(WDi,nWdTrue) % Progress
    
    % Calculate true power from FLORIS
    powerTrue = evalForWD(florisRunner,wdTrue,0,0);
    
    % Estimation
    noiseYaw = 0.0;
    noisePwr = 0.0;
    WD_range = linspace(0,2*pi,nWdEst+1);
    WD_range = WD_range(1:end-1);
    J = zeros(1,nWdEst);
    for WDii = 1:nWdEst
        WD = WD_range(WDii);
        if WD < 0; WD = WD + 2*pi; end
        if WD >= 2*pi; WD = WD - 2*pi; end
        powerOut = evalForWD(florisRunner,WD,noiseYaw,noisePwr);
        powerRMSE = sqrt(mean((powerOut-powerTrue).^2)) * 1e-6;
        
        % Homogenize
        if powerRMSE < 10*eps
            powerRMSE = 0;
        end
        
        dx = abs(WD-wdTrue); % Distance between arguments
        if dx > pi % Radial distance
            dx = 2*pi - dx;
        end
        J(WDii) = powerRMSE/(dx.^2); % The higher, the better
        powerRMSEsaved{WDi}(WDii) = powerRMSE;
    end
    Jsaved{WDi} = J;
%     sumJ(WDi) = sum(  J( rem(WD_range,2*pi) ~= rem(wdTrue,2*pi) )  );

    % Sum over all values (excluding the nan or numerically instable values)
    indicesJ = abs(rem(WD_range,2*pi) - rem(wdTrue,2*pi)) > 1e-8;
    sumJ(WDi) = sum(J(indicesJ));
end
toc
save(['tmpOut_' num2str(layout.nTurbs) 'turb.mat'])
% disp(sumJ);

if max(abs(diff(sumJ(1:(nWdTrue-1)/2)-sumJ((nWdTrue-1)/2+1:end-1)))) < 1e-6
    disp('Your observability rose appears to be symmetrical.');
else
    disp('Your observability rose appears to be non-symmetrical.');
end

%% Figure
set(groot, 'defaultAxesTickLabelInterpreter','latex');
set(groot, 'defaultLegendInterpreter','latex');

% plot(wdTrue_range,sumJ/max(sumJ))
% xlabel('Wind direction (rad)')
% ylabel('Observability')
% grid on


%% Turbine locations plot
plotLayout = true;
if plotLayout
    figure(1)
    set(gcf,'Position',[1.8634e+03 475.4000 218.4000 138.4000])
    clf; hold all
    normX = 5;
    normY = 2;
    Drotor = layout.uniqueTurbineTypes.rotorRadius * 2;
    locArray = [layout.locIf(:,1)/(normX*Drotor) ...
        layout.locIf(:,2)/(normY*Drotor)];
    
    for iTurb=1:layout.nTurbs
        Qx = locArray(iTurb,1);
        Qy = locArray(iTurb,2);
        bladeWidth = .10;
        rectangle('Position',[Qx-0.10 Qy-0.15 0.20 0.30],'Curvature',0.2,'FaceColor',.6*[1 1 1]) % hub
        rectangle('Position',[Qx-0.18 Qy bladeWidth 0.5],'Curvature',[1 1],'FaceColor',.9*[1 1 1]) % blade 1
        rectangle('Position',[Qx-0.18 Qy-0.5 bladeWidth 0.5],'Curvature',[1 1],'FaceColor',.9*[1 1 1]) % blade 2
    end
    xlim([min(locArray(:,1))-.5 max(locArray(:,1))+.5])
    ylim([min(locArray(:,2))-.8 max(locArray(:,2))+.8])
    grid on
    box on
    xlabel('x (D)','interpreter','latex')
    ylabel('y (D)','interpreter','latex')
    set(gca,'XTick', 0:1:layout.nTurbs)
    set(gca,'XTickLabel',0:normX:normX*layout.nTurbs)
    if length(unique(locArray(:,2))) > 1
        set(gca,'YTick', 0:1:layout.nTurbs)
        set(gca,'YTickLabel',0:normY:normY*layout.nTurbs)
    end
end


%% Radial plot
plotRadial = true;
if plotRadial
    figure(2); clf;
    % set(gcf,'Position',[1.6546e+03 512.2000 406.4000 224.8000]);
    set(gcf,'Position',[1.6546e+03 414.6000 406.4000 322.4000]);
    [T,R] = meshgrid(wdTrue_range+pi,linspace(0,1,2));
    X = R.*cos(T);
    Y = R.*sin(T);
    if max(sumJ) > 0
        Z = repmat(sumJ/max(sumJ),size(X,1),1);
    else
        Z = repmat(sumJ,size(X,1),1);
    end
    % sf=surf(X,Y,Z); hold on; surf(X,Y,Z,0:1.0); view(0,90); % SURFACE
    contourf(X,Y,Z,0.0:0.001:1.0,'Linecolor','none'); % caxis([0.0 1.0]); % CONTOURF
    tl=title(['Observability of ' num2str(florisRunner.layout.nTurbs) ' turbine case'],'interpreter','latex');
    tl.Position(2)=tl.Position(2)+0.35;
    hold all
    text(-1.25,0,'$0^{\circ}$','interpreter','latex')
    text(1.1,0,'$180^{\circ}$','interpreter','latex')
    text(-0.1,-1.15,'$90^{\circ}$','interpreter','latex')
    text(-0.1,1.1,'$270^{\circ}$','interpreter','latex')
    clb = colorbar;
    clb.Limits = [0.0 1.0];
    clb.Location = 'southoutside';
    clb.Position = [0.3072 0.195 0.4217 0.0303];
    colormap(flipud(jet))
    box off
    axis equal tight
    axis off
    set(gca,'Position',[0.1300 0.3357 0.7750 0.4687]);
end

%% Plot most crucial location
plotCrucial = true;
if plotCrucial
    [minSumJ,minIdx] = min(sumJ/max(sumJ));
    florisRunnerCrucial = copy(florisRunner);
    florisRunnerCrucial.layout.ambientInflow.windDirection = wdTrue_range(minIdx);
    florisRunnerCrucial.controlSet.yawAngleWFArray = florisRunnerCrucial.controlSet.yawAngleWFArray;
    florisRunnerCrucial.run();
    visTool = visualizer(florisRunnerCrucial);
    visTool.plot2dIF;
end

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