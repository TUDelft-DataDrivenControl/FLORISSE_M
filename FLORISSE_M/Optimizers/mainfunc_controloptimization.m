function [xopt, P_bl, P_opt] = mainfunc_controloptimization(...
    florisRunner,~, yawOpt, ~, pitchOpt, ~, axialOpt, WD_std, WD_N,...
    optMethod,turbIdxsToOptimize,optVerbose)
%OPTIMIZECONTROLSETTINGS Turbine control optimization algorithm
%
%   This function is an example case of how to optimize the yaw and/or
%   blade pitch angles/axial induction factors of the turbines inside the
%   wind farm using the FLORIS model. This function includes uncertainty in
%   the incoming wind direction by assuming a Gaussian probability
%   distribution, and optimizing a single yaw angle (or other control
%   setting) for the range of WDs.
%
%   Additional variables:
%    WD_std   -- standard deviation in wind direction (rad)
%    WD_N     -- number of bins to discretize over ( recommended: >=5 )
%

nTurbs = florisRunner.layout.nTurbs;
x0 = []; lb = []; ub = [];

% Default set-up
if nargin < 11
    turbIdxsToOptimize = 1:nTurbs;
end
if nargin < 12
    optVerbose = true;
end

% Check turbIdxsToOptimize specification
if any(turbIdxsToOptimize < 1) || ... % Smaller than 1
        any(turbIdxsToOptimize > nTurbs) || ... % Higher than nTurbs
        any(round(turbIdxsToOptimize)~=turbIdxsToOptimize) || ... % Not integers
        length(unique(turbIdxsToOptimize)) ~= length(turbIdxsToOptimize) % Double entries
    error('turbIdxsToOptimize not specified properly.')
end
nTurbsControlled = length(turbIdxsToOptimize);


if yawOpt
    x0 = [x0; florisRunner.controlSet.yawAngleWFArray(turbIdxsToOptimize)];
    lb = [lb; deg2rad(-30)*ones(1,nTurbsControlled)];
    ub = [ub; deg2rad(+30)*ones(1,nTurbsControlled)];
end
if pitchOpt
    if ~strcmp(florisRunner.controlSet.controlMethod, 'pitch')
        error('Tried to optimize pitchangles but controlMethod is set to %s', florisRunner.controlSet.controlMethod)
    end
    x0 = [x0; florisRunner.controlSet.pitchAngleArray(turbIdxsToOptimize)];
    lb = [lb; deg2rad(0.0)*ones(1,nTurbsControlled)];
    ub = [ub; deg2rad(5.0)*ones(1,nTurbsControlled)];
    
end
if axialOpt
    if ~strcmp(florisRunner.controlSet.controlMethod, 'axialInduction')
        error('Tried to optimize axial inductions but controlMethod is set to %s', florisRunner.controlSet.controlMethod)
    end
    x0 = [x0; florisRunner.controlSet.axialInductionArray(turbIdxsToOptimize)];
    lb = [lb; 0.0*ones(1,nTurbsControlled)];
    ub = [ub; 1/3*ones(1,nTurbsControlled)];
end

% Discretize probability distribution
if WD_N == 1
    WD_range = [0];
elseif WD_N == 2
    WD_range = [-0.5 0.5]*WD_std;
elseif WD_N == 3
    WD_range = [-1 0 1]*WD_std;
elseif WD_N == 4
    WD_range = [-1 -1/3 1/3 1]*WD_std;
elseif WD_N > 4
    WD_range = linspace(-WD_std*2,WD_std*2,WD_N);
else
    error('Please make sure WD_std is in radians, not degrees.');
end

if WD_std == 0
    error('Please specify a nonzero STD (even when WD_N == 1).');
end

fx = @(x) (1/WD_std) * (1/sqrt(2*pi)) * exp( (-x.^2)/(2*WD_std^2));
WD_probability = fx(WD_range); % Values from Normal dist.
WD_probability = WD_probability/sum(WD_probability); % Normalized

% Plot: optionally
plotDist = false;
if plotDist
    figure;
    xPl = linspace(-3*WD_std,3*WD_std,101);
    yPl = fx(xPl);
    plot(xPl,yPl,'k'); grid on; hold on;
    plot(WD_range,fx(WD_range),'ro');
    ylabel('Probability')
    xlabel('\Delta WD (rad)','Interpreter','tex');
    legend('Continuous distribution','Discretization points');
end

clear fx

% Define cost function
cost = @(x)costFunctionRobust(x, florisRunner,WD_range,WD_probability);
if strcmp(optMethod,'fmincon')
    % FMINCON OPTIMIZATION
    if optVerbose
        options = optimset('Display','final','MaxFunEvals',1e4,'PlotFcns',{@plotfun1;@plotfun2}); % Display convergence
    else
        options = optimset('Display','off','MaxFunEvals',1e4,'PlotFcns',{} );
    end
    xopt = fmincon(cost,x0,[],[],[],[],lb,ub,[],options);
    
