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
            checkAlphabeticalOrder = @(x) any(strcmp(unique(x),x)==0);
            for i = 1:length(measurementSet)
                if checkAlphabeticalOrder(measurementSet{i}.estimParams)
                    error('Please specify measurementSet.estimParams in alphabetical order.');
                end
                estimParamsAll = {estimParamsAll{:} measurementSet{i}.estimParams{:}};
            end
            obj.estimParamsAll = unique(estimParamsAll);
            disp(['Collective param. estimation set: [' strjoin(obj.estimParamsAll,', ') ']'])
        end
        
        function [xopt,Jopt] = gaEstimation(obj,lb,ub)           
            ga_A   = []; % Condition A * x <= b
            ga_b   = []; % Condition A * x <= b
            ga_Aeq = []; % Condition Aeq * x == beq
            ga_beq = []; % Condition Aeq * x == beq
            
            costFun = @(x) obj.costWeightedRMSE(x);
            
            % Optimize using Parallel Computing
            nVars = length(obj.estimParamsAll);
%             options = gaoptimset('Display','iter', 'TolFun', 1e-3,'UseParallel', true); No plotting
            options = gaoptimset('Display','iter', 'TolFun', 1e-3,'UseParallel', true,'PlotFcns',{@plotfun1}); % with plot
            [xopt,Jopt,exitFlag,output,population,scores] = ga(costFun, nVars, ga_A, ga_b, ga_Aeq, ga_beq, lb, ub, [], options);
            
            function state = plotfun1(options,state,flag)
                subplot(2,1,1);
                [~,idx]=min(state.Score);
                optSettings=state.Population(idx,:);
                bar(optSettings);
                text(1:length(optSettings),optSettings,num2str(optSettings'),'vert','bottom','horiz','center'); 
                ylabel('Value');
                xlabel('Estimation variables');
                grid on; box on;
                
                subplot(2,1,2);
                plot(1:length(state.Best),state.Best,'kd','MarkerFaceColor',[1 0 1]);
                ylabel('Cost');
                xlim([0 20]);
                xlabel('Generation');
                grid on; box on;
               
%                 set(gcf,'color','w');
%                 export_fig(['estimationOutputs/kOut/' num2str(state.Generation) '.png'],'-m2');
            end
        end
        
        function [J] = costWeightedRMSE(obj,x);
            florisObjSet   = obj.florisObjSet;
            measurementSet = obj.measurementSet;
            estimParamsAll = obj.estimParamsAll;
            
            if length(x) ~= length(estimParamsAll)
                error('The variable [x] has to be of equal length as [estimationParams].');
            end
            
            % Reset cost function 
            Jset = zeros(1,length(florisObjSet));
            
            % Update the parameters with [x] of each floris object, if required
            for i = 1:length(florisObjSet)
                florisObjTmp = copy(florisObjSet{i});
                for ji = 1:length(estimParamsAll)
                    % Update parameter iff is tuned for measurement set [i]
                    if ismember(estimParamsAll{ji},measurementSet{i}.estimParams)
                        if ismember(estimParamsAll{ji},{'Vref','TI0','windDirection'})
                            florisObjTmp.layout.ambientInflow.(estimParamsAll{ji}) = x(ji);
                        else
                            florisObjTmp.model.modelData.(estimParamsAll{ji}) = x(ji);
                        end
                    end
                end
                

                % Execute FLORIS with [x]
                florisObjTmp.run();
                
                % Calculate weighted power RMSE, if applicable
                if any(ismember(fields(measurementSet{i}),'P'))
                    powerError = [florisObjTmp.turbineResults.power] - measurementSet{i}.P.values;
                    Jset(i)    = Jset(i) + sqrt(mean((powerError ./ measurementSet{i}.P.stdev).^2));
                end
                
                % Calculate weighted flow RMSE, if applicable
                if any(ismember(fields(measurementSet{i}),'U'))
                    fixYaw  = false;
                    uProbes = compute_probes(florisObjTmp,measurementSet{i}.U.x,measurementSet{i}.U.y,measurementSet{i}.U.z,fixYaw);
                    flowError = uProbes - measurementSet{i}.U.values;
                    Jset(i)   = Jset(i) + sqrt(mean((flowError ./ measurementSet{i}.U.stdev).^2));
                end
            end
            
            % Final cost
            J = sum(Jset);
        end
        
    end
    
    methods (Hidden)
        %
    end
end

