clear all; clc
addpath(genpath('../../FLORISSE_M'))

%% Setup
nWdTrue = 37; % Discretization of 360 degrees wind rose. Recommended to be uneven number.
WS_range = 12.0 %[8.0 12.0 15.0 17.0]; % Below, at, and above-rated
TI_range = 0.02 %[0.02 0.07 0.12 0.20];

noiseYaw = 7 * (pi/180); % Add gauss. noise over FLORIS evaulations -- Needs attention. Recommended: 0
noisePwr = 50 * 1e5; % Add gauss. noise over FLORIS evaluations -- Needs attention. Recommended: 0

% Plotting functions
plotLayout = false;
plotRadial = true;
plotCrucial = false;

% Layout definitions
locIf = {};
% locIf = {[0, 0]}; % 1-turbine case
% locIf{end+1} = {[0, 0]; [5, 0]}; % 2-turbine case
locIf{end+1} = {[0, 0]; [5, 0]; [10 0]; [0 3]; [5 3]; [10 3]}; % Structured 6 turb case
% locIf{end+1} = {[4, 8]; [9, 9]; [4, 13]; [0,6];[12 11]; [13 6]; [8 4]; [4 0]}; % Unstructured 8-turbine case

% % Definition of Amalia wind farm
% load('centers_Amalia.mat');
% x_amalia = (1/80.0) * (Centers_turbine(:,1)-mean(Centers_turbine(:,1)));
% y_amalia = (1/80.0) * (Centers_turbine(:,2)-mean(Centers_turbine(:,2)));
% for iTurb = 1:length(x_amalia)
%     locIf{end+1}{iTurb,1} = [x_amalia(iTurb)-min(x_amalia) y_amalia(iTurb)-min(y_amalia)];
% end

% Construct farm
D = 178.3;
for i = 1:length(locIf)
    locIf{i} = cellfun(@(loc) D*loc, locIf{i}, 'UniformOutput', false);
    turbines = struct('turbineType', dtu10mw_v2(),'locIf',locIf{i});
    layout{i} = layout_class(turbines, 'sensitivity_layout_10mw');
    refheight(i) = layout{i}.uniqueTurbineTypes(1).hubHeight; % Use the height from the first turbine type as reference height for the inflow profile
    
    % Define an inflow struct and use it in the layout
    layout{i}.ambientInflow = ambient_inflow_uniform('windSpeed', WS_range(1), ...
        'windDirection', 0, 'TI0', TI_range(1));
    
    % Make a controlObject for this layout
    controlSet{i} = control_set(layout{i}, 'yawAndRelPowerSetpoint');

    % Define subModels
    subModels{i} = model_definition('deflectionModel','rans',...
                                'velocityDeficitModel', 'selfSimilar',...
                                'wakeCombinationModel', 'quadraticRotorVelocity',...
                                'addedTurbulenceModel', 'crespoHernandez');

    subModels{i}.modelData.TIa = 7.841152377297512;
    subModels{i}.modelData.TIb = 4.573750238535804;
    subModels{i}.modelData.TIc = 0.431969955023207;
    subModels{i}.modelData.TId = -0.246470535856333;
    subModels{i}.modelData.ad = 0.001117233213458;
    subModels{i}.modelData.alpha = 1.087617055657293;
    subModels{i}.modelData.bd = -0.007716521497980;
    subModels{i}.modelData.beta = 0.221944783863084;
    subModels{i}.modelData.ka = 0.536850894208880;
    subModels{i}.modelData.kb = -0.000847912134732;

    % Initialize the FLORIS object and run the simulation
    florisRunner{i} = floris(layout{i}, controlSet{i}, subModels{i});
end
clear i

nWdEst = nWdTrue - 1; % Recommended due to numerical stability
wdTrue_range = linspace(0,2*pi,nWdTrue);

if rem(nWdTrue,2) == 0
    disp('WARNING: RECOMMENDED TO USE AN UNEVEN NUMBER FOR ''nWdTrue''.')
end

