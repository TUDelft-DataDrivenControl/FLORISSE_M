function [databaseLUT] = importYawLUT(inputfilename)
addpath('bin')

if exist(inputfilename) ~= 2
    error(['File ''' inputfilename ''' not found.'])
end

% Import data
LUT = importLUTfile(inputfilename);
dataMat = sortrows(LUT.Variables,[3 2 1]);
dataMat = dataMat(:,[1 2 3 6:end]); % Remove Pbl and Popt

% Determine grid
databaseLUT.WS_range = unique(LUT.WSms)';
databaseLUT.WD_range = unique(LUT.WDdeg)';
databaseLUT.TI_range = unique(LUT.TI)';
databaseLUT.nWS = length(databaseLUT.WS_range);
databaseLUT.nWD = length(databaseLUT.WD_range);
databaseLUT.nTI = length(databaseLUT.TI_range);

% Rearrange data
nTurbs = size(dataMat,2)-3;
for TIi = 1:databaseLUT.nTI
    for WSi = 1:databaseLUT.nWS
        yawAngles = dataMat(dataMat(:,2) == databaseLUT.WS_range(WSi) & ...
                            dataMat(:,3) == databaseLUT.TI_range(TIi),4:end);
        for i = 1:nTurbs
%             databaseLUT.yawT{i} = nan*zeros(databaseLUT.nTI,databaseLUT.nWS,databaseLUT.nWD);
            databaseLUT.yawT{i}(TIi,WSi,:) = yawAngles(:,i);
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
formatSpec = '%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]';

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
LUTsediniyaw = table(dataArray{1:end-1}, 'VariableNames', {'WDdeg','WSms','TI','Pbl','Popt','x1','x2','x3','x4','x5','x6'});
end
end