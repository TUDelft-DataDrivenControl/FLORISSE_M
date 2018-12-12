clear all

set(groot, 'defaultAxesTickLabelInterpreter','latex'); 
set(groot, 'defaultLegendInterpreter','latex');

yawRange = -30:10:30;
for i = 1:length(yawRange)
    yaw = yawRange(i);
    filename_piso = ['W:\OpenFOAM\bmdoekemeijer-2.4.0\simulationCases\WE2019\runs\piso_yaw' num2str(270-yaw) '\postProcessing\turbineOutput\0\generatorPower'];
    filename_wps = ['W:\OpenFOAM\bmdoekemeijer-2.4.0\simulationCases\WE2019\runs\wps_yaw' num2str(270-yaw) '\postProcessing\turbineOutput\20000\generatorPower'];
    [time_piso,data_piso] = importTurbFile(filename_piso);
    [time_wps,data_wps] = importTurbFile(filename_wps);
    time_piso = rem(time_piso,1e4);
    time_wps = rem(time_wps,1e4);
    PAvg_piso(i) = mean(data_piso(time_piso>600)) / 1.225; % Correction from SOWFA
    PAvg_wps(i) = mean(data_wps(time_wps>500)) / 1.225; % Correction from SOWFA
end

% Determine FLORIS power
addpath(genpath('../../FLORISSE_M'))
pisoDB = load('processedData_10MW/uniformInflow/yaw0.mat');
wpsDB  = load('processedData_10MW/turbInflow/yaw0.mat');
layout_piso = layout_class(struct('turbineType',dtu10mw_we2019,'locIf',{[0 0]}), 'dtu10mw_1turb');
layout_wps  = layout_class(struct('turbineType',dtu10mw_we2019,'locIf',{[0 0]}), 'dtu10mw_1turb');
% layout_piso = layout_class(struct('turbineType',dtu10mw,'locIf',{[0 0]}), 'dtu10mw_1turb');
% layout_wps  = layout_class(struct('turbineType',dtu10mw,'locIf',{[0 0]}), 'dtu10mw_1turb');
layout_piso.ambientInflow = ambient_inflow_myfunc('Interpolant', pisoDB.inflowCurve,'HH',119.0,'windDirection', 0.0, 'TI0', 0.000);
layout_wps.ambientInflow  = ambient_inflow_myfunc('Interpolant', wpsDB.inflowCurve, 'HH',119.0,'windDirection', 0.0, 'TI0', 0.057);                                          
controlSet_piso = control_set(layout_piso, 'yawAndRelPowerSetpoint');
controlSet_wps  = control_set(layout_wps,  'yawAndRelPowerSetpoint');
subModels = model_definition('','rans','','selfSimilar','','quadraticRotorVelocity','','crespoHernandez');                 
florisRunner_piso = floris(layout_piso, controlSet_piso, subModels);
florisRunner_wps  = floris(layout_wps, controlSet_wps, subModels);

for i = 1:length(yawRange)
    florisRunner_piso.clearOutput;
    florisRunner_wps.clearOutput;
    controlSet_piso.yawAngleWFArray = yawRange(i)*pi/180;
    controlSet_wps.yawAngleWFArray  = yawRange(i)*pi/180;
    florisRunner_piso.run;
    florisRunner_wps.run;
    PAvg_FLORIS_piso(i) = florisRunner_piso.turbineResults.power;
    PAvg_FLORIS_wps(i) = florisRunner_wps.turbineResults.power;
end
    
%% Plot
figure(1); clf; hold all;
grayAlpha = .5;
lineWidth = .8;
set(gcf,'Position',[616.2000 232.2000 339.2000 284]);
set(groot, 'defaultAxesTickLabelInterpreter','latex'); 
set(groot, 'defaultLegendInterpreter','latex');
plot(yawRange,PAvg_wps,'-','Color',[.0 .0 .0],'displayName','SOWFA ($U_\infty=8.2$ m/s, $I_{\infty}=5\%$)')
plot(yawRange,PAvg_FLORIS_wps, '--d','Color',[.0 .0 .0],'markerSize',4,'displayName','FLORIS ($U_\infty=8.2$ m/s, $I_{\infty}=5\%$)')
plot(yawRange,PAvg_piso,'-.','Color',grayAlpha*[1 1 1],'lineWidth',lineWidth,'displayName','SOWFA ($U_\infty=7.0$ m/s, $I_{\infty}=0\%$)')
plot(yawRange,PAvg_FLORIS_piso,'--x','Color',grayAlpha*[1 1 1],'lineWidth',lineWidth,'displayName','FLORIS ($U_\infty=7.0$ m/s, $I_{\infty}=0\%$)')
legend('-dynamicLegend','Location','s'); grid on;
ylim([0 4.5e6]);
box on;
xlim([yawRange(1) yawRange(end)])
ylabel('Power (W)','interpreter','latex')
xlabel('Yaw angle (deg)','interpreter','latex')

