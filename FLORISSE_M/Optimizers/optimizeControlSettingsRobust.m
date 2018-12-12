function [xopt, P_bl, P_opt] = optimizeControlSettingsRobust(florisRunner, ~, yawOpt, ~, pitchOpt, ~, axialOpt, WD_std, WD_N, optVerbose)
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

if nargin <= 9 % Add silence/verbose option
    optVerbose = true;
end

if yawOpt
    x0 = [x0; florisRunner.controlSet.yawAngleWFArray];
    lb = [lb; deg2rad(-30)*ones(1,nTurbs)];
    ub = [ub; deg2rad(+30)*ones(1,nTurbs)];
end
if pitchOpt
    if ~strcmp(florisRunner.controlSet.controlMethod, 'pitch')
        error('Tried to optimize pitchangles but controlMethod is set to %s', florisRunner.controlSet.controlMethod)
    end
    x0 = [x0; florisRunner.controlSet.pitchAngleArray];
    lb = [lb; deg2rad(0.0)*ones(1,nTurbs)];
    ub = [ub; deg2rad(5.0)*ones(1,nTurbs)];
    
end
if axialOpt
    if ~strcmp(florisRunner.controlSet.controlMethod, 'axialInduction')
        error('Tried to optimize axial inductions but controlMethod is set to %s', florisRunner.controlSet.controlMethod)
    end
    x0 = [x0; florisRunner.controlSet.axialInductionArray];
    lb = [lb; 0.0*ones(nTurbs,1)];
    ub = [ub; 1/3*ones(nTurbs,1)];
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
if optVerbose
    options = optimset('Display','final','MaxFunEvals',1e4,'PlotFcns',{@plotfun1;@plotfun2}); % Display convergence
else
    options = optimset('Display','off','MaxFunEvals',1e4,'PlotFcns',{} );
end

xopt    = fmincon(cost,x0,[],[],[],[],lb,ub,[],options);

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
    function J = costFunctionRobust(x, florisRunner,WD_range, WD_probability)
        J = 0;
        WD0 = florisRunner.layout.ambientInflow.windDirection; % Initial WD
        
        % Cover the range
        for i = 1:length(WD_range)
            florisRunner.layout.ambientInflow.windDirection = WD0 + WD_range(i);
            J = J + WD_probability(i) * costFunctionDeterministic(x, florisRunner);
        end
        
        % Restore to default wind direction
        florisRunner.layout.ambientInflow.windDirection = WD0;
    end

% Deterministic cost function (for a single WD)
    function J = costFunctionDeterministic(x, florisRunner)
        % 'x' contains the to-be-optimized control variables. This
        % can be yaw angles, blade pitch angles, or both. Hence,
        % depending on these choices, we have to first extract the
        % yaw angles and/or blade pitch angles back from x, before
        % we trial them in a FLORIS simulation. That is what we do next:
        if yawOpt
            florisRunner.controlSet.yawAngleWFArray = x(1,:);
            if pitchOpt; florisRunner.controlSet.pitchAngleArray = x(2,:); end
            if axialOpt; florisRunner.controlSet.axialInductionArray = x(2,:); end
        else
            if pitchOpt; florisRunner.controlSet.pitchAngleArray = x(1,:); end
            if axialOpt; florisRunner.controlSet.axialInductionArray = x(1,:); end
        end
        % Then, we simulate FLORIS and determine the cost J(x)
        florisRunner.clearOutput();
        florisRunner.run;
        J = -sum([florisRunner.turbineResults.power]);
    end

    % Visualization functions
    function stop = plotfun1(x,optimValues,state)
        stop=optimplotx(x,optimValues,state);
        ylabel('Angle (rad)')
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
