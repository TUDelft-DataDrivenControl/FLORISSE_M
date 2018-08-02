classdef estimator < handle
    %VISUALIZER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        estimParamsAll
        florisObjSet
        measurementSet
    end
    
    methods
        function obj = estimator(florisObjSet,measurementSet)
            % Store the relevant properties from the FLORIS object
            obj.florisObjSet   = florisObjSet;
            obj.measurementSet = measurementSet;
            
            if length(measurementSet) ~= length(florisObjSet)
                error('The measurementSet dimensions should match that of the florisObjSet.');
            end
            
            % Determine the collective set of estimation parameters
            estimParamsAll = {};
            for i = 1:length(measurementSet)
                estimParamsAll = {estimParamsAll{:} measurementSet{i}.estimParams{:}};
            end
            obj.estimParamsAll = unique(estimParamsAll);
            disp(['Collective param. estimation set: [' strjoin(obj.estimParamsAll,', ') ']'])
        end
        
        function [xopt,Jopt] = gaEstimation(obj,x0)           
            if nargin < 2
                disp('Starting unconstrained parameter estimation using the GA toolbox...');
                lb = [];   % Condition lb <= x <= ub
                ub = [];   % Condition lb <= x <= ub
            else
                disp('Starting constrained parameter estimation using the GA toolbox...');
                if length(x0) ~= length(obj.estimParamsAll)
                    error(['The variable [x0] has to be of equal length as [estimationParams], which is ' num2str(length(obj.estimParamsAll)) '.']);
                end                
                lb = min([x0/2. ; x0*2.]) % Condition lb <= x <= ub
                ub = max([x0/2. ; x0*2.]) % Condition lb <= x <= ub
            end
            ga_A   = []; % Condition A * x <= b
            ga_b   = []; % Condition A * x <= b
            ga_Aeq = []; % Condition Aeq * x == beq
            ga_beq = []; % Condition Aeq * x == beq
            
            costFun = @(x) obj.costWeightedRMSE(x);
            
            % Optimize using Parallel Computing
                % options = gaoptimset('PopulationSize', popsize, 'Generations', gensize, 'Display', 'off', 'TolFun', 1e-2,'UseParallel', true);
            nVars = length(obj.estimParamsAll);
            options = gaoptimset('Display','iter', 'TolFun', 1e-3,'UseParallel', true);
            [xopt,Jopt,exitFlag,output,population,scores] = ga(costFun, nVars, ga_A, ga_b, ga_Aeq, ga_beq, lb, ub, [], options);
        end
    end
    
    methods (Hidden)
        function [J] = costWeightedRMSE(obj,x);
            florisObjSet     = obj.florisObjSet;
            measurementSet   = obj.measurementSet;
            estimParamsAll = obj.estimParamsAll;
            
            if length(x) ~= length(estimParamsAll)
                error('The variable [x] has to be of equal length as [estimationParams].');
            end
            
            % Update the parameters with [x] of each floris object, if required
            for i = 1:length(florisObjSet)
                florisObjTmp = copy(florisObjSet{i});
                for ji = 1:length(estimParamsAll)
                    % Update parameter iff is tuned for measurement set [i]
                    if ismember(estimParamsAll{ji},measurementSet{i}.estimParams)
                        florisObjTmp.model.modelData.(estimParamsAll{ji}) = x(ji);
                    end
                end
                
                % Reset cost function and execute FLORIS with [x]
                Jset = zeros(1,length(florisObjSet));
                florisObjTmp.run();
                
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
            
            % Final cost
            J = sum(Jset);
        end
    end
end