correctionFactor = [PAvg_piso./PAvg_FLORIS_piso PAvg_wps./PAvg_FLORIS_wps];
correctionFactorNoYaw = correctionFactor([yawRange==0 yawRange==0])
meanCorrFactorNoYaw = mean(correctionFactorNoYaw)
newGenEfficiency = meanCorrFactorNoYaw*layout_piso.uniqueTurbineTypes.genEfficiency

savePlot = false;
if savePlot
    addpath('D:\bmdoekemeijer\My Documents\MATLAB\WFSim\libraries\export_fig');
    export_fig 'WE2019_powerVsYaw.pdf' -transparent
end

%% NORMALIZED PLOT
normalizedPlot = false;
if normalizedPlot
    figure('Position',[612.2000 262.6000 317.6000 213.6000]);
    plot(yawRange,PAvg_piso/PAvg_piso(yawRange==0),'k-','displayName','SOWFA (TI=0%)')
    hold on
    plot(yawRange,PAvg_FLORIS_piso/PAvg_FLORIS_piso(yawRange==0),'k-.','displayName','FLORIS (TI=0%)')
    grid on
    xlim([-30 30])
    ylim([0.6 1])
    xlabel('Yaw angle (deg)','interpreter','latex')
    ylabel('Norm. power (-)','interpreter','latex')
    legend('-dynamicLegend','Location','s')
    addpath('D:\bmdoekemeijer\My Documents\MATLAB\WFSim\libraries\export_fig');
    export_fig 'singleTurbYawCurve.pdf' -dpdf -transparent
end

%% IMPORT TURBINE FILE
function [time,data] = importTurbFile(filename)
delimiter = ' ';
startRow = 1;
endRow = inf;

%% Read columns of data as text:
% For more information, see the TEXTSCAN documentation.
formatSpec = '%*s%s%*s%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to the format.
textscan(fileID, '%[^\n\r]', startRow(1)-1, 'WhiteSpace', '', 'ReturnOnError', false);
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'TextType', 'string', 'ReturnOnError', false, 'EndOfLine', '\r\n');
for block=2:length(startRow)
    frewind(fileID);
    textscan(fileID, '%[^\n\r]', startRow(block)-1, 'WhiteSpace', '', 'ReturnOnError', false);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'TextType', 'string', 'ReturnOnError', false, 'EndOfLine', '\r\n');
    for col=1:length(dataArray)
        dataArray{col} = [dataArray{col};dataArrayBlock{col}];
    end
end

%% Close the text file.
fclose(fileID);

%% Convert the contents of columns containing numeric text to numbers.
% Replace non-numeric text with NaN.
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = mat2cell(dataArray{col}, ones(length(dataArray{col}), 1));
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[1,2]
    % Converts text in the input cell array to numbers. Replaced non-numeric
    % text with NaN.
    rawData = dataArray{col};
    for row=1:size(rawData, 1)
        % Create a regular expression to detect and remove non-numeric prefixes and
        % suffixes.
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData(row), regexstr, 'names');
            numbers = result.numbers;
            
            % Detected commas in non-thousand locations.
            invalidThousandsSeparator = false;
            if numbers.contains(',')
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(numbers, thousandsRegExp, 'once'))
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Convert numeric text to numbers.
            if ~invalidThousandsSeparator
                numbers = textscan(char(strrep(numbers, ',', '')), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch
            raw{row, col} = rawData{row};
        end
    end
end


%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
raw(R) = {NaN}; % Replace non-numeric cells

%% Create output variable
time = cell2mat(raw(2:end, 1));
data = cell2mat(raw(2:end, 2));
end