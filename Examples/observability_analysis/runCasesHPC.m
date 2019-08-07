addpath('bin')
addpath('layouts')
addpath(genpath('../../FLORISSE_M'))

%% Setup
layouts{1} = sns_2turb_layout();
layouts{2} = sns_6turb_layout();
layouts{3} = sns_8turb_layout();

trueRange = struct(...
    'WD', linspace(0,2*pi,61),... % Discretization of 360 degrees wind rose. Recommended to be uneven number.
    'WS', [6.5 9.0 11.4 14.5],... % True wind speed [m/s]
    'TI', [0.065 0.065:0.03:0.16]); % True turbulence intensity [%]

relSearchRange1 = struct(...
    'WD', linspace(-20.,20.,51) * (pi/180),... % Search range of wind direction in delta from the true [deg]
    'WS', linspace(-1.5,1.5,13),... % Search range of wind speed in delta from the true [m/s]
    'TI', [0.0]); % Search range of turbulence intensity in delta from the true [m/s]

relSearchRange2 = struct(...
    'WD', linspace(-20.,20.,51) * (pi/180),... % Search range of wind direction in delta from the true [deg]
    'WS', linspace(-1.5,1.5,13),... % Search range of wind speed in delta from the true [m/s]
    'TI', [-0.06 -0.03 0.0 0.03 0.06 0.09]); % Search range of turbulence intensity in delta from the true [m/s]


%% Evaluate FLORIS for all true and hypothetical conditions
if isunix; parpool(40); end % Initialize parallel pool
[costInfo1] = calculateCostRose(layouts,trueRange,relSearchRange1); 
timestamp = strrep(strrep(datestr(rem(now,1)),':','.'),' ','');
save([timestamp '_obsvAnalysis_perfectTI.mat'],'costInfo1');

[costInfo2] = calculateCostRose(layouts,trueRange,relSearchRange2); 
timestamp = strrep(strrep(datestr(rem(now,1)),':','.'),' ','');
save([timestamp 'obsvAnalysis_estimateAll.mat'],'costInfo2');


%% Calculate the observability rose
jFunString = '0.0*msePwr + 1.0*mseUwse + 10.0*(dwd^2)'; % Specify cost function J: here, assume wind speed and wind vane measurements
mFunString = 'J/dxSqrd'; % Specify intermediate function for M. The observability O is the minimum value of M.
deadzone = struct('apply',true,'WD',3.99*pi/180,'WS',0.249,'TI',0.029); % Apply a deadzone around the true solution for M
obsvInfo1 = calculateObsvRose(costInfo1,jFunString,mFunString,deadzone);
obsvInfo2 = calculateObsvRose(costInfo2,jFunString,mFunString,deadzone);


%% Plot the observability rose
plotSensitivityFigures(obsvInfo1);
plotSensitivityFigures(obsvInfo2);