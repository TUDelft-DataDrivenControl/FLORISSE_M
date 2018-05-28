function [outputArg1,outputArg2] = calibrateParameters(inputArg1,inputArg2)
%CALIBRATEPARAMETERS Summary of this function goes here
%   Detailed explanation goes here
outputArg1 = inputArg1;
outputArg2 = inputArg2;
end


%% FLORIS model calibration
function [xopt] = calibrate(self,paramSet,x0,lb,ub,calibrationData)
    disp(['Performing model parameter calibration: paramSet = [' strjoin(paramSet,', ') '].']);

    % Set-up cost function and minimize error with calibrationData
    costFun = @(x)calibrationCostFunc(x,paramSet,calibrationData);
    options = optimset('Display','final','MaxFunEvals',1e4,'PlotFcns',{@optimplotx, @optimplotfval} ); % Display convergence
    xopt    = fmincon(costFun,x0,[],[],[],[],lb,ub,[],options)

%             J       = calibrationCostFunc(xopt,paramSet,calibrationData)
%             disp(['Optimal calibration values: xopt = ' num2str(xopt) '.']);

    % Update self.inputData with the optimized model parameters
    for jj = 1:length(paramSet)
        self.inputData.(paramSet{jj}) = xopt(jj); % Overwrite model settings
    end    

    % Update the derived settings (inflow conditions, model functions, ...)
    self.inputData = processSettings(self.inputData);

end
