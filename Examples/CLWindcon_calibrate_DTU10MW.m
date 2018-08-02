%
% CLWINDCON_CALIBRATE_DTU10MW.M
% Summary: This script demonstrates how to tune a subset of model
% parameters to high-fidelity simulation or experimental data. In this
% example, we are tuning 4 tuning parameters to flow measurements for a
% single-turbine wind farm case. It should be straight-forward to extend
% this to multiple wind farm simulations, layouts, ambient conditions, and
% measurements (power and/or flow).
%
clear all; close all; clc;

%% Initialize FLORIS objects for the cases used for model calibration (should match the measurementSet)
subModels = model_definition('deflectionModel','rans','velocityDeficitModel', 'selfSimilar','wakeCombinationModel', 'quadraticRotorVelocity','addedTurbulenceModel', 'crespoHernandez');
layout    = generic_1_turb;
layout.ambientInflow = ambient_inflow_log('PowerLawRefSpeed', 8,'PowerLawRefHeight',90.0,'windDirection', 0, 'TI0', .05);

% Generate a separate FLORIS object for each yaw setting evaluated
yawAngleRange = [-30:10:30]*pi/180;
for i = 1:length(yawAngleRange)
    controlSetSet{i} = control_set(layout, 'greedy');
    controlSetSet{i}.yawAngles = yawAngleRange(i); % Overwrite yaw angle
    florisObjSet{i}  = floris(layout, controlSetSet{i}, subModels);
end

%% Format measurements from SOWFA
for i = 1:length(yawAngleRange)
    % measurementSet{i}.P.values  = [1e6]; % Power measurements not relevant for 1-turbine model fitting
    % measurementSet{i}.P.stdev     = [2e5]; % Power measurements not relevant for 1-turbine model fitting
    measurementSet{i}.U.x      = [300.0, 1000.0];
    measurementSet{i}.U.y      = [  0.0,    0.0];
    measurementSet{i}.U.z      = [ 90.0,   90.0];
    measurementSet{i}.U.values = [  5.0,    6.0];
    measurementSet{i}.U.stdev  = [  1.0,    1.0];
    measurementSet{i}.estimParams = {'alpha','beta','ka','kb'};
end

% Optional: only estimate some parameters for some situations
measurementSet{1}.estimParams = {'beta','ka','kb'};
measurementSet{5}.estimParams = {'bd'};

% Create an estimation object with the right inputs
estTool = estimator(florisObjSet,measurementSet);

% Constrained optimization, with  x0/2 <= x_opt <= x0*2
x0 = [2.32,.154,.3837,.0037,-0.01];
xopt_con = estTool.gaEstimation(x0); % Use genetic algorithms for constrained optimization

% Unconstrained optimization
% xopt_uncon = estTool.gaEstimation();   % Use genetic algorithms for unconstrained optimization