function [timeAvgData,inflowCurve,measurementSet] =  preprocessData_core(...
    sourceFolder,outputFile,ss, plotFigures)

% Define variables
xCutOff = ss.xCutOff;
yCutOff = ss.yCutOff;
zCutOff = ss.zCutOff;
vertSlice_Y = ss.vertSlices.Y;
vertSlice_Z = ss.vertSlices.Z;

%% Importing VTK files
disp(['1. Loading and time-averaging raw VTK data for .' sourceFolder]);
timeAvgData = importVTKfolder(sourceFolder,xCutOff,yCutOff,zCutOff);
        
%% Extract vertical inflow profile
disp('2. Vertical inflow profile.');
% upstreamPlane = find(regexp({timeAvgData.name},ss.inflowCurve.vtkFileformat));
strCmpInflow = regexp({timeAvgData.name},regexptranslate('wildcard',ss.inflowCurve.vtkFileformat));
upstreamPlane = find(~cellfun(@isempty,strCmpInflow));
if isempty(upstreamPlane)
    inflowCurve = []; % Empty
else
    [inflowCurve] = estimateInflowProfile(timeAvgData(upstreamPlane).cellCenters,...
        timeAvgData(upstreamPlane).UData,plotFigures);
    timeAvgData(upstreamPlane).type = 'vertical slice';
end


%% Extract measurements at downstream locations
if ss.vertSlices.sampleFlow
    disp('3a. Extracting the time-averaged flow data at prespecified points.');
    vertSlices = find(~cellfun('isempty',regexp({timeAvgData.name},...
        regexptranslate('wildcard',ss.vertSlices.vtkFileformat))) & ...
        cellfun(@isempty,strCmpInflow));
    
    if isempty(vertSlices)
        error('No vertical slices found.')
    end
    
    for i = vertSlices
        Fu = scatteredInterpolant(timeAvgData(i).cellCenters(:,2),...
                                 timeAvgData(i).cellCenters(:,3),...
                                 timeAvgData(i).UData,'linear');  
        Fx = scatteredInterpolant(timeAvgData(i).cellCenters(:,2),...
                                 timeAvgData(i).cellCenters(:,3),...
                                 timeAvgData(i).cellCenters(:,1),'linear');  
        timeAvgData(i).extrapolatedDataU = Fu(vertSlice_Y,vertSlice_Z);
        timeAvgData(i).extrapolatedDataX = Fx(vertSlice_Y,vertSlice_Z);
        timeAvgData(i).extrapolatedDataY = vertSlice_Y;
        timeAvgData(i).extrapolatedDataZ = vertSlice_Z;
        timeAvgData(i).type = 'vertical slice';
    end
end

% if ss.sampleVirtualTurbine
%     disp('3b. Extracting the time-averaged virtual power data at prespecified points.');
%     vertSlices = find(~cellfun('isempty',regexp({timeAvgData.name},...
%         regexptranslate('wildcard','U_slice_vertical_x*D'))));
% 
%     for i = vertSlices
%         F = scatteredInterpolant(timeAvgData(i).cellCenters(:,2),...
%                                  timeAvgData(i).cellCenters(:,3),...
%                                  timeAvgData(i).UData,'linear');  
%         
%         yRange = ss.virtTurb.yRange;
%         HH = ss.virtTurb.HH;
%         Drotor = ss.virtTurb.Drotor;     
%         nPoints = ss.virtTurb.sqrtNrPoints;
%         UAvg = zeros(1,length(yRange));
%         for ii = 1:length(yRange);
%             yTurb = ss.virtTurb.yRange(ii);
%             [yPts,zPts] = meshgrid(yTurb+Drotor*linspace(-.5,.5,nPoints),...
%                                    HH+Drotor*linspace(-.5,.5,nPoints));
%             idxInsideCircle = ((yPts-yTurb).^2 + (zPts-HH).^2) < Drotor^2/4;
%             yPts = yPts(idxInsideCircle); zPts = zPts(idxInsideCircle);
% %             figure; plot(yPts(:),zPts(:),'.'); axis equal
%             UAvg(ii) = mean(F(yPts,zPts));
% %             virtPower(ii) = 0.5*1.225*(.25*pi*Drotor^2)*UAvg(ii)^3*sampleStruct.virtTurb.powerFunc(UAvg(ii));
%         end
%         timeAvgData(i).virtTurb.UAvg = UAvg;
%         timeAvgData(i).virtTurb.Drotor = Drotor;
%         timeAvgData(i).virtTurb.Locs = [timeAvgData(i).cellCenters(1,1)*ones(size(yRange))',...
%                                        ss.virtTurb.yRange',HH*ones(size(yRange))'];
%         timeAvgData(i).virtTurb.yPts = yPts;                                
%         timeAvgData(i).virtTurb.zPts = zPts;
%     end
% end

