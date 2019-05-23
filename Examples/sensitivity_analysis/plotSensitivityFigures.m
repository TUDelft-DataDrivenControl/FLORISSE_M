function [] = plotSensitivityFigures(outputMatrix, plotLayout, plotRadial, plotCrucial)
addpath(genpath('../../FLORISSE_M'))
addpath('bin')

if nargin == 1
    plotLayout = 0;
    plotRadial = 1;
    plotCrucial = 0;
end

% Import variables
trueRange = outputMatrix.trueRange;
relSearchRange = outputMatrix.relSearchRange;
sumJ = outputMatrix.sumJ;
noiseYaw = outputMatrix.noiseYaw;
noisePwr = outputMatrix.noisePwr;
locIf = outputMatrix.locIf;

% Derive dependent variables
nWS = size(sumJ,2);
nTI = size(sumJ,3);
nLayouts = size(sumJ,1);

% Construct farms
if nLayouts == 1
    florisRunner{1} = generateFlorisRunner(locIf);
else
    for i = 1:length(locIf)
        florisRunner{i} = generateFlorisRunner(locIf{i});
    end
    clear i
end

%% Figure
set(groot, 'defaultAxesTickLabelInterpreter','latex');
set(groot, 'defaultLegendInterpreter','latex');

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
%                     % Normalize each 'circle' w.r.t. all TIs and WDs
%                     sumJnorm(Layouti,WSi,:,:) = squeeze(sumJ(Layouti,WSi,:,:))/max(max(sumJ(Layouti,WSi,:,:)));                
                for TIi = 1:nTI
%                     % Normalize each radial slice of the 'circle' individually w.r.t. the WDs only
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
    
    [T,R] = meshgrid(trueRange.WD+pi,linspace(0,1,max([nTI 2])));
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
                ylb = ylabel(ax,['$U_{\infty} = ' num2str(trueRange.WS(WSi)) '$ m/s'],'interpreter','latex');
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
                florisRunnerCrucial.layout.ambientInflow.windDirection = trueRange.WD(minIdx);
                florisRunnerCrucial.layout.ambientInflow.Vref = trueRange.WS(WSi);
                florisRunnerCrucial.layout.ambientInflow.TI0 = trueRange.TI(TIi);
                florisRunnerCrucial.controlSet.yawAngleWFArray = florisRunnerCrucial.controlSet.yawAngleWFArray;
                florisRunnerCrucial.run();
                visTool = visualizer(florisRunnerCrucial);
                visTool.plot2dIF;
            end
        end
    end
    
end

end