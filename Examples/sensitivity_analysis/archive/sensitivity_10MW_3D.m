clear all; clc
addpath(genpath('../../FLORISSE_M'))

%% Setup
sensanalysis_WD_range = linspace(0,2*pi,37); % Discretization of 360 degrees wind rose. Recommended to be uneven number.
sensanalysis_WS_range = [8.5];% 12.0 15.0 17.0]; % Below, at, and above-rated
sensanalysis_TI_range = 0.12;%[0.02 0.07 0.12 0.20];

WD_relSearchRange = linspace(-20.,20.,41) * (pi/180);
WS_relSearchRange = linspace(-1.0,1.0,8);
TI_relSearchRange = [-0.06 0.0 0.06 0.12]; % Get TI exactly right; max([0.02, tiTrue-0.05]) : 0.05 : (tiTrue+0.05);
            
noiseYaw = 0 * (pi/180); % Add gauss. noise over FLORIS evaulations -- Needs attention. Recommended: 0
noisePwr = 0 * 1e5; % Add gauss. noise over FLORIS evaluations -- Needs attention. Recommended: 0

% Plotting functions
plotLayout = false;
plotRadial = true;
plotCrucial = false;

% Layout definitions
locIf = {};
% locIf{end+1} = {[0, 0]}; % 1-turbine case
locIf{end+1} = {[0, 0]; [5, 0]}; % 2-turbine case
% locIf{end+1} = {[0, 0]; [5, 0]; [10 0]; [0 3]; [5 3]; [10 3]}; % Structured 6 turb case
% locIf{end+1} = {[4, 8]; [9, 9]; [4, 13]; [0,6];[12 11]; [13 6]; [8 4]; [4 0]}; % Unstructured 8-turbine case

% % Definition of Amalia wind farm
% load('centers_Amalia.mat');
% x_amalia = (1/80.0) * (Centers_turbine(:,1)-mean(Centers_turbine(:,1)));
% y_amalia = (1/80.0) * (Centers_turbine(:,2)-mean(Centers_turbine(:,2)));
% for iTurb = 1:length(x_amalia)
%     locIf{end+1}{iTurb,1} = [x_amalia(iTurb)-min(x_amalia) y_amalia(iTurb)-min(y_amalia)];
% end

% Construct farms
for i = 1:length(locIf)
    florisRunner{i} = generateFlorisRunner(locIf{i});
end
clear i

tic
nLayouts = length(locIf);
nWS = length(sensanalysis_WS_range);
nTI = length(sensanalysis_TI_range);
nWD = length(sensanalysis_WD_range);
if rem(nWD,2) == 0
    disp('WARNING: RECOMMENDED TO DISCRETIZE WD AT AN UNEVEN NUMBER: '' WDsensitivity_range ''.')
end

