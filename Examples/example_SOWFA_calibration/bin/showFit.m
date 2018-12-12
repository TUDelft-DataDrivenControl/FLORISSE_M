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
        zlimTmp = [0 ceil(max([timeAvgData(i).UData; uFLORISOld; uFLORISOpt]))];
        zlimArray = {zlimTmp; zlimTmp; zlimTmp; zlimTmp; [0 3]; [0 3]};
        nameArray = {['SOWFA (' timeAvgData(i).name ')'];'SOWFA';'FLORIS_old';'FLORIS_opt';...
                     'abs(SOWFA-FLORIS_old)'; 'abs(SOWFA-FLORIS_opt)'};
        nCols = 2;
    elseif plotFloris 
        uFLORIS = compute_probes(florisObj,timeAvgData(i).cellCenters(:,1),...
                                           timeAvgData(i).cellCenters(:,2),...
                                           timeAvgData(i).cellCenters(:,3),true);        
        dataArray = {timeAvgData(i).UData;uFLORIS;abs(timeAvgData(i).UData-uFLORIS)};
        zlimTmp = [0 ceil(max([timeAvgData(i).UData; uFLORIS]))];
        zlimArray = {zlimTmp; zlimTmp; [0 3]};
        nameArray = {['SOWFA (' timeAvgData(i).name ')'],'FLORIS','abs(SOWFA-FLORIS)'};
        nCols = 1;
    else
        dataArray = {timeAvgData(i).UData};
        zlimArray = {[0 max(timeAvgData(i).UData)]};
        nameArray = {['SOWFA (' timeAvgData(i).name ')']};
        nCols = 1;
    end
    
    figure;
    for si = 1:length(dataArray)
        subplot(length(dataArray)/nCols,nCols,si); 
        hold all;
        trisurf(tri, xData, yData, dataArray{si});
        caxis(zlimArray{si})
        clb = colorbar;
        clb.Limits = zlimArray{si};
        lighting none; shading flat; 
        light('Position',[-50 -15 29]); view(0,90);
        if max(abs(diff(timeAvgData(i).cellCenters(:,1)))) < 1e-5 & si < 2 % Vertical slice
            hold on;
            if isfield(timeAvgData(i),'extrapolatedDataY')
                scatter3(timeAvgData(i).extrapolatedDataY(:),timeAvgData(i).extrapolatedDataZ(:),...
                         +500*ones(size(timeAvgData(i).extrapolatedDataZ(:))),'k.','markerEdgeAlpha',0.4);
            end
            if isfield(timeAvgData(i),'virtTurb')
                if ~isempty(timeAvgData(i).virtTurb)
                    for jj = [1 size(timeAvgData(i).virtTurb.Locs,1)]
                        for angle = linspace(0,2*pi,30)
                            yTmp = cos(angle)*timeAvgData(i).virtTurb.Drotor/2+timeAvgData(i).virtTurb.Locs(jj,2);
                            zTmp = sin(angle)*timeAvgData(i).virtTurb.Drotor/2+timeAvgData(i).virtTurb.Locs(jj,3);
                            hold on;
                            scatter3(yTmp,zTmp,500*ones(size(zTmp)),'r.','markerEdgeAlpha',0.6);    
                        end
                    end
                    hold on
                    scatter3(timeAvgData(i).virtTurb.Locs(:,2),timeAvgData(i).virtTurb.Locs(:,3),...
                             500*ones(size(timeAvgData(i).virtTurb.Locs(:,2))),'r.','markerEdgeAlpha',0.6);
                end
            end
        end
        xlabel(xlabelName); ylabel(ylabelName);
        title(nameArray{si},'interpreter','none');
        axis equal tight
    end
    drawnow;
end
end