elseif strcmp(optMethod,'gridsearch')
    % GRID SEARCH OPTIMIZATION
    for iil = 1:length(lb)
        if yawOpt && iil <= nTurbsControlled
            tmp_L{iil} = lb(iil):pi/180:ub(iil);
        else
            tmp_L{iil} = linspace(lb(iil),ub(iil),31);
        end
    end
    Lcoms = combvec(tmp_L{:})'; % All combinations of inputs
    J_eval = zeros(size(Lcoms,1),1); % Evaluation vector
    for iil = 1:size(Lcoms,1)
        J_eval(iil) = cost(Lcoms(iil,:)); 
    end
    [Jopt,iopt] = min(J_eval); % Optimal cost function value and inputs index
    xopt = Lcoms(iopt,:); % Optimal inputs
    
    if optVerbose
        disp(['Power optimization using grid search. J(xopt) = ' num2str(Jopt) '. xopt = [' num2str(xopt) '].']);
    end
else
    error('Unvalid optimization method specified.')
end

% Overwrite florisRunner object parameters
if yawOpt
    florisRunner.controlSet.yawAngleWFArray(turbIdxsToOptimize) = xopt(1,:); % Evaluation point
    if pitchOpt; florisRunner.controlSet.pitchAngleArray(turbIdxsToOptimize) = xopt(2,:); end
    if axialOpt; florisRunner.controlSet.axialInductionArray(turbIdxsToOptimize) = xopt(2,:); end
else
    if pitchOpt; florisRunner.controlSet.pitchAngleArray(turbIdxsToOptimize) = xopt(1,:); end
    if axialOpt; florisRunner.controlSet.axialInductionArray(turbIdxsToOptimize) = xopt(1,:); end
end

% Calculate improvements
if nargout > 1 || optVerbose
    P_bl  = -costFunctionRobust(x0,  florisRunner,WD_range, WD_probability); % Calculate baseline power
    P_opt = -costFunctionRobust(xopt,florisRunner,WD_range, WD_probability); % Calculate optimal power
end

% Display improvements
if optVerbose
    disp(['Initial power: ' num2str(P_bl/10^6) ' MW']);
    disp(['Optimized power: ' num2str(P_opt/10^6) ' MW']);
    disp(['Relative increase: ' num2str((P_opt/P_bl-1)*100) '%.']);
end

% Probablistic cost function (for a prob. dist. of wind directions)
    function J = costFunctionRobust(x, florisRunnerIn,WD_range, WD_probability)
        J = 0;
        florisRunnerLocal = copy(florisRunnerIn); % Create independent copy
        WD0 = florisRunnerIn.layout.ambientInflow.windDirection; % Initial WD
        
        % 'x' contains the to-be-optimized control variables. This
        % can be yaw angles, blade pitch angles, or both. Hence,
        % depending on these choices, we have to first extract the
        % yaw angles and/or blade pitch angles back from x, before
        % we trial them in a FLORIS simulation. That is what we do next:
        if yawOpt
            florisRunnerLocal.controlSet.yawAngleWFArray(turbIdxsToOptimize) = x(1,:); % Evaluation point
            if pitchOpt; florisRunnerLocal.controlSet.pitchAngleArray(turbIdxsToOptimize) = x(2,:); end
            if axialOpt; florisRunnerLocal.controlSet.axialInductionArray(turbIdxsToOptimize) = x(2,:); end
        else
            if pitchOpt; florisRunnerLocal.controlSet.pitchAngleArray(turbIdxsToOptimize) = x(1,:); end
            if axialOpt; florisRunnerLocal.controlSet.axialInductionArray(turbIdxsToOptimize) = x(1,:); end
        end

        % Cover the range
        for i = 1:length(WD_range)
            % Update wind direction
            florisRunnerLocal.layout.ambientInflow.windDirection = WD0 + WD_range(i);
            % Maintain fixed yaw angle in the inertial frame
            florisRunnerLocal.controlSet.yawAngleIFArray = florisRunnerLocal.controlSet.yawAngleIFArray;
            % Determine cost for this WD
            J = J + WD_probability(i) * costSingleRun(florisRunnerLocal);
        end
    end

% Deterministic cost function (for a single WD)
    function J = costSingleRun(florisRunner)
        % Then, we simulate FLORIS and determine the cost J(x)
        florisRunner.clearOutput();
        florisRunner.run;
        J = -sum([florisRunner.turbineResults.power]);
    end

    % Visualization functions
    function stop = plotfun1(x,optimValues,state)
        stop=optimplotx(x,optimValues,state);
        ylabel('Value')
        xlabel('Control variable');
        grid on; box on;
    end
    function stop = plotfun2(x,optimValues,state)
        optimValues.fval = -1e-6*optimValues.fval; 
        stop = optimplotfval(x,optimValues,state);
        ylabel('Expected power prod. (MW)')
        grid on; box on;      
        xlim([0 30]);
        
%         set(gcf,'color','w');
%         export_fig(['optimizationOutputs/kOut/' num2str(optimValues.iteration+1) '.png'],'-m2');
    end

end
