function [outputArg1,outputArg2] = optimizeControl(inputArg1,inputArg2)
%OPTIMIZECONTROL Summary of this function goes here
%   Detailed explanation goes here
outputArg1 = inputArg1;
outputArg2 = inputArg2;
end

%% FLORIS control optimization
function [] = optimize(self,optimizeYaw,optimizeAxInd)
    % This function will optimize the turbine yaw angles and/or the
    % turbine axial induction factors (blade pitch angles) to
    % maximize the power output of the wind farm. 

    inputData = self.inputData;
    disp(['Performing optimization: optimizeYaw = ' num2str(optimizeYaw) ', optimizeAxInd: ' num2str(optimizeAxInd) '.']);

    % Define initial guess x0, lower bounds lb, and upper bounds ub
    x0 = []; lb = []; ub = [];
    if optimizeYaw  
        x0 = [x0, inputData.yawAngles];
        lb = [lb, deg2rad(-25)*ones(inputData.nTurbs,1)];
        ub = [ub, deg2rad(+25)*ones(inputData.nTurbs,1)];
    end
    if optimizeAxInd
        if inputData.axialControlMethod == 0
            x0 = [x0, inputData.pitchAngles];  
            lb = [lb, deg2rad(0.0)*ones(inputData.nTurbs,1)];
            ub = [ub, deg2rad(5.0)*ones(inputData.nTurbs,1)];
        elseif inputData.axialControlMethod == 1
            disp(['Cannot optimize axialInd for axialControlMethod == 1.']);
            if optimizeYaw == false
                disp('Exiting optimization call.');
                return; 
            else
                disp('Optimizing yaw only.');
                optimizeAxInd = false;
            end
        elseif inputData.axialControlMethod == 2
            x0 = [x0, inputData.axialInd];     
            lb = [lb, 0.0*ones(inputData.nTurbs,1)];
            ub = [ub, 1/3*ones(inputData.nTurbs,1)];
        end
    end

    % Cost function that is to be optimized. Basically, J = -sum(P).
    function J = costFunction(x,inputData,optimizeYaw,optimizeAxInd)
        % 'x' contains the to-be-optimized control variables. This
        % can be yaw angles, blade pitch angles, or both. Hence,
        % depending on these choices, we have to first extract the
        % yaw angles and/or blade pitch angles back from x, before
        % we trial them in a FLORIS simulation. That is what we do next:
        if optimizeYaw; inputData.yawAngles = x(1:inputData.nTurbs); end
        if optimizeAxInd
            if inputData.axialControlMethod == 0
                inputData.pitchAngles = x(end-inputData.nTurbs+1:end);
            elseif inputData.axialControlMethod == 2
                inputData.axialInd    = x(end-inputData.nTurbs+1:end); 
            end
        end

        % Then, we simulate FLORIS and determine the cost J(x)
        [outputData] = floris_core(inputData,0);
        J            = -sum(outputData.power);
    end

    cost = @(x)costFunction(x,self.inputData,optimizeYaw,optimizeAxInd);

    % Optimizer settings and optimization execution
    %options = optimset('Display','final','MaxFunEvals',1000 ); % Display nothing
    %options = optimset('Algorithm','sqp','Display','final','MaxFunEvals',1000,'PlotFcns',{@optimplotx, @optimplotfval} ); % Display convergence
    options = optimset('Display','final','MaxFunEvals',1e4,'PlotFcns',{@optimplotx, @optimplotfval} ); % Display convergence
    xopt    = fmincon(cost,x0,[],[],[],[],lb,ub,[],options);

    % Simulated annealing
    %options = optimset('Display','iter','MaxFunEvals',1000,'PlotFcns',{@optimplotx, @optimplotfval} ); % Display convergence
    %xopt    = simulannealbnd(cost,self.inputData.axialInd,lb,ub,options);

    % Display improvements
    P_bl  = -costFunction(x0,  inputData,optimizeYaw,optimizeAxInd); % Calculate baseline power
    P_opt = -costFunction(xopt,inputData,optimizeYaw,optimizeAxInd); % Calculate optimal power
    disp(['Initial power: ' num2str(P_bl/10^6) ' MW']);
    disp(['Optimized power: ' num2str(P_opt/10^6) ' MW']);
    disp(['Relative increase: ' num2str((P_opt/P_bl-1)*100) '%.']);

    % Overwrite current settings with optimized oness
    if P_opt > P_bl
        if optimizeYaw; self.inputData.yawAngles = xopt(1:inputData.nTurbs); end
        if optimizeAxInd
            if inputData.axialControlMethod == 0
                self.inputData.pitchAngles = xopt(end-inputData.nTurbs+1:end); 
                self.inputData.axialInd    = NaN*ones(1,inputData.nTurbs);
                % The implicit values for axialInd calculated from
                % blade pitch angles can be found in outputData,
                % under the 'turbine.axialInd' substructure.
            elseif inputData.axialControlMethod == 2
                self.inputData.pitchAngles = NaN*ones(1,inputData.nTurbs);
                self.inputData.axialInd    = xopt(end-inputData.nTurbs+1:end); 
            end
        end
    else
        disp('Optimization was unsuccessful. Sticking to old control settings.');
    end

    % Update outputData for optimized settings
    self.run(); 
end

%% Simplified function to call yaw-only optimization
function [] = optimizeYaw(self)
    self.optimize(true,false);
end

%% Simplified function to call axial-only optimization
function [] = optimizeAxInd(self)
    self.optimize(false,true);
end
