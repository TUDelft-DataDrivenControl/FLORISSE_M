clear all; close all; clc;

% Add FLORIS path and setup layout
addpath(genpath('../FLORISSE_M'))
layout = sowfa_9_turb;

% Purposely initialize with poor initial conditions (to assess estimation)
% layout.ambientInflow = ambient_inflow_log('WS', 8.0,'HH', 90.0,'WD', 0,'TI0', .06);
layout.ambientInflow = ambient_inflow_log('WS', 6.5,'HH', 90.0,'WD', deg2rad(10.0),'TI0', .01);
controlSet = control_set(layout, 'greedy');
subModels = model_definition('','rans','','selfSimilar','','quadraticRotorVelocity','', 'crespoHernandez');
florisRunner = floris(layout, controlSet, subModels);

% Set FLORIS model parameters to the values found by offline calibration
xopt = [-0.001338, 3.1602, -0.00267504, 0.32761, 0.17447, 0.000968572]; % From constrained optimization: fitFLORIS.m
florisOpt.model.modelData.ad    = xopt(1);
florisOpt.model.modelData.alpha = xopt(2);
florisOpt.model.modelData.bd    = xopt(3);
florisOpt.model.modelData.beta  = xopt(4);
florisOpt.model.modelData.ka	= xopt(5);
florisOpt.model.modelData.kb    = xopt(6);


% Setup all estimation cases
% measurementSet.estimParams = {'windDirection','TI0','Vref'}
measurementSet.estimParams = {'TI0','Vref','windDirection'}
lb = [ 0.0  6.0   -0.4];
ub = [ 0.4  12.0  +0.4];
yawAnglesArray{1}    = 0*ones(1,layout.nTurbs);
powerMeasurements{1} = 1e6*[1.9947 1.8571 1.6051 0.6811 0.6033 0.7136 0.6942 0.6557 0.6334];
yawAnglesArray{2}    = [-0.4338 -0.4338 -0.4338 -0.4379 -0.4379 -0.4379 0 0 0];
powerMeasurements{2} = 1e6*[1.3840 1.5633 1.5111 0.7089 0.7636 0.8734 1.1055 1.1472 1.2631];
yawAnglesArray{3}    = [0.3393 0.3458 0.3377 0.3491 0.3448 0.3430 0 0 0];
powerMeasurements{3} = 1e6*[1.6972 1.4984 1.6907 0.8087 0.7111 0.7851 0.9944 1.2076 0.9540];

for i = 1:length(yawAnglesArray)
    disp(' '); disp(' ')
    disp(' ---------------------- ')
    disp([' OPTIMIZING CASE ' num2str(i) '.']);
    % Set up control settings
    florisRunner.controlSet.yawAngleArray = yawAnglesArray{i};
    
    % Set up measurements
    measurementSet.P = struct('values',powerMeasurements{i},'stdev',[1 1 1 2 2 2 3 3 3]);
    
    % Estimate ambient conditions
    florisRunner.clearOutput;
    estTool = estimator({florisRunner},{measurementSet});
    xopt  = estTool.gaEstimation(lb,ub)
end
% True: 8 m/s, WD = 0 deg, and TI = 0.06


florisRunner.run()
visTool = visualizer(florisRunner);
visTool.plot2dIF;
%  