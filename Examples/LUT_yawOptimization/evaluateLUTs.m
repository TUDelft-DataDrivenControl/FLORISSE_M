clear all; close all; clc
addpath('bin')
addpath(genpath('../../FLORISSE_M'))

% LUT files
ix = 0;

% ix = ix + 1;
% inputArray{ix}.databaseLUT = importYawLUT('LUTs/LUT_6turb_yaw.csv');
% inputArray{ix}.outputFile = 'LUTs/LUT_6turb_yaw.deter.mat';

ix = ix + 1;
inputArray{ix} = load('LUTs/LUT_6turb_yawFiltered.mat');
inputArray{ix}.outputFile = 'LUTs/LUT_6turb_yawFiltered.deter.mat';

% ------------------------------
%% Setup a FLORIS object
layout = WE19_6_turb(); % Instantiate a layout without ambientInflow conditions
refheight = layout.uniqueTurbineTypes(1).hubHeight; % Use the height from the first turbine type as reference height for theinflow profile
layout.ambientInflow = ambient_inflow_log('PowerLawRefSpeed', 8,  'PowerLawRefHeight', refheight,'windDirection', 0,  'TI0', .05);
controlSet = control_set(layout, 'yaw'); % Make a controlObject for this layout
subModels = model_definition('','rans','','selfSimilar','','quadraticRotorVelocity','','crespoHernandez');

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
florisRunner = floris(layout, controlSet, subModels);

%% Simulations
WD_N = 1; % If N = 1, then only evaluate nominal point. Increase for stochastic evaluations.
WD_std = 5.0*pi/180; % Standard deviation in WD prob. distr. Irrelevant if WD_N == 1.
for di = 1:length(inputArray)
    disp(['Evaluating for case ' num2str(di) '.'])
    databaseLUT = inputArray{di}.databaseLUT;
    [avgGainPercent,minGainPercent,maxGainPercent,databaseLUTout] = runLUTcases(databaseLUT,florisRunner,WD_N,WD_std);
    save([inputArray{di}.outputFile],'databaseLUTout')
end