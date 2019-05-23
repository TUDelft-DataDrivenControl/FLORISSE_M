function [] = plotLUTYawWD(databaseLUT,TiPlotIndices)

nTurbs = length(databaseLUT.yawT);
powerDataAvail = any(strcmp(fieldnames(databaseLUT),'Pbl'));

if powerDataAvail
    spL = nTurbs+1; % Subplot length
else
    spL = nTurbs;
end

for TIi = [TiPlotIndices] %1:databaseLUT.nTI
    TI0 = databaseLUT.TI_range(TIi);
    
    figure()%('Position',[1593 187.4000 687.2000 620],'color','w');
    for turbi = 1:nTurbs
        sp1 = subplot(spL,1,turbi);
        for WSi = 1:databaseLUT.nWS
            yawT{turbi} = squeeze(databaseLUT.yawT{turbi}(TIi,WSi,:));
            plot(databaseLUT.WD_range,yawT{turbi})
            grid on
            if databaseLUT.nWS > 1
                clb = legend('-dynamicLegend');
                clb.Position = [0.7754 0.0867 0.1802 0.8306];
            end
            if spL > turbi
                set(gca,'XTickLabel',[])
            else
                xlabel('Wind direction (deg)','interpreter','latex')
            end
            ylabel('$\gamma$ ($^\circ$)','interpreter','latex')
            title(['Turb ' num2str(turbi) '; TI = ' num2str(TI0)],'interpreter','latex');
            ylim([-32 32])
            box on
        end
        xlim([databaseLUT.WD_range(1),databaseLUT.WD_range(end)])
    end
    if powerDataAvail
        sp1 = subplot(spL,1,spL);
        grid on
        xlabel('Wind direction')
        ylabel('$P_{bl}^{-1} \cdot P_{opt}$','interpreter','latex')
        box on
        hold on
        for WSi = 1:databaseLUT.nWS
            relGain = squeeze(databaseLUT.Popt(TIi,WSi,:)./databaseLUT.Pbl(TIi,WSi,:));
        end
        plot(databaseLUT.WD_range,relGain,'displayName',['WS=' num2str(databaseLUT.WS_range(WSi)) ' m/s'])
        xlim([databaseLUT.WD_range(1),databaseLUT.WD_range(end)])
    end
    
    if powerDataAvail && databaseLUT.nWS > 1
        % Averaged line
        meanGain = nanmean(databaseLUT.Popt(TIi,:,:)./databaseLUT.Pbl(TIi,:,:),1);
        hold on
        plot(databaseLUT.WD_range,meanGain,'k--','lineWidth',1.5,'displayName',['Mean'])
    end
end
end

