clear all; close all; clc;

% Set-up
format long
addpath(genpath('../../FLORISSE_M'));
addpath('bin');
tic;

% Load measurements
validationCase = 2; % 1 or 2

loadedData = load(['processedData/9turb_varyingYaw_validation_' num2str(validationCase) '.mat']);
timeAvgData = loadedData.timeAvgData;
inflowCurve = loadedData.inflowCurve;
measurementSet = loadedData.measurementSet;

% Initialize FLORIS objects
subModels = model_definition('deflectionModel','rans',...
                             'velocityDeficitModel', 'selfSimilar',...
                             'wakeCombinationModel', 'quadraticRotorVelocity',...
                             'addedTurbulenceModel', 'crespoHernandez');

turbines = struct('turbineType', nrel5mw() , ...
                      'locIf', {[921.5, 1141.3]; [0877.6 1390.3]; [0833.7 1639.2]; ...
                                [1543.9 1251.0]; [1500.0 1500.0]; [1456.1 1749.0];...
                                [2166.3 1360.8]; [2122.4 1609.7]; [2078.5 1858.7]});


layout = layout_class(turbines, 'fitting_9turb'); 
layout.ambientInflow = ambient_inflow_myfunc('Interpolant', ...
    inflowCurve,'HH',90,'windDirection', 0, 'TI0', .06);
controlSet = control_set(layout, 'pitch');

controlSet.pitchAngleArray = zeros(1,9);
if validationCase == 1
    controlSet.yawAngleArray = deg2rad(270.0-[282.6 256.7 271.5 261.8 274.6 261.0 277.3 281.1 295.7]);
else
    controlSet.yawAngleArray = deg2rad(270.0-[267.1 237.9 257.4 290.3 253.9 284.4 271.9 291.6 240.6]);
end

% Compare initial fit (x0) and optimal fit (xopt)
tmpInterpolant = scatteredInterpolant(timeAvgData(1).cellCenters(:,1),...
                                      timeAvgData(1).cellCenters(:,2),...
                                      timeAvgData(1).UData);
                                  
florisInit = floris(layout, controlSet, subModels);
florisOpt  = copy(florisInit);
xopt = [-0.001338132885368   3.160208854425835  -0.002675041439218  0.327610240042950   0.174472079310193   0.000968572145479]; % From constrained optimization: fitFLORIS.m  
florisOpt.model.modelData.ad    = xopt(1);
florisOpt.model.modelData.alpha = xopt(2);
florisOpt.model.modelData.bd    = xopt(3);
florisOpt.model.modelData.beta  = xopt(4);
florisOpt.model.modelData.ka	= xopt(5);
florisOpt.model.modelData.kb    = xopt(6);

florisObjSet = {florisInit};
florisObjSetOpt = {florisOpt};

% Show vertical cut-throughs of all SOWFA data: detailed plots
% showFit(timeAvgData,florisInit,florisOpt)
showFit(timeAvgData(1),florisOpt)
hold all; 
for i = 1:length(turbines)
  gamma = controlSet.yawAngleArray(i);
  xTurb = layout.locIf(i,1);
  yTurb = layout.locIf(i,2);
  R     = layout.turbines(i).turbineType.rotorRadius;
  plot3(xTurb + R*[sin(-gamma) sin(gamma)], ...
        yTurb + R*[cos(gamma) -cos(gamma)],[500 500],'k','lineWidth',1.5)
  text(xTurb-200,yTurb,500,['T' num2str(i)]);
end
axis equal;
xlim([500 2950]);
ylim([750 2250]);

% Downstream slices at hub height
Yq = [500:5:2500];
tmpInterpolant.Values = timeAvgData(1).UData;

figure('Position',[143.4000 218.6000 1.1592e+03 521.6000]);          
DD_array = [3 6 10 14];
for DDi = 1:length(DD_array) % Downstream distance in rotor diameters
    Xq = (1000 + DD_array(DDi)*126.4) * ones(size(Yq));
    subplot(2,2,DDi)
    wakeSOWFA  = tmpInterpolant(Xq,Yq);
    wakeFLORISold = compute_probes(florisInit,Xq,Yq,90.0*ones(size(Xq)),false);
    wakeFLORISopt = compute_probes(florisOpt,Xq,Yq,90.0*ones(size(Xq)),false);

    plot(Yq,wakeSOWFA,'k-');
    hold on
    plot(Yq,wakeFLORISold,'b--');
    hold on
    plot(Yq,wakeFLORISopt,'r--');
    if DDi == 4
        legend('SOWFA','FLORIS($\Psi_0$)','FLORIS($\Psi_\textrm{opt}$)','Location','se','Interpreter','latex');
    end
    grid on; ylim([3 9]);
    ylabel('Wind speed (m/s)','Interpreter','latex'); xlabel('y (m)','Interpreter','latex');
%     title([ num2str(DD_array(DDi)) 'D, yaw = ' num2str(rad2deg(controlSet.yawAngleArray)) ' deg']);
    title(['$x = ' num2str(Xq(1)) '$ m'],'Interpreter','latex');
end