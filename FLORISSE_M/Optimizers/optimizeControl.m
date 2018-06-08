function [xopt] = optimizeControl(florisRunner, ~, yawOpt, ~, pitchOpt, ~, axialOpt)
%OPTIMIZECONTROL Summary of this function goes here
%   Detailed explanation goes here
nTurbs = florisRunner.layout.nTurbs;
x0 = []; lb = []; ub = [];

if yawOpt
    x0 = [x0; florisRunner.controlSet.yawAngles];
    lb = [lb; deg2rad(-45)*ones(nTurbs,1)];
    ub = [ub; deg2rad(+45)*ones(nTurbs,1)];
end
if pitchOpt
    if ~strcmp(florisRunner.controlSet.controlMethod, 'pitch')
        error('Tried to optimize pitchangles but controlMethod is set to %s', florisRunner.controlSet.controlMethod)
    end
    x0 = [x0; florisRunner.controlSet.pitchAngles];
    lb = [lb; deg2rad(0.0)*ones(nTurbs,1)];
    ub = [ub; deg2rad(5.0)*ones(nTurbs,1)];
end
if axialOpt
    if ~strcmp(florisRunner.controlSet.controlMethod, 'axialInduction')
        error('Tried to optimize axial inductions but controlMethod is set to %s', florisRunner.controlSet.controlMethod)
    end
    x0 = [x0; florisRunner.controlSet.axialInductions];
    lb = [lb; 0.0*ones(nTurbs,1)];
    ub = [ub; 1/3*ones(nTurbs,1)];
end


cost = @(x)costFunction(x, florisRunner);

% Optimizer settings and optimization execution
%options = optimset('Display','final','MaxFunEvals',1000 ); % Display nothing
%options = optimset('Algorithm','sqp','Display','final','MaxFunEvals',1000,'PlotFcns',{@optimplotx, @optimplotfval} ); % Display convergence
options = optimset('Display','final','MaxFunEvals',1e4,'PlotFcns',{@optimplotx, @optimplotfval} ); % Display convergence
xopt    = fmincon(cost,x0,[],[],[],[],lb,ub,[],options);

% Simulated annealing
%options = optimset('Display','iter','MaxFunEvals',1000,'PlotFcns',{@optimplotx, @optimplotfval} ); % Display convergence
%xopt    = simulannealbnd(cost,self.inputData.axialInd,lb,ub,options);

% Display improvements
P_bl  = -costFunction(x0,  florisRunner); % Calculate baseline power
P_opt = -costFunction(xopt,florisRunner); % Calculate optimal power
disp(['Initial power: ' num2str(P_bl/10^6) ' MW']);
disp(['Optimized power: ' num2str(P_opt/10^6) ' MW']);
disp(['Relative increase: ' num2str((P_opt/P_bl-1)*100) '%.']);


% Cost function that is to be optimized. Basically, J = -sum(P).
function J = costFunction(x, florisRunner)
    % 'x' contains the to-be-optimized control variables. This
    % can be yaw angles, blade pitch angles, or both. Hence,
    % depending on these choices, we have to first extract the
    % yaw angles and/or blade pitch angles back from x, before
    % we trial them in a FLORIS simulation. That is what we do next:
    if yawOpt
        florisRunner.controlSet.yawAngles = x(1,:);
        if pitchOpt; florisRunner.controlSet.pitchAngles = x(2,:); end
        if axialOpt; florisRunner.controlSet.axialInductions = x(2,:); end
    else
        if pitchOpt; florisRunner.controlSet.pitchAngles = x(1,:); end
        if axialOpt; florisRunner.controlSet.axialInductions = x(1,:); end
    end
    % Then, we simulate FLORIS and determine the cost J(x)
    florisRunner.clearOutput()
    florisRunner.run
    J = -sum([florisRunner.turbineResults.power]);
end
end