tic
nLayouts = length(layout);
nWS = length(WS_range);
nTI = length(TI_range);
sumJ = zeros(nLayouts,nWS,nTI,nWdTrue); % Initialize empty vector
for Layouti = 1:nLayouts
    florisRunnerLocal = copy(florisRunner{Layouti});
    disp(['Determining all roses for layout{' num2str(Layouti) '}.'])
    for WSi = 1:nWS
        florisRunnerLocal.layout.ambientInflow.Vref = WS_range(WSi);
        disp(['  Determining rose for WS = ' num2str(WS_range(WSi)) ' m/s.'])
        for TIi = 1:nTI
            florisRunnerLocal.layout.ambientInflow.TI0 = TI_range(TIi);
            disp(['    Calculating observability for TIi = ' num2str(TIi) '/' num2str(nTI) '.']); % Progress
            
            parfor WDi = 1:nWdTrue
                wdTrue = wdTrue_range(WDi);
                % Calculate true power from FLORIS
                powerTrue = evalForWD(florisRunnerLocal,wdTrue,0,0);
                
                % Estimation
                WD_range = linspace(0,2*pi,nWdEst+1);
                WD_range = WD_range(1:end-1);
                J = zeros(1,nWdEst);
                for WDii = 1:nWdEst
                    WD = WD_range(WDii);
                    if WD < 0; WD = WD + 2*pi; end
                    if WD >= 2*pi; WD = WD - 2*pi; end
                    powerOut = evalForWD(florisRunnerLocal,WD,noiseYaw,noisePwr);
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
                end
                
                % Sum over all values (excluding the nan or numerically instable values)
                indicesJ = abs(rem(WD_range,2*pi) - rem(wdTrue,2*pi)) > 1e-8;
                sumJ(Layouti,WSi,TIi,WDi) = sum(J(indicesJ));
            end
        end
    end
    if max(abs(diff(sumJ(Layouti,1,1,1:(nWdTrue-1)/2)-sumJ(Layouti,1,1,(nWdTrue-1)/2+1:end-1)))) < 1e-6
        disp(['The observability rose of layout{' num2str(Layouti) '} appears to be symmetrical.']);
    else
        disp(['The observability rose of layout{' num2str(Layouti) '} appears to be non-symmetrical.']);
    end    
end
toc

save(['tmpOut_' strrep(strrep(datestr(now),' ','_'),':','_') 'turb.mat'])



%% Figure
set(groot, 'defaultAxesTickLabelInterpreter','latex');
set(groot, 'defaultLegendInterpreter','latex');

% plot(wdTrue_range,sumJ/max(sumJ))
% xlabel('Wind direction (rad)')
% ylabel('Observability')
% grid on


%% Turbine locations plot
if plotLayout
    for Layouti = 1:nLayouts
        figure
%         set(gcf,'Position',[1.8634e+03 475.4000 218.4000 138.4000])
        hold all
        normX = 5;
        normY = 2;
        Drotor = layout{Layouti}.uniqueTurbineTypes.rotorRadius * 2;
        locArray = [layout{Layouti}.locIf(:,1)/(normX*Drotor) ...
            layout{Layouti}.locIf(:,2)/(normY*Drotor)];

        for iTurb=1:layout{Layouti}.nTurbs
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
        set(gca,'XTick', 0:1:layout{Layouti}.nTurbs)
        set(gca,'XTickLabel',0:normX:normX*layout{Layouti}.nTurbs)
        if length(unique(locArray(:,2))) > 1
            set(gca,'YTick', 0:1:layout{Layouti}.nTurbs)
            set(gca,'YTickLabel',0:normY:normY*layout{Layouti}.nTurbs)
        end
    end
end


%% Radial plot
if plotRadial
    % Normalize
    if max(sumJ(:)) > 0
        for Layouti = 1:nLayouts
            for WSi = 1:nWS
                for TIi = 1:nTI
