function SCO = importSuperCONOUT(filename)
%Paul Fleming, Pieter Gebraad
%ImportSuperCONOUT
%This script returns a structure which is the data from a given
%superCONOUT.csv file


if nargin < 1 %if no filename provided assume it is superCONOUT.csv
    filename = 'superCONOUT.csv';
end

%Import header
fid = fopen(filename, 'r');
tline = fgetl(fid);
Names(1,:) = regexp(tline, '\,', 'split');
Names = Names(1,1:end-1);

%% Read columns of data according to format string.
delimiter = ',';
startRow = 2;
endRow = inf;

if verLessThan('matlab', '7.13')
    % fix for MATLAB versions prior to R2011b
    disp 'using dlmread for MATLAB versions prior to R2011b'
    fclose(fid);
    dat = dlmread(filename,',',startRow-1,0); 
    dat = dat(:,1:end-1);
else 
    formatSpec=[repmat('%f ',1,length(Names)),'%*[^\n]'];
    frewind(fid);
    dat = textscan(fid, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines', startRow(1)-1, 'ReturnOnError', false);
    for block=2:length(startRow)
        frewind(fid);
        dataArrayBlock = textscan(fid, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines', startRow(block)-1, 'ReturnOnError', false);
        for col=1:length(dat)
            dat{col} = [dat{col};dataArrayBlock{col}];
        end
    end
    fclose(fid);
    dat = cell2mat(dat);
end

%Determine the number of turbines
SCO.numTurb = sscanf(Names{end},'T%d:');

%Determine the number of sensors
SCO.numSens = (length(Names) - 1)/SCO.numTurb;

%Extract a list of sensor names
SCO.sensorList = {};
for s = 1:SCO.numSens
    SCO.sensorList{s} = Names{2 + (s-1) * SCO.numTurb}(4:end);
end

%Extract time
SCO.time = dat(:,1);

%Now place data in a seperate matrix for each tubrine
for t = 1:SCO.numTurb
    for s = 1:SCO.numSens
        SCO.data{t}(:,s) = dat(:, ( (s - 1) * SCO.numTurb) + t + 1);
    end
end

