% Run FLORIS over a prob. distr. of WDs
function powerOut = runLUTcases_runFLORIS(florisRunnerIn,rho,WD_probability)
florisRunnerLocal = copy(florisRunnerIn); % Create independent copy
WD0 = florisRunnerIn.layout.ambientInflow.windDirection; % Initial WD

% Cover the range
powerSingleRun = zeros(size(rho));
for i = 1:length(rho)
    florisRunnerLocal.layout.ambientInflow.windDirection = WD0 + rho(i); % Update wind direction
    florisRunnerLocal.controlSet.yawAngleIFArray = florisRunnerLocal.controlSet.yawAngleIFArray; % Maintain fixed yaw angle in the inertial frame
    
    florisRunnerLocal.run()
    powerSingleRun(i) = sum([florisRunnerLocal.turbineResults.power]);
    florisRunnerLocal.clearOutput()
end
powerOut = WD_probability * powerSingleRun'; % Determine cost for this WD
end