addpath('layouts')

%% Setup
layouts{1} = sns_2turb_layout();

trueRange = struct(...
    'WD', linspace(0,2*pi,37),... % Discretization of 360 degrees wind rose. Recommended to be uneven number.
    'WS', [7.0],... % True wind speed [m/s]
    'TI', [0.065]); % True turbulence intensity [%]

relSearchRange = struct(...
    'WD', linspace(-20.,20.,51) * (pi/180),... % Search range of wind direction in delta from the true [deg]
    'WS', linspace(-1.0,1.0,9),... % Search range of wind speed in delta from the true [m/s]
    'TI', [0.0]); % Search range of turbulence intensity in delta from the true [m/s]

%% Evaluate FLORIS for all true and hypothetical conditions
[costInfo] = calculateCostRose(layouts,trueRange,relSearchRange); 

%% Calculate the observability rose
jFunString = '0.0*msePwr + 1.0*mseUwse + 10.0*(dwd^2)'; % Wind speed and wind vane measurements
mFunString = 'J/dxSqrd'; % Function to determine M. The observability O is the minimum value of J
deadzone = struct('apply',true,'WD',3.99*pi/180,'WS',0.249,'TI',0.029); % Apply a deadzone around the true solution for M
obsvInfo = calculateObsvRose(costInfo,jFunString,mFunString,deadzone);

%% Plot the observability rose
plotSensitivityFigures(obsvInfo);