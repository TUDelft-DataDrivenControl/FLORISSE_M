clc
clear
% Delete double entries (for some reason)
[dataArray,noLines] = readPastLUTData('LUT_6turb_yaw.csv');
noColumns = find(isnan(dataArray(1,:)))-1;
dataArray = dataArray(:,1:noColumns);

% Organize by uniqueness of first 4 entries
[C,ia,ic] = unique(dataArray(:,1:4),'rows');
dataArray = dataArray(ia,:);

% Write to new LUT file
databaseOutput = 'LUT_6turb_yaw.clean.csv';
dlmwrite(databaseOutput,sprintf('TI(-) \t WS(m/s) \t WD(deg) \t WD_std(deg) \t Pbl (W) \t Popt \t xopt(deg, CW positive)'),'delimiter','','newline','pc');
for i = 1:size(dataArray,1)
    dlmwrite(databaseOutput,dataArray(i,:),'delimiter','\t','newline','pc','-append');
end

% Function to read *.csv file
function [dataArray,noLines] = readPastLUTData(filenameIn)
fileID = fopen(filenameIn,'r');
dataArray = textscan(fileID, [repmat('%f',1,100) '%[^\n\r]'], 'Delimiter', '\t', 'TextType', 'string', 'HeaderLines' ,1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
dataArray = [dataArray{1:end-1}]; % Convert to matrix
noLines = size(dataArray,1)+1;
fclose(fileID);
end