clear all

%% Setup
trueRange = struct(...
    'WD', linspace(0,2*pi,21),...%linspace(0,2*pi,37),... % Discretization of 360 degrees wind rose. Recommended to be uneven number.
    'WS', [16.0],...%[8.0 11.4 16.0],... % Below, at, and above-rated
    'TI', [0.065]);%[0.065 0.12 0.18]);

relSearchRange = struct(...
    'WD', linspace(-20.,20.,21) * (pi/180),...
    'WS', linspace(-1.0,1.0,7),...
    'TI', [0.0]);%[-0.06 0.0 0.06 0.12]);

vaneMeasurementWeight = 1e5;

outputMatrix = multidimensionalSensitivity(trueRange,relSearchRange,vaneMeasurementWeight);
plotSensitivityFigures(outputMatrix);