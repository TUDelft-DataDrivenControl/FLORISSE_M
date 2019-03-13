clear all; close all; clc;

%% Setup
trueRange = struct(...
    'WD', linspace(0,2*pi,37),... % Discretization of 360 degrees wind rose. Recommended to be uneven number.
    'WS', [16.0],...%[8.5 11.4 16.0],... % Below, at, and above-rated
    'TI', [0.065]); %[0.065 0.12 0.18]);

% HPC
if isunix
    parpool(40)
end

relSearchRange = struct(...
    'WD', linspace(-20.,20.,51) * (pi/180),...
    'WS', linspace(-1.5,1.5,13),...
    'TI', [-0.06 0.0 0.06 0.12]);

for vaneMeasurementWeight = 1.0%[0.0 0.1 0.2 0.5 1.0 2.0 5.0 10.0 20.0]
    outputMatrix = multidimensionalSensitivity(trueRange,relSearchRange,vaneMeasurementWeight);
    save(['out_vaneWeight' num2str(vaneMeasurementWeight) '.mat']);
end

% relSearchRange = struct(...
%     'WD', linspace(-20.,20.,51) * (pi/180),...
%     'WS', linspace(-1.0,1.0,13),...
%     'TI', [-0.06 -0.03 0.0 0.03 0.06 0.09 0.12]);
% multidimensionalSensitivity(trueRange,relSearchRange)
% % Tight bound, detailed plot