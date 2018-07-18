clear all; close all; clc;
addpath(genpath('../FLORISSE_M'));

% - - - - - - - - - - - - -  USER SET UP  - - - - - - - - - - - - - -  %
databaseOutput = 'LUT_2turb_yaw.csv'; % Specify database output filename (do not forget '.mat' at the end)
forceAppend    = false;    % Force write (skips safety check. Useful for HPC computations)
WD_range = [-177:3:180];   % Span of wind directions (degrees)
WS_range = [5.0 8.0 12.0]; % Span of wind speeds (m/s)

probablisticOptimization = false; % Optimize with uncertainty in WD
WD_std  = 5.*pi/180;    % Standard dev. in radians (if probablisticOptimization == 1)
WD_N    = 5;            % N.o. sample points for prob. dist. (if probablisticOptimization == 1)
     
% NOTE: Do not forget to update the FLORIS settings at line 94 and onwards.



% - - - - - - - - - - - -  CORE OPERATIONS  - - - - - - - - - - - - -  %
% Generate all combinations of WS and WDs
[X2,X1] = ndgrid(WS_range,WD_range);
xTests  = [X1(:) X2(:)]; % Generate test queue

% Load existing or initialize new database file
if exist(databaseOutput,'file')
    if ~forceAppend
        if ~strcmp(questdlg(['Existing database found. Will simulate all non-existent cases and append to file ''' databaseOutput '''. Continue?']),'Yes')
            error(['Exiting run: cannot append to file ' databaseOutput '. Please delete or move the existing file.']);
        end
    end
    
    % Remove all duplicate runs from test queue
    [dataArray,noLinesInit] = readPastLUTData(databaseOutput);
    prevRuns = ismember(xTests,dataArray(:,[3 4]),'rows');
    xTests = xTests(~prevRuns,:); % Exclude all pre-existing tests
    disp(['Skipping ' num2str(sum(prevRuns)) ' cases (already existent in database).']);
    clear  dataArray    
else
    noLinesInit = 1;
    disp(['Creating new database output file with name ''' databaseOutput '''.']);
    dlmwrite(databaseOutput,sprintf('Pbl(W) \t Popt(W) \t WD(deg) \t WS(m/s) \t xopt(deg)'),'delimiter','','newline','pc');
end

% Perform actual runs (in parallel, if possible)
startTime = tic;
N = size(xTests,1);
disp(['Batch size: ' num2str(N) ' remaining optimization cases.']); disp(' ');
parfor i = 1:N
    disp(sprintf([datestr(rem(now,1)) ' __ Generating LUT entries for case: [%05.1f, %04.1f].'],xTests(i,1),xTests(i,2)));
    
    % Give periodic updates on current progress and ETA
    if randi(10) == 1  % Randomly, approx. every 10 times
        [~,noLinesCurrent] = readPastLUTData(databaseOutput);
        noCasesSimulated   = noLinesCurrent - noLinesInit;
        ETA = (size(xTests,1)-noCasesSimulated)*toc(startTime)/noCasesSimulated; % Update ETA
        disp(sprintf([datestr(rem(now,1)) ' __ Progress. Status: %05.2f%%. \t ETA: %.f mins.'],...
                                                       100*noCasesSimulated/size(xTests,1),ETA/60));
    end
    
    florisRunnerTmp = generateFLORISobject(xTests(i,1),xTests(i,2));    
    if probablisticOptimization
        % Robust optimization (over a prob. dist. of wind directions)
        [xopt,Pbl,Popt] = optimizeControlSettingsRobust(florisRunnerTmp, ...
                                                  'Yaw Optimizer', 1, ...
                                                  'Pitch Optimizer', 0, ...
                                                  'Axial induction Optimizer', 0,...
                                                  WD_std, WD_N, false); % silent execution       
    else
        % Deterministic optimization (over a single wind direction)
        [xopt,Pbl,Popt] = optimizeControlSettings(florisRunnerTmp, ...
                                                  'Yaw Optimizer', 1, ...
                                                  'Pitch Optimizer', 0, ...
                                                  'Axial induction Optimizer', 0,...
                                                  false); % silent execution
    end
        
    % Write output to the csv
    dlmwrite(databaseOutput,[Pbl Popt xTests(i,:) xopt*180/pi],'delimiter','\t','newline','pc','-append');
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
function florisObj = generateFLORISobject(WD,WS)
    layout = generic_2_turb; % Instantiate a layout without ambientInflow conditions
    refheight = layout.uniqueTurbineTypes(1).hubHeight; % Use the height from the first turbine type as reference height for theinflow profile
    layout.ambientInflow = ambient_inflow_log('PowerLawRefSpeed', 8,  'PowerLawRefHeight', refheight, ...
        'windDirection', 0,  'TI0', .05);
    controlSet = control_set(layout, 'axialInduction'); % Make a controlObject for this layout
    subModels = model_definition('deflectionModel',      'rans',...
        'velocityDeficitModel', 'selfSimilar',...
        'wakeCombinationModel', 'quadraticRotorVelocity',...
        'addedTurbulenceModel', 'crespoHernandez');
    
    % Create FLORIS instant
    florisObj = floris(layout, controlSet, subModels); 
    
    % Overwrite ambient conditions
    florisObj.layout.ambientInflow.windDirection = WD*pi/180;
    florisObj.layout.ambientInflow.Vref          = WS;    
end




% Example function for plotting:

% % Plot optimal yaw angles and expected power gain over WD
% % Mat  = [LUT2turbyaw.Variables];  %% Use 'uiopen' to load the .csv file
% % Pbl  = Mat(:,1); 
% % Popt = Mat(:,2); 
% % WD   = Mat(:,3); 
% % WS   = Mat(:,4); 
% % yaw  = Mat(:,[5:end]);
% % [WD_sorted,I_sort] = sort(WD);
% % WS_sorted  = WS(I_sort);
% % yaw_sorted = yaw(I_sort,:);
% % figure;
% % subplot(2,1,1);
% % plot(WD_sorted,yaw_sorted,'.');
% % grid on; xlabel('Wind direction (deg)');
% % ylabel('Yaw angle (deg)');
% % legend('Turbine 1','Turbine 2');
% % subplot(2,1,2);
% % plot(WD_sorted,Popt(I_sort)./Pbl(I_sort));
% % grid on; xlabel('Wind direction (deg)');
% % ylabel('P_{opt}/P_{bl} (-)');