%                     sumJnorm(Layouti,WSi,:,:) = squeeze(sumJ(Layouti,WSi,:,:))/max(max(sumJ(Layouti,WSi,:,:)));
                    sumJnorm(Layouti,WSi,TIi,:) = squeeze(sumJ(Layouti,WSi,TIi,:))/max(max(sumJ(Layouti,WSi,TIi,:)));
                end
            end
        end
    end
    
    figure; clf;
    if nWS == 4 && nLayouts == 3
        set(gcf,'Position',[1.6546e+03 149.8000 528.0000 587.2000]);
    elseif nWS == 1
        set(gcf,'Position',[1.6546e+03 414.6000 406.4000 322.4000]);
    else
        set(gcf,'Position',[1.6546e+03 174.6000 406.4000 562.4000]);
    end
    
    [T,R] = meshgrid(wdTrue_range+pi,linspace(0,1,max([nTI 2])));
    X = R.*cos(T);
    Y = R.*sin(T);
    
    for WSi = 1:nWS
        for Layouti = 1:nLayouts
            if nWS > 1 || nLayouts > 1
                subplot(nWS,nLayouts,Layouti+(WSi-1)*nLayouts)
            end
            if nTI == 1
                Z = repmat(squeeze(sumJnorm(Layouti,WSi,:,:))',2,1);
            else
                %         Z = [sumJnorm; sumJnorm(end,:)];
                Z = squeeze(sumJnorm(Layouti,WSi,:,:));
            end
            
            %     sf=surf(X,Y,Z); hold on; surf(X,Y,Z,0:0.01:1.0); view(0,90); % SURFACE
            
            % CONTOURF
            contourf(X,Y,Z,0.0:0.001:1.0,'Linecolor','none'); % caxis([0.0 1.0]);
            hold all
            caxis([0 1])
            lineAlpha = 0.15;
            % circular lines
            for i = 1:size(X,1)
                plt = plot(X(i,:),Y(i,:),'k-');
                plt.Color(4) = lineAlpha;
            end
            % radial lines
            for i = 1:size(X,2)
                plt = plot([0 X(end,i)],[0 Y(end,i)],'k-');
                plt.Color(4) = lineAlpha;
            end
            
            if WSi == 1
                tl=title([num2str(florisRunner{Layouti}.layout.nTurbs) ' turbine case'],'interpreter','latex');
                tl.Position(2)=tl.Position(2)+0.35;
            end
            hold all
            text(-1.25,0,'$0^{\circ}$','interpreter','latex')
            text(1.1,0,'$180^{\circ}$','interpreter','latex')
            text(-0.1,-1.15,'$90^{\circ}$','interpreter','latex')
            text(-0.1,1.1,'$270^{\circ}$','interpreter','latex')
            box off
            ax = gca;
            axis equal tight
            axis(ax,'off');
            if Layouti == 1
                ylb = ylabel(ax,['$U_{\infty} = ' num2str(WS_range(WSi)) '$ m/s'],'interpreter','latex');
            end
            set(get(ax,'YLabel'),'Visible','on')
            %         axis off
            %         set(gca,'Position',[0.1300 0.3357 0.7750 0.4687]);
            %         clb = colorbar;
        end
    end
    clb = colorbar;
    clb.Limits = [0.0 1.0];
    clb.Location = 'southoutside';
%     clb.Position = clb.Position+0.01; %[0.3072 0.195 0.4217 0.0303];
    clb.Position(2)=0.04;
    clb.Position(3)=clb.Position(3)+0.30;
    if nLayouts == 3
        clb.Position(1)=0.36;
    else
        clb.Position(1)=clb.Position(1)-0.15;
    end
    colormap(flipud(jet))
    
%     addpath('D:\bmdoekemeijer\My Documents\MATLAB\WFSim\libraries\export_fig')
%     export_fig 'sensitivity_radial.png' -m5 -transparent
%     export_fig 'sensitivity_radial.pdf' -transparent
end

%% Plot most crucial locations
if plotCrucial
    for Layouti = 1:nLayouts
        for WSi = 1:nWS
            for TIi = 1:nTI
                [minSumJ,minIdx] = min(squeeze(sumJ(Layouti,WSi,TIi,:)));
                florisRunnerCrucial = copy(florisRunner{Layouti});
                florisRunnerCrucial.layout.ambientInflow.windDirection = wdTrue_range(minIdx);
                florisRunnerCrucial.layout.ambientInflow.Vref = WS_range(WSi);
                florisRunnerCrucial.layout.ambientInflow.TI0 = TI_range(TIi);
                florisRunnerCrucial.controlSet.yawAngleWFArray = florisRunnerCrucial.controlSet.yawAngleWFArray;
                florisRunnerCrucial.run();
                visTool = visualizer(florisRunnerCrucial);
                visTool.plot2dIF;                
            end
        end
    end

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