addpath('bin')
addpath('layouts')
addpath(genpath('../../FLORISSE_M'))

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
jFunString = '0.0*msePwr + 1.0*mseUwse + 10.0*(dwd^2)'; % Specify cost function J: here, assume wind speed and wind vane measurements
mFunString = 'J/dxSqrd'; % Specify intermediate function for M. The observability O is the minimum value of M.
deadzone = struct('apply',true,'WD',3.99*pi/180,'WS',0.249,'TI',0.029); % Apply a deadzone around the true solution for M
obsvInfo = calculateObsvRose(costInfo,jFunString,mFunString,deadzone);

%% Plot the observability rose
plotSensitivityFigures(obsvInfo);

%% Plot 2D cost function
WDplotidx = 2; % Plot entry number {value between 1 and length(trueRange.WD)}
figure()
[X,Y] = meshgrid(relSearchRange.WS,relSearchRange.WD*180/pi);
surf(X,Y,(squeeze(obsvInfo.Mfilt{WDplotidx}(1,:,:))'),'EdgeColor','interp');
xlabel('$\Delta U_\infty$','interpreter','latex')
ylabel('$\Delta \phi$','interpreter','latex')
zlabel('$\textrm{log}(\mathcal{M})$','interpreter','latex')
title(['2D visualization of $\mathcal{M}$ for WD=' num2str(round(trueRange.WD(WDplotidx)*180/pi)) ' deg, with $\mathcal{O} = ' num2str(obsvInfo.O(WDplotidx)) '$'],'Interpreter','latex')