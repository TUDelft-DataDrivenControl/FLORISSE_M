function [databaseLUT] = importYawLUT(inputfilename)
addpath('bin')

if exist(inputfilename) ~= 2
    error(['File ''' inputfilename ''' not found.'])
end

% Import data
LUT = importLUTfile(inputfilename);
dataMat = sortrows(LUT.Variables,[1 2 3 4]);
dataMat = dataMat(:,[1 2 3 4 7:end]); % Remove Pbl and Popt

% Remove NaN entries from dataMat
nnancolumns = sum(isnan(dataMat(1,:)));
dataMat = dataMat(:,1:(end-nnancolumns));

% Determine grid
databaseLUT.TI_range = unique(LUT.TI)';
databaseLUT.WS_range = unique(LUT.WSms)';
databaseLUT.WD_range = unique(LUT.WDdeg)';
databaseLUT.WD_std_range = unique(LUT.WDstddeg)';
databaseLUT.nTI = length(databaseLUT.TI_range);
databaseLUT.nWS = length(databaseLUT.WS_range);
databaseLUT.nWD = length(databaseLUT.WD_range);
databaseLUT.nWDstd = length(databaseLUT.WD_std_range);

% Rearrange data
nTurbs = size(dataMat,2)-4;
for TIi = 1:databaseLUT.nTI
    dataMatSubsetTI = dataMat(dataMat(:,1) == databaseLUT.TI_range(TIi),:);
    for WSi = 1:databaseLUT.nWS
        dataMatSubsetTiWS = dataMatSubsetTI(dataMatSubsetTI(:,2) == databaseLUT.WS_range(WSi),:);
        for WDi = 1:databaseLUT.nWD
            for WDstdi = 1:databaseLUT.nWDstd
                yawAngles = dataMatSubsetTiWS(dataMatSubsetTiWS(:,3) == databaseLUT.WD_range(WDi) & ...
                                              dataMatSubsetTiWS(:,4) == databaseLUT.WD_std_range(WDstdi),5:end);
                for i = 1:nTurbs
                    databaseLUT.yawT{i}(TIi,WSi,WDi,WDstdi) = yawAngles(i);
                end
            end
        end
    end
end


%% Import function
function LUTsediniyaw = importLUTfile(filename)
%% Initialize variables.
delimiter = '\t';
startRow = 2;
endRow = inf;

%% Format for each line of text:
formatSpec = [repmat('%f',1,15) '%[^\n\r]']; %'%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to the format.
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines', startRow(1)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
for block=2:length(startRow)
    frewind(fileID);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines', startRow(block)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
    for col=1:length(dataArray)
        dataArray{col} = [dataArray{col};dataArrayBlock{col}];
    end
end

%% Close the text file.
fclose(fileID);

%% Create output variable
LUTsediniyaw = table(dataArray{1:end-1}, 'VariableNames', {'TI','WSms','WDdeg','WDstddeg','Pbl','Popt','x1','x2','x3','x4','x5','x6','x7','x8','x9'});
end
end