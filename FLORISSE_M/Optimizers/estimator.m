classdef estimator < handle
    %VISUALIZER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        estimationParams
        florisObjSet
        measurementSet
    end
    
    methods
        function obj = estimator(estimationParams,florisObjSet,measurementSet)
            % Store the relevant properties from the FLORIS object
            obj.estimationParams = estimationParams;
            obj.florisObjSet     = florisObjSet;
            
            if nargin < 3
                % Generate empty measurement set
                obj.measurementSet   = cell(size(obj.florisObjSet));
            else
                obj.measurementSet = measurementSet;
            end
        end
        
        function [xopt,Jopt] = gaEstimation(obj,x0)
            costFun = @(x) obj.costWeightedRMSE(x);
            
            lb = x0/5;   % Condition lb <= x <= ub
            ub = x0*5;   % Condition lb <= x <= ub
            ga_A = [];   % Condition A * x <= b
            ga_b = [];   % Condition A * x <= b
            ga_Aeq = []; % Condition Aeq * x == beq
            ga_beq = []; % Condition Aeq * x == beq
            J0 = costFun(x0);
           
            % Optimize using Parallel Computing
            disp('Starting parameter estimation using the GA toolbox...');
           
            % options = gaoptimset('PopulationSize', popsize, 'Generations', gensize, 'Display', 'off', 'TolFun', 1e-2,'UseParallel', true);
            options = gaoptimset('Display','iter', 'TolFun', 1e-3,'UseParallel', true);
            [xopt,Jopt,exitFlag,output,population,scores] = ga(costFun, length(lb), ga_A, ga_b, ga_Aeq, ga_beq, lb, ub, [], options);
        end
            
            
        function [J] = costWeightedRMSE(obj,x);
            florisObjSet     = obj.florisObjSet;
            measurementSet   = obj.measurementSet;
            estimationParams = obj.estimationParams;
            
            if length(x) ~= length(estimationParams)
                error('The variable [x] has to be of equal length as [estimationParams].');
            end
            
            Jset = zeros(1,length(florisObjSet));
            for i = 1:length(florisObjSet)
                florisObjTmp = copy(florisObjSet{i});
                for ji = 1:length(estimationParams)
                    % Overwrite the model parameter ji
                    florisObjTmp.model.modelData.(estimationParams{ji}) = x(ji);
                end
                florisObjTmp.run(); % Execute
                
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
            J = sum(Jset);
        end
    end
end

