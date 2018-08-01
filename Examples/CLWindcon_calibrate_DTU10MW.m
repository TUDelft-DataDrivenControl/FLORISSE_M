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
    measurementSet{i}.U.x      = [100.0, 1000.0];
    measurementSet{i}.U.y      = [  0.0,    0.0];
    measurementSet{i}.U.z      = [ 90.0,   90.0];
    measurementSet{i}.U.values = [  8.0,    8.0];
    measurementSet{i}.U.stdev  = [  1.0,    1.0];
end

% Set up cost function
costFun = @(x) costWeightedRMSE(x,florisObjSet,measurementSet);

% Evaluate initial cost
% x0 = [2.32,.154,.3837,.0037];
x0 = [2.72,.274,.8107,.2037];
J0 = costFun(x0);

% Optimize
xopt = ga(costFun,4); % Genetic algorithm optimization
Jopt = costFun(xopt);

function [J] = costWeightedRMSE(x,florisObjSet,measurementSet);
    Jset = zeros(1,length(florisObjSet));
    for i = 1:length(florisObjSet)
        clear florisObjTmp
        florisObjTmp = florisObjSet{i};
        florisObjTmp.model.modelData.alpha = x(1);
        florisObjTmp.model.modelData.beta  = x(2);
        florisObjTmp.model.modelData.ka    = x(3);
        florisObjTmp.model.modelData.kb    = x(4);
        florisObjTmp.run(); % Execute
        
        % Calculate weighted power RMSE, if applicable
        if any(ismember(fields(measurementSet{i}),'P'))
            powerError = [florisObjTmp.turbineResults.power] - measurementSet{i}.P.values;
            Jset(i)    = Jset(i) + rms(powerError ./ measurementSet{i}.P.stdev);
        end  
        
        % Calculate weighted flow RMSE, if applicable
        if any(ismember(fields(measurementSet{i}),'U'))
            fixYaw  = false;
            uProbes = compute_probes(florisObjTmp,measurementSet{1}.U.x,measurementSet{1}.U.y,measurementSet{1}.U.z,fixYaw);
            flowError = uProbes - measurementSet{i}.U.values;
            Jset(i)   = Jset(i) + rms(flowError ./ measurementSet{i}.U.stdev);
        end  
    end
    J = sum(Jset);
end
