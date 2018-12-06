function [timeAvgData,inflowCurve,measurementSet] =  preprocessSowfaData(...
    sourceFolder,outputFile,sampleStruct, plotFigures)

% Define variables
xCutOff = sampleStruct.xCutOff;
yCutOff = sampleStruct.yCutOff;
zCutOff = sampleStruct.zCutOff;
vertSlice_Y = sampleStruct.vertSlice_Y;
vertSlice_Z = sampleStruct.vertSlice_Z;

% sourceFolder = './rawData/yaw-30';
% outputFile   = 'yaw-30.mat';
% 
% % Show time-averaged slices
% plotFigures = false;
% xCutOff     = [-Inf Inf];  % [-Inf Inf]
% yCutOff     = [1000 2000]; % [-Inf Inf]
% zCutOff     = [0 200];     % [-Inf Inf]
% 
% % Sampling for downstream slices
% [vertSlice_Y,vertSlice_Z] = meshgrid(1250:25:1750,25:25:200);

%% Importing VTK files
disp(['1. Loading and time-averaging raw VTK data for .' sourceFolder]);
[rawData,timeAvgData] = importVTKfolder(sourceFolder,xCutOff,yCutOff,zCutOff);

%% Extract vertical inflow profile
disp('2. Vertical inflow profile.');
upstreamPlane = find(strcmp({timeAvgData.name},'U_slice_vertical_x500.vtk'));
[inflowCurve] = estimateInflowProfile(timeAvgData(upstreamPlane).cellCenters,...
    timeAvgData(upstreamPlane).UData,plotFigures);


%% Extract measurements at downstream locations
if sampleStruct.sampleFlow
    disp('3a. Extracting the time-averaged flow data at prespecified points.');
    vertSlices = find(~cellfun('isempty',regexp({timeAvgData.name},...
        regexptranslate('wildcard','U_slice_vertical_x*D'))));

    for i = vertSlices
        F = scatteredInterpolant(timeAvgData(i).cellCenters(:,2),...
                                 timeAvgData(i).cellCenters(:,3),...
                                 timeAvgData(i).UData,'linear');  
        timeAvgData(i).extrapolatedDataU = F(vertSlice_Y,vertSlice_Z);
        timeAvgData(i).extrapolatedDataX = timeAvgData(i).cellCenters(1,1)*...
            ones(size(vertSlice_Y));
        timeAvgData(i).extrapolatedDataY = vertSlice_Y;
        timeAvgData(i).extrapolatedDataZ = vertSlice_Z;
    end
end

if sampleStruct.sampleVirtualTurbine
    disp('3b. Extracting the time-averaged virtual power data at prespecified points.');
    vertSlices = find(~cellfun('isempty',regexp({timeAvgData.name},...
        regexptranslate('wildcard','U_slice_vertical_x*D'))));

    for i = vertSlices
        F = scatteredInterpolant(timeAvgData(i).cellCenters(:,2),...
                                 timeAvgData(i).cellCenters(:,3),...
                                 timeAvgData(i).UData,'linear');  
        
        yRange = sampleStruct.virtTurb.yRange;
        HH = sampleStruct.virtTurb.HH;
        Drotor = sampleStruct.virtTurb.Drotor;     
        nPoints = sampleStruct.virtTurb.sqrtNrPoints;
        UAvg = zeros(1,length(yRange));
        for ii = 1:length(yRange);
            yTurb = sampleStruct.virtTurb.yRange(ii);
            [yPts,zPts] = meshgrid(yTurb+Drotor*linspace(-.5,.5,nPoints),...
                                   HH+Drotor*linspace(-.5,.5,nPoints));
            idxInsideCircle = ((yPts-yTurb).^2 + (zPts-HH).^2) < Drotor^2/4;
            yPts = yPts(idxInsideCircle); zPts = zPts(idxInsideCircle);
%             figure; plot(yPts(:),zPts(:),'.'); axis equal
            UAvg(ii) = mean(F(yPts,zPts));
%             virtPower(ii) = 0.5*1.225*(.25*pi*Drotor^2)*UAvg(ii)^3*sampleStruct.virtTurb.powerFunc(UAvg(ii));
        end
        timeAvgData(i).virtTurb.UAvg = UAvg;
        timeAvgData(i).virtTurb.Drotor = Drotor;
        timeAvgData(i).virtTurb.Locs = [timeAvgData(i).cellCenters(1,1)*ones(size(yRange))',...
                                       sampleStruct.virtTurb.yRange',HH*ones(size(yRange))'];
        timeAvgData(i).virtTurb.yPts = yPts;                                
        timeAvgData(i).virtTurb.zPts = zPts;
    end
end

%% Plotting time-averaged flow slices
disp('4. Plotting results (if applicable).');
if strcmp(plotFigures,'all')
    showFit(timeAvgData);
