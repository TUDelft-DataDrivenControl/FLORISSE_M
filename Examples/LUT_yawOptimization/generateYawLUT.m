%
% GENERATEYAWLUT.M
% Summary: This script demonstrates how one could use FLORIS to generate a
% set of optimal yaw settings of each turbine, for a range of ambient
% conditions. In this specific example, the yaw angles are optimized for a
% 2-turbine case over a range of wind directions and wind speeds. The
% results are saved to a .csv "look-up table" (LUT) style file.
%

clear all; close all; clc;
addpath(genpath('../../FLORISSE_M'));

% - - - - - - - - - - - - -  USER SET UP  - - - - - - - - - - - - - -  %
databaseOutput = 'LUT_6turb_yaw.csv'; % Specify database output filename (do not forget '.mat' at the end)
forceAppend    = false;    % Force write (skips safety check. Useful for HPC computations)
WD_range = [0.:1.:90.]; % Span of wind directions (degrees)
WS_range = [8.0];  % Span of wind speeds (m/s)
TI_range = [0.02 0.07 0.12 0.17]; % Span of TIs (-)

% - - - - - - - - - - - -  CORE OPERATIONS  - - - - - - - - - - - - -  %
% Generate all combinations of WSs, WDs and TIs
[X1,X2,X3] = ndgrid(WD_range,WS_range,TI_range);
xTests  = [X1(:) X2(:) X3(:)]; % Generate test queue

