% Specify database output filename (do not forget '.mat' at the end)
databaseOutput = 'LUT_9turb_yaw.mat';
WD_range = [-pi:pi/60:pi]; % Span of wind directions
WS_range = [5:0.5:15];     % Span of wind speeds

probablisticOptimization = true;
WD_std  = 5.*pi/180;
WD_N    = 5;

% Setup a FLORIS model and wind farm case
layout = generic_9_turb; % Instantiate a layout without ambientInflow conditions
refheight = layout.uniqueTurbineTypes(1).hubHeight; % Use the height from the first turbine type as reference height for theinflow profile
layout.ambientInflow = ambient_inflow_log('PowerLawRefSpeed', 8,  'PowerLawRefHeight', refheight, ...
                                          'windDirection', 0,  'TI0', .05);
controlSet = control_set(layout, 'axialInduction'); % Make a controlObject for this layout
subModels = model_definition('deflectionModel',      'rans',...
                             'velocityDeficitModel', 'selfSimilar',...
                             'wakeCombinationModel', 'quadraticRotorVelocity',...
                             'addedTurbulenceModel', 'crespoHernandez');                         
florisRunner = floris(layout, controlSet, subModels);

% Generate all combinations of WS and WDs
[X2,X1] = ndgrid(WS_range,WD_range);
xTests  = [X1(:) X2(:)]; % Generate test queue

% Load/initialize database file
if exist(databaseOutput,'file')
    loadedDatabase = load(databaseOutput);
    if isequal(florisRunner,loadedDatabase.florisRunner)
        disp('Existing file seems to match. Continuing run.');
    else
        disp('Settings with existing file do not match! Continue run?');
        keyboard;
    end
        databaseLUT = loadedDatabase.databaseLUT;
        
        % Remove all duplicate runs from test queue
        prevRuns = ismember(xTests,databaseLUT(:,[1 2]),'rows');
        xTests = xTests(~prevRuns,:); 
        disp(['Skipping ' num2str(sum(prevRuns)) ' cases (already exists in the database).']);

        clear loadedDatabase
else
    databaseLUT = [];
    disp(['No existing file found. Creating new file with name ''' databaseOutput '''.']);
    save(databaseOutput,'florisRunner','databaseLUT');
end




startTime = tic;
ETA       = Inf;
for i = 1:size(xTests,1)
    disp([num2str(100*i/size(xTests,1)) '%. Generating LUT entries for case: [' num2str(xTests(i,1)) ', ' num2str(xTests(i,2)) ']. ETA: ' num2str(ETA) ' s.']);
    florisRunner.layout.ambientInflow.windDirection = xTests(i,1);
    florisRunner.layout.ambientInflow.Vref          = xTests(i,2);
    
    if probablisticOptimization
        % Robust
        [xopt,Pbl,Popt] = optimizeControlSettingsRobust(florisRunner, ...
                                                  'Yaw Optimizer', 1, ...
                                                  'Pitch Optimizer', 0, ...
                                                  'Axial induction Optimizer', 0,...
                                                  WD_std, WD_N, false); % silent execution       
    else
    % Deterministic
        [xopt,Pbl,Popt] = optimizeControlSettings(florisRunner, ...
                                                  'Yaw Optimizer', 1, ...
                                                  'Pitch Optimizer', 0, ...
                                                  'Axial induction Optimizer', 0,...
                                                  false); % silent execution
    end
    
    databaseLUT = [databaseLUT; Pbl Popt xTests(i,:) xopt];
    save(databaseOutput,'databaseLUT','-append');
    ETA = (size(xTests,1)-i)*toc(startTime)/i;
end