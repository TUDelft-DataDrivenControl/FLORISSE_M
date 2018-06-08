function [xopt] = calibrateParameters(florisRunner, florisPower)
%CALIBRATEPARAMETERS Summary of this function goes here
%   Detailed explanation goes here

x0 = [florisRunner.model.modelData.ka florisRunner.model.modelData.kb];
% x0 = .5
lb = x0/2;
ub = x0*2;
% Set-up cost function and minimize error with calibrationData
costFun = @(x)calibrationCostFunc(x, florisRunner, florisPower);
options = optimset('Display','final','MaxFunEvals',1e4,'PlotFcns',{@optimplotx, @optimplotfval} ); % Display convergence
xopt    = fmincon(costFun,x0,[],[],[],[],lb,ub,[],options);
disp(['Optimal calibration values: xopt = ' num2str(xopt) '.']);


% Cost function that is to be optimized. Basically, J = -sum(P).
function J = calibrationCostFunc(x, florisRunner, florisPower)
    % 'x' contains the to-be-optimized control variables. This
    % can be yaw angles, blade pitch angles, or both. Hence,
    % depending on these choices, we have to first extract the
    % yaw angles and/or blade pitch angles back from x, before
    % we trial them in a FLORIS simulation. That is what we do next:
    florisRunner.model.modelData.ka = x(1);
    florisRunner.model.modelData.kb = x(2);
    
    % Then, we simulate FLORIS and determine the cost J(x)
    florisRunner.clearOutput()
    florisRunner.run
    J = rms([florisRunner.turbineResults.power]-florisPower);
end
end