% Load existing or initialize new database file
if exist(databaseOutput,'file')
    if ~forceAppend
        if ~strcmp(questdlg(['Existing database found. Will simulate all non-existent cases and append to file ''' databaseOutput '''. Continue?']),'Yes')
            error(['Exiting run: cannot append to file ' databaseOutput '. Please delete or move the existing file.']);
        end
    end
    
    % Remove all duplicate runs from test queue
    [dataArray,noLinesInit] = readPastLUTData(databaseOutput);
    prevRuns = ismember(xTests,dataArray(:,[1:size(xTests,2)]),'rows');
    xTests = xTests(~prevRuns,:); % Exclude all pre-existing tests
    disp(['Skipping ' num2str(sum(prevRuns)) ' cases (already existent in database).']);
    clear  dataArray
else
    noLinesInit = 1;
    disp(['Creating new database output file with name ''' databaseOutput '''.']);
    %     dlmwrite(databaseOutput,sprintf('WD(deg) \t WS(m/s) \t TI (-) \t Pbl(W) \t Popt(W) \t xopt(deg)'),'delimiter','','newline','pc');
    dlmwrite(databaseOutput,sprintf('WD(deg) \t WS(m/s) \t TI (-) \t Pbl (W) \t Popt \t xopt(deg, CW positive)'),'delimiter','','newline','pc');
end

% Perform actual runs (in parallel, if possible)
startTime = tic;
N = size(xTests,1);
disp(['Batch size: ' num2str(N) ' remaining optimization cases.']); disp(' ');
if isunix % In our case: Linux HPC facility
    parpool(40)
end
parfor i = 1:N
% for i = 1:N
    disp(sprintf([datestr(rem(now,1)) ' __ Generating LUT entries for case: [%05.1f, %04.1f, %04.3f].'],xTests(i,1),xTests(i,2),xTests(i,3)));    
    florisRunnerTmp = generateFLORISobject(xTests(i,1),xTests(i,2),xTests(i,3));
    try
        
        % Choose which turbines to optimize (smart optimization)
        if xTests(i,1) < 10 % Symmetry in the rows: T1 = T2, T3 = T4, T5 = T6 = 0
            turbsToOptimize = [1 3];
        elseif xTests(i,1) < 20 % Only interaction with T1 on T6
            turbsToOptimize = [1];
        elseif xTests(i,1) < 45 % Only interaction with T1 and T3 on T4 and T6
            turbsToOptimize = [1 3];
        else
            turbsToOptimize = [1]; % Symmetry in columns: T1 = T3 = T5, T2 = T4 = T6 = 0
        end
        
        % Deterministic optimization (over a single wind direction)
        [xopt,Pbl,Popt] = optimizeControlSettingsSimpleGS(florisRunnerTmp,'Yaw', 1,'Pitch', 0,'AxInd', 0,turbsToOptimize, false); % silent execution
        
        yawAnglesOpt = zeros(1,florisRunnerTmp.layout.nTurbs);
        yawAnglesOpt(turbsToOptimize) = xopt;
        
        % Implement symmetry
        if xTests(i,1) < 10 % Symmetry in the rows: T1 = T2, T3 = T4, T5 = T6 = 0
            yawAnglesOpt(2) = yawAnglesOpt(1);
            yawAnglesOpt(4) = yawAnglesOpt(3);
        elseif xTests(i,1) < 20 % Only interaction with T1 on T6
            % do nothing, no symmetry exploited
        elseif xTests(i,1) < 45 % Only interaction with T1 and T3 on T4 and T6
            % do nothing, no symmetry exploited
        else
            yawAnglesOpt(3) = yawAnglesOpt(1);
            yawAnglesOpt(5) = yawAnglesOpt(1);
        end
        
        if Pbl >= Popt - eps | isnan(Popt) | isnan(Pbl) % no improvement
            xopt = xopt * 0.0; % Set to greedy
            disp('No noticeable improvement. Setting xopt to greedy.')
        end
                
        % Write output to the csv
%         dlmwrite(databaseOutput,[xTests(i,:) Pbl Popt round(-xopt*180/pi,1)],'delimiter','\t','newline','pc','-append');
        dlmwrite(databaseOutput,[xTests(i,:) Pbl Popt round(yawAnglesOpt*180/pi,1)],'delimiter','\t','newline','pc','-append');
    catch
        disp('Caught an error. Writing NaNs to this entry.')
        dlmwrite(databaseOutput,[xTests(i,:) NaN],'delimiter','\t','newline','pc','-append');
    end
end
disp([datestr(rem(now,1)) ' __ Finished ' num2str(N) ' runs. Terminating LUT generation.']);



% - - - - - - - - - - - - ADDITIONAL FUNCTIONS - - - - - - - - - - - - - -
% Function to read *.csv file
function [dataArray,noLines] = readPastLUTData(filenameIn)
fileID = fopen(filenameIn,'r');
dataArray = textscan(fileID, '%f%f%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]', 'Delimiter', '\t', 'TextType', 'string', 'HeaderLines' ,1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
dataArray = [dataArray{1:end-1}]; % Convert to matrix
noLines = size(dataArray,1)+1;
fclose(fileID);
end

% Function to set-up FLORIS object
function florisObj = generateFLORISobject(WD,WS,TI0)
    layout = WE19_6_turb(); % Instantiate a layout without ambientInflow conditions
    refheight = layout.uniqueTurbineTypes(1).hubHeight; % Use the height from the first turbine type as reference height for theinflow profile
    layout.ambientInflow = ambient_inflow_log('PowerLawRefSpeed', 8,  'PowerLawRefHeight', refheight, ...
        'windDirection', 0,  'TI0', .05);
    controlSet = control_set(layout, 'yaw'); % Make a controlObject for this layout
    subModels = model_definition('deflectionModel','rans',...
        'velocityDeficitModel', 'selfSimilar',...
        'wakeCombinationModel', 'quadraticRotorVelocity',...
        'addedTurbulenceModel', 'crespoHernandez');
    
    % Set FLORIS model parameters to the values found by offline calibration
    subModels.modelData.TIa = 7.841152377297512;
    subModels.modelData.TIb = 4.573750238535804;
    subModels.modelData.TIc = 0.431969955023207;
    subModels.modelData.TId = -0.246470535856333;
    subModels.modelData.ad = 0.001117233213458;
    subModels.modelData.alpha = 1.087617055657293;
    subModels.modelData.bd = -0.007716521497980;
    subModels.modelData.beta = 0.221944783863084;
    subModels.modelData.ka = 0.536850894208880;
    subModels.modelData.kb = -0.000847912134732;
    
    % Create FLORIS instant
    florisObj = floris(layout, controlSet, subModels); 
    
    % Overwrite ambient conditions
    florisObj.layout.ambientInflow.windDirection = WD*pi/180;
    florisObj.layout.ambientInflow.Vref          = WS;
    florisObj.layout.ambientInflow.TI0           = TI0;
    
    % Set default yaw angles to greedy
    florisObj.controlSet.yawAngleWFArray = zeros(1,layout.nTurbs);
end