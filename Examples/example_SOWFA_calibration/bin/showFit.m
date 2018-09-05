function [] = showFit(timeAvgData,florisObj,florisObjOpt)

if nargin < 2
    plotFloris = false;
else
    plotFloris = true;
end

if nargin < 3
    plotFlorisOpt = false;
else
    plotFlorisOpt = true;
end


%% Plotting time-averaged flow slices
for i = 1:length(timeAvgData)
    if max(abs(diff(timeAvgData(i).cellCenters(:,3)))) < 1e-5
        xData = timeAvgData(i).cellCenters(:,1);
        yData = timeAvgData(i).cellCenters(:,2);
        xlabelName = 'x (m)'; ylabelName = 'y (m)';
    elseif max(abs(diff(timeAvgData(i).cellCenters(:,2)))) < 1e-5
        xData = timeAvgData(i).cellCenters(:,1);
        yData = timeAvgData(i).cellCenters(:,3);
        xlabelName = 'x (m)'; ylabelName = 'z (m)';
    elseif max(abs(diff(timeAvgData(i).cellCenters(:,1)))) < 1e-5
        xData = timeAvgData(i).cellCenters(:,2);
        yData = timeAvgData(i).cellCenters(:,3);
        xlabelName = 'y (m)'; ylabelName = 'z (m)';
    else
        error(['Cannot determine which plane is exported for timeAvgData( ' num2str(i) ').']);
    end
    
    tri = delaunay(xData,yData);
    
    if plotFlorisOpt
        uFLORISOld = compute_probes(florisObj,timeAvgData(i).cellCenters(:,1),...
                                              timeAvgData(i).cellCenters(:,2),...
                                              timeAvgData(i).cellCenters(:,3),true);         
        uFLORISOpt = compute_probes(florisObjOpt,timeAvgData(i).cellCenters(:,1),...
                                                 timeAvgData(i).cellCenters(:,2),...
                                                 timeAvgData(i).cellCenters(:,3),true);        
        dataArray = {timeAvgData(i).UData; timeAvgData(i).UData; uFLORISOld; uFLORISOpt; ...
                     abs(timeAvgData(i).UData-uFLORISOld); abs(timeAvgData(i).UData-uFLORISOpt)};
        nameArray = {['SOWFA (' timeAvgData(i).name ')'];'SOWFA';'FLORIS_old';'FLORIS_opt';...
                     'abs(SOWFA-FLORIS_old)'; 'abs(SOWFA-FLORIS_opt)'};
        nCols = 2;
    elseif plotFloris 
        uFLORIS = compute_probes(florisObj,timeAvgData(i).cellCenters(:,1),...
                                           timeAvgData(i).cellCenters(:,2),...
                                           timeAvgData(i).cellCenters(:,3),true);        
        dataArray = {timeAvgData(i).UData;uFLORIS;abs(timeAvgData(i).UData-uFLORIS)};
        nameArray = {['SOWFA (' timeAvgData(i).name ')'],'FLORIS','abs(SOWFA-FLORIS)'};
        nCols = 1;
    else
        dataArray = {timeAvgData(i).UData};
        nameArray = {['SOWFA (' timeAvgData(i).name ')']};
        nCols = 1;
    end
    
    figure;
    for si = 1:length(dataArray)
        subplot(length(dataArray)/nCols,nCols,si); hold all;
        trisurf(tri, xData, yData, dataArray{si});
        lighting none; shading flat; colorbar;
        light('Position',[-50 -15 29]); view(0,90);
        if max(abs(diff(timeAvgData(i).cellCenters(:,1)))) < 1e-5 & si < 2 % Measurement locations
            hold on;
            scatter3(timeAvgData(i).extrapolatedDataY(:),timeAvgData(i).extrapolatedDataZ(:),...
                     +500*ones(size(timeAvgData(i).extrapolatedDataZ(:))),'k.','markerEdgeAlpha',0.4);
        end
        xlabel(xlabelName); ylabel(ylabelName);
        title(nameArray{si},'interpreter','none');
        axis equal tight
    end
    drawnow;
end
end