sumJ = zeros(nLayouts,nWS,nTI,nWD); % Initialize empty tensor
for Layouti = 1:nLayouts
    florisRunnerTrue = copy(florisRunner{Layouti});
    disp(['Determining all roses for layout{' num2str(Layouti) '} (' num2str(Layouti) '/' num2str(nLayouts) ').'])
    for WSi = 1:nWS
        wsTrue = sensanalysis_WS_range(WSi);
        florisRunnerTrue.layout.ambientInflow.Vref = wsTrue;
        disp(['  Determining rose for WS_true = ' num2str(sensanalysis_WS_range(WSi)) ' m/s (' num2str(WSi) '/' num2str(nWS) ').'])
        for TIi = 1:nTI
            tiTrue = sensanalysis_TI_range(TIi);
            florisRunnerTrue.layout.ambientInflow.TI0 = tiTrue;
            disp(['    Calculating observability for TI_true = tiTrue (' num2str(TIi) '/' num2str(nTI) ').']); % Progress
            
            WD_abssearchrange = 0.0    + WD_relSearchRange;
            WS_abssearchrange = wsTrue + WS_relSearchRange;
            TI_abssearchrange = tiTrue + TI_relSearchRange;
            
            % Determine observability for these true conditions
            sumJ(Layouti,WSi,TIi,:) = sensitivityRose(...
                florisRunnerTrue,sensanalysis_WD_range,...
                WS_abssearchrange,...
                TI_abssearchrange,...
                WD_abssearchrange,...
                noiseYaw,noisePwr);
            
        end
    end
    if max(abs(diff(sumJ(Layouti,1,1,1:(nWD-1)/2)-sumJ(Layouti,1,1,(nWD-1)/2+1:end-1)))) < 1e-6
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
        Drotor = florisRunner{Layouti}.layout.uniqueTurbineTypes.rotorRadius * 2;
        locArray = [florisRunner{Layouti}.layout.locIf(:,1)/(normX*Drotor) ...
                    florisRunner{Layouti}.layout.locIf(:,2)/(normY*Drotor)];
        
        for iTurb=1:florisRunner{Layouti}.layout.nTurbs
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
        set(gca,'XTick', 0:1:florisRunner{Layouti}.layout.nTurbs)
        set(gca,'XTickLabel',0:normX:normX*florisRunner{Layouti}.layout.nTurbs)
        if length(unique(locArray(:,2))) > 1
            set(gca,'YTick', 0:1:florisRunner{Layouti}.layout.nTurbs)
            set(gca,'YTickLabel',0:normY:normY*florisRunner{Layouti}.layout.nTurbs)
        end
    end
end


%% Radial plot
if plotRadial
    % Normalize
    if max(sumJ(:)) > 0
        for Layouti = 1:nLayouts
            for WSi = 1:nWS
                    % Normalize each 'circle' w.r.t. all TIs and WDs
%                     sumJnorm(Layouti,WSi,:,:) = squeeze(sumJ(Layouti,WSi,:,:))/max(max(sumJ(Layouti,WSi,:,:)));                
                for TIi = 1:nTI
                    % Normalize each radial slice of the 'circle' individually w.r.t. the WDs only
%                     sumJnorm(Layouti,WSi,TIi,:) = squeeze(sumJ(Layouti,WSi,TIi,:))/max(max(sumJ(Layouti,WSi,TIi,:)));

                    % Normalize each 'circle' w.r.t. all WSs, TIs and WDs
                    sumJnorm(Layouti,WSi,TIi,:) = squeeze(sumJ(Layouti,WSi,TIi,:))/max(max(max(sumJ(Layouti,:,:,:))));
                end
            end
        end
    else
        sumJnorm = sumJ;
    end
    
    figure; clf;
    if nWS == 4 && nLayouts == 3
        set(gcf,'Position',[1.6546e+03 149.8000 528.0000 587.2000]);
    elseif nWS == 1
        set(gcf,'Position',[1.6546e+03 414.6000 406.4000 322.4000]);
    else
        set(gcf,'Position',[1.6546e+03 174.6000 406.4000 562.4000]);
    end
    
    [T,R] = meshgrid(sensanalysis_WD_range+pi,linspace(0,1,max([nTI 2])));
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
                ylb = ylabel(ax,['$U_{\infty} = ' num2str(sensanalysis_WS_range(WSi)) '$ m/s'],'interpreter','latex');
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
                florisRunnerCrucial.layout.ambientInflow.windDirection = sensanalysis_WD_range(minIdx);
                florisRunnerCrucial.layout.ambientInflow.Vref = sensanalysis_WS_range(WSi);
                florisRunnerCrucial.layout.ambientInflow.TI0 = sensanalysis_TI_range(TIi);
                florisRunnerCrucial.controlSet.yawAngleWFArray = florisRunnerCrucial.controlSet.yawAngleWFArray;
                florisRunnerCrucial.run();
                visTool = visualizer(florisRunnerCrucial);
                visTool.plot2dIF;
            end
        end
    end
    
end