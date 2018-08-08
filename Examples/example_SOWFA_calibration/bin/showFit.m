function [] = showFit(timeAvgData,florisObj)

if nargin < 2
    florisObj  = [];
    plotFloris = false;
else
    plotFloris = true;
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
    
    
    if plotFloris 
        uFLORIS = compute_probes(florisObj,timeAvgData(i).cellCenters(:,1),...
                                           timeAvgData(i).cellCenters(:,2),...
                                           timeAvgData(i).cellCenters(:,3),true);        
        dataArray = {timeAvgData(i).UData;uFLORIS;timeAvgData(i).UData-uFLORIS};
        nameArray = {'SOWFA','FLORIS','SOWFA-FLORIS'};
    else
        dataArray = {timeAvgData(i).UData};
        nameArray = {'SOWFA'};
    end
    
    figure;
    for si = 1:length(dataArray)
        subplot(length(dataArray),1,si); hold all;
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

