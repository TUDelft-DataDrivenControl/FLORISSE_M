function [] = plotLUTsurf(databaseLUT,TiPlotIndices)
nTurbs = length(databaseLUT.yawT);
if databaseLUT.nWS <= 1
    error('You need at least 2 different WSs for a 2D plot of your LUT.')
end
for TIi = [TiPlotIndices]    
    figure()
    for turbi = 1:nTurbs
        databaseTmpT{turbi} = squeeze(databaseLUT.yawT{turbi}(TIi,:,:));
        
        subplot(nTurbs,1,turbi)
        surf(databaseLUT.WS_range,databaseLUT.WD_range,databaseTmpT{turbi}');
        xlabel('Wind speed (m/s)')
        ylabel('Wind direction (deg)')
        zlabel('Yaw angle (deg)')
        grid on
        title(['Turbine ' num2str(turbi) '; TI = ' num2str(databaseLUT.TI_range(TIi)) ''],'interpreter','latex')
        pbaspect([2 2.5 1])
    end
end