%% Plotting time-averaged flow slices
disp('4. Plotting results (if applicable).');
if strcmp(plotFigures,'all')
    showFit(timeAvgData);
elseif strcmp(plotFigures,'hor')
    horIndx = find(~cellfun('isempty',regexp({timeAvgData.name},...
                   regexptranslate('wildcard','*horiz*'))));
    timeAvgData(horIndx).type = 'horizontal slice';
    showFit(timeAvgData(horIndx));
end


%% Put into FLORIS-compatible format
disp('5. Converting results into FLORIS-compatible format (if applicable).');
measurementSet = struct();
if ss.vertSlices.sampleFlow
    measurementSet.U = struct('x',[],'y',[],'z',[],'values',[],'stdev',[]);
    for i = 1:length(timeAvgData)
        measurementSet.U.x      = [measurementSet.U.x timeAvgData(i).extrapolatedDataX(:)'];
        measurementSet.U.y      = [measurementSet.U.y timeAvgData(i).extrapolatedDataY(:)'];
        measurementSet.U.z      = [measurementSet.U.z timeAvgData(i).extrapolatedDataZ(:)'];
        measurementSet.U.values = [measurementSet.U.values timeAvgData(i).extrapolatedDataU(:)'];
    end
    measurementSet.U.stdev = ones(size(measurementSet.U.values));
end

% if ss.sampleVirtualTurbine
%     measurementSet.virtTurb = struct('x',[],'y',[],'z',[],'Drotor',[],'yPts',[],'zPts',[],'UAvg',[]);
%     for i = vertSlices
%         measurementSet.virtTurb.x      = [measurementSet.virtTurb.x; timeAvgData(i).virtTurb.Locs(:,1)'];
%         measurementSet.virtTurb.y      = [measurementSet.virtTurb.y; timeAvgData(i).virtTurb.Locs(:,2)'];
%         measurementSet.virtTurb.z      = [measurementSet.virtTurb.z; timeAvgData(i).virtTurb.Locs(:,3)'];
% %         measurementSet.virtTurb.values = [measurementSet.virtP.values timeAvgData(i).virtTurb.P];
%         measurementSet.virtTurb.UAvg   = [measurementSet.virtTurb.UAvg; timeAvgData(i).virtTurb.UAvg];
%     end
%     measurementSet.virtTurb.Drotor = timeAvgData(i).virtTurb.Drotor;
%     measurementSet.virtTurb.yPts = yPts-mean(yPts);
%     measurementSet.virtTurb.zPts = zPts-mean(zPts);
% end

if strcmp(outputFile,'') == false
    save(outputFile,'timeAvgData','inflowCurve','measurementSet');
end
end




function [timeAvgData] = importVTKfolder(averagedVTKpath,xCutOff,yCutOff,zCutOff)
%% Load data
[fileNames] = dir(averagedVTKpath);

if length(fileNames) <= 0
    error(['The path ''' averagedVTKpath ''' does not contain any .vtk files.'])
end

for ji = 1:length(fileNames)
    rawData(ji).name = fileNames(ji).name;
    rawData(ji).path = [fileNames(ji).folder filesep fileNames(ji).name];
    
    [rawData(ji).dataType,rawData(ji).cellCenters, ...
        rawData(ji).cellData] = importVTK(rawData(ji).path);
    
    % Cut off all entries that do not fall inside (xCutOff, yCutOff, zCutOff)
    tmp_cutOff = ((rawData(ji).cellCenters(:,1) > xCutOff(1)) & (rawData(ji).cellCenters(:,1) <= xCutOff(2))) & ...
        ((rawData(ji).cellCenters(:,2) > yCutOff(1)) & (rawData(ji).cellCenters(:,2) <= yCutOff(2))) & ...
        ((rawData(ji).cellCenters(:,3) > zCutOff(1)) & (rawData(ji).cellCenters(:,3) <= zCutOff(2)));
    rawData(ji).cellCenters = rawData(ji).cellCenters(tmp_cutOff,:);
    rawData(ji).cellData    = rawData(ji).cellData(tmp_cutOff,:);
end
disp(['    Loaded ' num2str(length(rawData)) ' VTK files. Processing...']);


%% Process
disp('    Reformatting the VTK data.');
for ji = 1:length(rawData)
    timeAvgData(ji).name        = rawData(ji).name;
    timeAvgData(ji).cellCenters = rawData(ji).cellCenters;
    timeAvgData(ji).UData       = sqrt(rawData(ji).cellData(:,1).^2+rawData(ji).cellData(:,2).^2);
end

end