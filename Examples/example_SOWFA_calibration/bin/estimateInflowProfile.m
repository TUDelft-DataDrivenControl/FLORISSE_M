function [curveFit,fitGoodness] = estimateInflowProfile(cellCenters,UData,plotFigures)

% Default option: do not plot figures
if nargin < 3
    plotFigures = 'none';
end

%% Extract vertical inflow profile
nSamples    = [300, 100]; % [ySamples, zSamples]
domainEdges = [min(cellCenters); max(cellCenters)];

yVec = linspace(domainEdges(1,2),domainEdges(2,2),nSamples(1));
zVec = linspace(domainEdges(1,3),domainEdges(2,3),nSamples(2));

[Y,Z] = meshgrid(yVec,zVec);
% UGrid = griddata(cellCenters(:,2),cellCenters(:,3),UData, Y,Z, 'linear');
UGrid = griddata(cellCenters(:,2),cellCenters(:,3),UData, Y,Z, 'nearest');
meanVertProfile = mean(UGrid,2);

% Add (0,0) to dataset
zVec            = [0 zVec]';
meanVertProfile = [0; meanVertProfile];

% Exponential fit: usually poor...
% fo = fitoptions('Method','NonlinearLeastSquares',...
%                'Lower',[0,0],...
%                'Upper',[100.0,10.0],...
%                'StartPoint',[4.5,0.14]);
% ft = fittype('a*(x)^b','options',fo);
% [curveFit,fitGoodness] = fit(zVec,meanVertProfile,ft);

% Linear interpolant fit
[curveFit,fitGoodness] = fit(zVec,meanVertProfile,'linearinterp');
vertProfileFit = curveFit(zVec);

if strcmp(plotFigures,'all')
    figure; hold all;
    for i = 1:nSamples(1)
        plot(UGrid(:,i),zVec(2:end),'color',.85+[0 0 0],'HandleVisibility','off');
    end
    plot(meanVertProfile,zVec,'r--','displayName','Mean profile');
    plot(vertProfileFit,zVec,'-.','displayName','Fitted profile');
    xlabel('Wind speed (m/s)');
    ylabel('Height (m)');
    legend('-dynamicLegend','Location','nw');
    title('Vertical inflow profile');
end

end

