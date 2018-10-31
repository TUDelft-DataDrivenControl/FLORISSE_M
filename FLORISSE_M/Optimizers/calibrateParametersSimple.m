function [xopt] = calibrateParametersSimple(florisRunner, measuredPower)
%CALIBRATEPARAMETERSSIMPLE A simple example function for the estimation of
% ka and kb using turbine power measurements

% Define initial conditions & lower and upper bounds for the optimization
x0 = [florisRunner.model.modelData.ka florisRunner.model.modelData.kb];
lb = x0/2;
ub = x0*2;

% Set-up cost function and minimize error with the measuredPower
costFun = @(x)calibrationCostFunc(x, florisRunner, measuredPower);
options = optimset('Display','final','MaxFunEvals',1e4,'PlotFcns',{@optimplotx, @optimplotfval} ); % Display convergence
xopt    = fmincon(costFun,x0,[],[],[],[],lb,ub,[],options);
disp(['Optimal calibration values: xopt = ' num2str(xopt) '.']);


% Cost function that is to be optimized.
function J = calibrationCostFunc(x, florisRunner, measuredPower)
    % 'x' contains the to-be-estimated model parameter variables. In the
    % current example, we estimate model parameters 'ka' and 'kb':
    florisRunner.model.modelData.ka = x(1);
    florisRunner.model.modelData.kb = x(2);
    
    % Then, we simulate FLORIS and determine the cost J(..)
    florisRunner.clearOutput()
    florisRunner.run()
    J = sqrt(mean(([florisRunner.turbineResults.power]-measuredPower).^2));
end
end