elseif strcmp(plotFigures,'hor')
    horIndx = find(~cellfun('isempty',regexp({timeAvgData.name},...
                   regexptranslate('wildcard','*horiz*'))));
    showFit(timeAvgData(horIndx));
end


%% Put into FLORIS-compatible format
disp('5. Converting results into FLORIS-compatible format (if applicable).');

if sampleStruct.sampleFlow
    measurementSet.U = struct('x',[],'y',[],'z',[],'values',[],'stdev',[]);
    for i = 1:length(timeAvgData)
        measurementSet.U.x      = [measurementSet.U.x timeAvgData(i).extrapolatedDataX(:)'];
        measurementSet.U.y      = [measurementSet.U.y timeAvgData(i).extrapolatedDataY(:)'];
        measurementSet.U.z      = [measurementSet.U.z timeAvgData(i).extrapolatedDataZ(:)'];
        measurementSet.U.values = [measurementSet.U.values timeAvgData(i).extrapolatedDataU(:)'];
    end
    measurementSet.U.stdev = ones(size(measurementSet.U.values));
end

if sampleStruct.sampleVirtualTurbine
    measurementSet.virtTurb = struct('x',[],'y',[],'z',[],'Drotor',[],'yPts',[],'zPts',[],'UAvg',[]);
    for i = vertSlices
        measurementSet.virtTurb.x      = [measurementSet.virtTurb.x; timeAvgData(i).virtTurb.Locs(:,1)'];
        measurementSet.virtTurb.y      = [measurementSet.virtTurb.y; timeAvgData(i).virtTurb.Locs(:,2)'];
        measurementSet.virtTurb.z      = [measurementSet.virtTurb.z; timeAvgData(i).virtTurb.Locs(:,3)'];
%         measurementSet.virtTurb.values = [measurementSet.virtP.values timeAvgData(i).virtTurb.P];
        measurementSet.virtTurb.UAvg   = [measurementSet.virtTurb.UAvg; timeAvgData(i).virtTurb.UAvg];
    end
    measurementSet.virtTurb.Drotor = timeAvgData(i).virtTurb.Drotor;
    measurementSet.virtTurb.yPts = yPts-mean(yPts);
    measurementSet.virtTurb.zPts = zPts-mean(zPts);
end

if strcmp(outputFile,'') == false
    save(outputFile,'timeAvgData','inflowCurve','measurementSet');
end
end




function [rawData,timeAvgData] = importVTKfolder(sliceDataInstnPath,xCutOff,yCutOff,zCutOff)
%% Load raw data
[folderNames] = dir(sliceDataInstnPath);

for i = 1:length(folderNames)-2
    tmp_folderName = [folderNames(i+2).folder filesep folderNames(i+2).name];
    tmp_fileNames  = dir(tmp_folderName);
    
    for ji = 1:length(tmp_fileNames)-2
        rawData(i,ji).name = tmp_fileNames(ji+2).name;
        rawData(i,ji).path = [tmp_fileNames(ji+2).folder filesep tmp_fileNames(ji+2).name];
        
        %         disp(['Importing data, t = ' folderNames(i+2).name ' s, case: ' rawData(i,ji).name '.']);
        [rawData(i,ji).dataType,rawData(i,ji).cellCenters, ...
            rawData(i,ji).cellData] = importVTK(rawData(i,ji).path);
        
        % Cut off all entries that do not fall inside (xCutOff, yCutOff, zCutOff)
        tmp_cutOff = ((rawData(i,ji).cellCenters(:,1) > xCutOff(1)) & (rawData(i,ji).cellCenters(:,1) <= xCutOff(2))) & ...
            ((rawData(i,ji).cellCenters(:,2) > yCutOff(1)) & (rawData(i,ji).cellCenters(:,2) <= yCutOff(2))) & ...
            ((rawData(i,ji).cellCenters(:,3) > zCutOff(1)) & (rawData(i,ji).cellCenters(:,3) <= zCutOff(2)));
        rawData(i,ji).cellCenters = rawData(i,ji).cellCenters(tmp_cutOff,:);
        rawData(i,ji).cellData    = rawData(i,ji).cellData(tmp_cutOff,:);
    end
end
disp(['    Loaded ' num2str(size(rawData,1)) 'x' num2str(size(rawData,2)) ' VTK files. Processing...']);


%% Time averaging
disp('    Time-averaging the raw VTK data.');
for ji = 1:size(rawData,2)
    timeAvgData(ji).name        = rawData(1,ji).name;
    timeAvgData(ji).cellCenters = rawData(1,ji).cellCenters;
    timeAvgData(ji).cellData    = rawData(1,ji).cellData./size(rawData,1);
    for i = 2:size(rawData,1)
        timeAvgData(ji).cellData = timeAvgData(ji).cellData + ...
            rawData(i,ji).cellData./size(rawData,1);
    end
    timeAvgData(ji).UData = sqrt(timeAvgData(ji).cellData(:,1).^2+timeAvgData(ji).cellData(:,2).^2);
end

end