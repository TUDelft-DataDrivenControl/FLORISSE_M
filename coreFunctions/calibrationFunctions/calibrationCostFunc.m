function [J] = calibrationCostFunc(x,paramSet,calibrationData)
%CALIBRATIONCOSTFUNC Cost function for comparison with LES/experimental data
%
%  Inputs:      
%    x       : vector with values corresponding to paramSet.
%               e.g., x = [12.0, 0.30];
%    paramSet: a cell array with tuning parameter fieldnames as entries.
%               e.g., paramSet = {'uInfWf','windDirection'};
%    calibrationData: a struct with inputData template and LES/experimental
%    data which is required for tuning.
%         e.g.,                         
%         calibrationData(1).caseName  = '3x3_5MW_WD270_yaw0';
%         calibrationData(1).inputData = floris_loadSettings(...);
%         calibrationData(1).flow(1)   = struct('x',5.0,'y',5.0,'z',90,...
%                                               'value',8.0,...
%                                               'weight',1.0);
%         calibrationData(1).flow(2)   = struct('x',150.0,'y',150.0,'z',90,...
%                                               'value',5.0,...
%                                               'weight',0.5);                      
%         calibrationData(1).power(1)  = struct('turbId',1,...
%                                               'value',5e6,...
%                                               'weight',1);
%         calibrationData(1).power(2)  = struct('turbId',1,...
%                                               'value',5e6,...
%                                               'weight',1);
%         calibrationData(2).(...) = ...
%         ...
%

    % 1. Update FLORIS(x): update inputDatas with the to-be-evaluated parameters
    for ii = 1:length(calibrationData)
        for jj = 1:length(paramSet)
            % Overwrite model settings
            calibrationData(ii).inputData.(paramSet{jj}) = x(jj);
        end    
        % Update the derived settings (inflow conditions, model functions, ...)
        calibrationData(ii).inputData = processSettings(calibrationData(ii).inputData);
    end
    
    % 2. Determine error between FLORIS(x) and calibrationData
    J = J_cost(calibrationData);    
    
    % -------------------------------------------- %
    function J = J_cost(calibrationData)
    J = 0; % Initial cost

    % Determine cost of each struct entry using parallel computing
    parfor i = 1:length(calibrationData)
        Ji = 0; % Set local error to 0

        % Calculate the error in turbine powers
        outputData = floris_core(calibrationData(i).inputData,false);
        
        % Add squared error of power to the total cost
        if any(strcmp('power',fieldnames(calibrationData(i))))
            for iP = 1:length(calibrationData(i).power)
                Ji = Ji + calibrationData(i).power(iP).weight * ...
                    (calibrationData(i).power(iP).value - ...
                    outputData.power(calibrationData(i).power(iP).turbId))^2;
            end
    %         disp(['Cost due to power: ' num2str(Ji) '.']);
        end
        
        if any(strcmp('flow',fieldnames(calibrationData(i))))
            % Calculate the error in flow fields
            flowField.X = [calibrationData(i).flow.x];
            flowField.Y = [calibrationData(i).flow.y];
            flowField.Z = [calibrationData(i).flow.z];
            flowField.U = calibrationData(i).inputData.Ufun(flowField.Z) .* ...
                           ones(size(flowField.X));
            flowField.V = zeros(size(flowField.X));
            flowField.W = zeros(size(flowField.X));
            flowField.fixYaw = false;

            % Compute the flowfield velocity predicted by FLORIS
            [flowField] = floris_flowField(calibrationData(i).inputData,...
                                                   flowField,outputData.turbines,...
                                                   outputData.wakes);

            % Add squared error of flow to the total cost
            for iF = 1:length(calibrationData(i).flow)
                Ji = Ji + calibrationData(i).flow(iF).weight * ...
                    (calibrationData(i).flow(iF).value - flowField.U(iF))^2;
            end
        end

        J = J + Ji; % Add local squared error to global squared error
    end
    end
end

