function [] = plotLUTYawWD(databaseLUT,TiPlotIndices,WDstdPlotIndices)

nTurbs = length(databaseLUT.yawT);
powerDataAvail = any(strcmp(fieldnames(databaseLUT),'Pbl'));

if powerDataAvail
    spL = nTurbs+1; % Subplot length
else
    spL = nTurbs;
end

for WDstdi = [WDstdPlotIndices]
    WDstd = databaseLUT.WD_std_range(WDstdi);
    for TIi = [TiPlotIndices]
        figure('Position',[1537 -339.8000 864 1.4624e+03],'color','w');
        TI0 = databaseLUT.TI_range(TIi);    
        for turbi = 1:nTurbs
            sp1 = subplot(spL,1,turbi);
            for WSi = 1:databaseLUT.nWS
                WS = databaseLUT.WS_range(WSi);
                yawT{turbi} = squeeze(databaseLUT.yawT{turbi}(TIi,WSi,:,WDstdi));
                hold on
                plot(databaseLUT.WD_range,yawT{turbi},'displayName',['WS=' num2str(WS) ' m/s'])
                grid on
                if turbi == nTurbs & WSi == 1 & databaseLUT.nWS > 1
                    clb = legend('-dynamicLegend');
%                     clb.Position = [0.7754 0.0867 0.1802 0.8306];
                end
                if spL > turbi
                    set(gca,'XTickLabel',[])
                else
                    xlabel('Wind direction (deg)','interpreter','latex')
                end
                ylabel('$\gamma$ ($^\circ$)','interpreter','latex')
                title(['Turb ' num2str(turbi) '; TI = ' num2str(TI0) ', WDstd = ' num2str(WDstd)],'interpreter','latex');
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
                relGain = squeeze(databaseLUT.Popt(TIi,WSi,:,WDstdi)./databaseLUT.Pbl(TIi,WSi,:,WDstdi));
            end
            plot(databaseLUT.WD_range,relGain,'displayName',['WS=' num2str(databaseLUT.WS_range(WSi)) ' m/s'])
            xlim([databaseLUT.WD_range(1),databaseLUT.WD_range(end)])
        end
        
        if powerDataAvail && databaseLUT.nWS > 1
            % Averaged line
            meanGain = nanmean(squeeze(databaseLUT.Popt(TIi,:,:,WDstdi)./databaseLUT.Pbl(TIi,:,:,WDstdi)),1);
            hold on
            plot(databaseLUT.WD_range,meanGain,'k--','lineWidth',1.5,'displayName',['Mean'])
        end
    end
end
end

