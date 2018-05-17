classdef floris<handle
    properties
        inputData
        outputData
        outputFlowField
        outputDataAEP
    end
    methods
        %% Constructor function initializes default inputData
        function self = floris(siteType,turbType,atmoType,controlType,...
                        wakeDeficitModel,wakeDeflectionModel,wakeSumModel,...
                        wakeTurbulenceModel,modelDataFile)
            
            addpath(genpath('inputFiles'))    % Input functions
            addpath(genpath('coreFunctions')) % Model functions
            addpath('submodelDefinitions')    % Model functions
%             addpath('florisCoreFunctions'); % Airfoil data
            
            % Default setup settings (see in floris_loadSettings.m for explanations)
            if ~exist('siteType','var');            siteType            = 'generic_9turb'; end % Wind farm topology ('1turb','9turb')
            if ~exist('turbType','var');            turbType            = 'nrel5mw';    end % Turbine type ('NREL5MW')
            if ~exist('atmoType','var');            atmoType            = 'uniform';    end % Atmospheric inflow ('uniform','boundary')
            if ~exist('controlType','var');         controlType         = 'pitch';      end % Actuation method ('pitch','greedy','axialInduction')         
            if ~exist('wakeDeficitModel','var');    wakeDeficitModel    = 'PorteAgel';  end % Single wake model ('Zones','Gauss','Larsen','PorteAgel')
            if ~exist('wakeDeflectionModel','var'); wakeDeflectionModel = 'PorteAgel';  end % Single wake model ('Zones','Gauss','Larsen','PorteAgel')
            if ~exist('wakeSumModel','var');        wakeSumModel        = 'Katic';      end % Wake addition method ('Katic','Voutsinas')
            if ~exist('wakeTurbulenceModel','var'); wakeTurbulenceModel = 'PorteAgel';  end % Turbine-induced turbulence ('PorteAgel','nothing')
            if ~exist('modelDataFile','var');       modelDataFile       = 'PorteAgel_default';  end % Single wake model ('Zones','Gauss','Larsen','PorteAgel')

            % Site definition
            run([siteType]); 
            
            % Turbine specifications
            run(['turbineDefinitions/' turbType '/specifications.m']); 
            inputData.rotorRadius           = turbine.rotorRadius   * ones(1,nTurbs);
            inputData.generator_efficiency  = turbine.genEfficiency * ones(1,nTurbs);
            inputData.hub_height            = turbine.hubHeight     * ones(1,nTurbs);
            inputData.pP                    = turbine.pP; % yaw power correction parameter
            inputData.LocIF(:,3)            = inputData.hub_height;
            inputData.rotorArea             = pi*inputData.rotorRadius.^2;
            
            % Create single wake model object
            inputData.wakeModel = createWakeObject(wakeDeflectionModel,...
                                                   wakeDeficitModel,...
                                                   wakeSumModel,...
                                                   wakeTurbulenceModel,...
                                                   modelDataFile);
            
            %% Turbine axial control methodology
            % Herein we define how the turbine are controlled. In the traditional
            % FLORIS model, we directly control the axial induction factor of each
            % turbine. However, to apply this in practise, we still need a mapping to
            % the turbine generator torque and the blade pitch angles. Therefore, we
            % have implemented the option to directly control and optimize the blade
            % pitch angles 'pitch', under the assumption of optimal generator torque
            % control. Additionally, we can also assume fully greedy control, where we
            % cannot adjust the generator torque nor the blade pitch angles ('greedy').
            
            switch controlType
                case {'pitch'}
                    % Choice of how a turbine's axial control setting is determined
                    % 0: use pitch angles and Cp-Ct LUTs for pitch and WS,
                    % 1: greedy control   and Cp-Ct LUT for WS,
                    % 2: specify axial induction directly.
                    inputData.axialControlMethod = 0;
                    inputData.pitchAngles = zeros(1,nTurbs); % Blade pitch angles, by default set to greedy
                    inputData.axialInd    = nan*ones(1,nTurbs); % Axial inductions  are set to NaN to find any potential errors
                    
                    % Determine Cp and Ct interpolation functions as a function of WS and blade pitch
                    for airfoilDataType = {'cp','ct'}
                        lut       = csvread(['turbineDefinitions/' turbType '/' airfoilDataType{1} 'Pitch.csv']); % Load file
                        lut_ws    = lut(1,2:end);          % Wind speed in LUT in m/s
                        lut_pitch = deg2rad(lut(2:end,1)); % Blade pitch angle in LUT in radians
                        lut_value = lut(2:end,2:end);      % Values of Cp/Ct [dimensionless]
                        inputData.([airfoilDataType{1} '_interp']) = @(ws,pitch) interp2(lut_ws,lut_pitch,lut_value,ws,pitch);
                    end
                    
                    % Greedy control: we cannot adjust gen torque nor blade pitch
                case {'greedy'}
                    inputData.axialControlMethod = 1;
                    inputData.pitchAngles = nan*ones(1,nTurbs); % Blade pitch angles are set to NaN to find any potential errors
                    inputData.axialInd    = nan*ones(1,nTurbs); % Axial inductions  are set to NaN to find any potential errors
                    
                    % Determine Cp and Ct interpolation functions as a function of WS
                    lut                 = load(['turbineDefinitions/' turbType '/cpctgreedy.mat']);
                    inputData.cp_interp = @(ws) interp1(lut.wind_speed,lut.cp,ws);
                    inputData.ct_interp = @(ws) interp1(lut.wind_speed,lut.ct,ws);
                    
                    % Directly adjust the axial induction value of each turbine.
                case {'axialInduction'}
                    inputData.axialControlMethod = 2;
                    inputData.pitchAngles = nan*ones(1,nTurbs); % Blade pitch angles are set to NaN to find any potential errors
                    inputData.axialInd    = 1/3*ones(1,nTurbs); % Axial induction factors, by default set to greedy
                    
                otherwise
                    error(['Control methodology with name: "' controlType '" not defined']);
            end
            
            self.inputData = inputData;
        end
        
        
        
        %% FLORIS single execution
        function [outputData] = run(self)
            % Run a new FLORIS simulation and additionally reset existing
            % output data (e.g., old flow field)
            [self.outputData] = floris_core(self.inputData);
            self.outputFlowField = [];
            
            % Results saved internally, but also returns externally if desired.
            if nargout > 0; outputData = self.outputData; end
        end
        
        
        %% FLORIS control optimization
        function [] = optimize(self,optimizeYaw,optimizeAxInd,optimizeTurbines)
            % This function will optimize the turbine yaw angles and/or the
            % turbine axial induction factors (blade pitch angles) to
            % maximize the power output of the wind farm. 
            % If only a subset of turbine shall be optimized,
            % the (optional) vector 'optimizeTurbines' should contain the
            % numbers/IDs of the turbines to be optimized.
            
            if nargin==3 % 'optimizeTurbines' not specified, optimize all turbines
                optimizeTurbines=1:self.inputData.nTurbs;
            end
            
            inputData = self.inputData;
            disp(['Performing optimization: optimizeYaw = ' num2str(optimizeYaw) ', optimizeAxInd: ' num2str(optimizeAxInd) '.']);
            
            % Define initial guess x0, lower bounds lb, and upper bounds ub
            x0 = []; lb = []; ub = [];
            if optimizeYaw  
                x0 = [x0, inputData.yawAngles(optimizeTurbines)];
                lb = [lb, deg2rad(-25)*ones(length(optimizeTurbines),1)];
                ub = [ub, deg2rad(+25)*ones(length(optimizeTurbines),1)];
            end
            if optimizeAxInd
                if inputData.axialControlMethod == 0
                    x0 = [x0, inputData.pitchAngles(optimizeTurbines)];  
                    lb = [lb, deg2rad(0.0)*ones(length(optimizeTurbines),1)];
                    ub = [ub, deg2rad(5.0)*ones(length(optimizeTurbines),1)];
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
                    x0 = [x0, inputData.axialInd(optimizeTurbines)];     
                    lb = [lb, 0.0*ones(length(optimizeTurbines),1)];
                    ub = [ub, 1/3*ones(length(optimizeTurbines),1)];
                end
            end
            
            % Cost function that is to be optimized. Basically, J = -sum(P).
            function J = costFunction(x,inputData,optimizeYaw,optimizeAxInd,optimizeTurbines)
                % 'x' contains the to-be-optimized control variables. This
                % can be yaw angles, blade pitch angles, or both. Hence,
                % depending on these choices, we have to first extract the
                % yaw angles and/or blade pitch angles back from x, before
                % we trial them in a FLORIS simulation. That is what we do next:
                if optimizeYaw
                    inputData.yawAngles(optimizeTurbines) = x(1:length(optimizeTurbines));
                end
                if optimizeAxInd
                    if inputData.axialControlMethod == 0
                        inputData.pitchAngles(optimizeTurbines) = x(end-length(optimizeTurbines)+1:end);
                    elseif inputData.axialControlMethod == 2
                        inputData.axialInd(optimizeTurbines)    = x(end-length(optimizeTurbines)+1:end); 
                    end
                end

                % Then, we simulate FLORIS and determine the cost J(x)
                [outputData] = floris_core(inputData,0);
                J            = -sum(outputData.power);
            end
            
            cost = @(x)costFunction(x,self.inputData,optimizeYaw,optimizeAxInd,optimizeTurbines);
              
            % Optimizer settings and optimization execution
            %options = optimset('Display','final','MaxFunEvals',1000 ); % Display nothing
            %options = optimset('Algorithm','sqp','Display','final','MaxFunEvals',1000,'PlotFcns',{@optimplotx, @optimplotfval} ); % Display convergence
            options = optimset('Display','final','MaxFunEvals',1e4,'PlotFcns',{@optimplotx, @optimplotfval} ); % Display convergence
            xopt    = fmincon(cost,x0,[],[],[],[],lb,ub,[],options);
            
            % Simulated annealing
            %options = optimset('Display','iter','MaxFunEvals',1000,'PlotFcns',{@optimplotx, @optimplotfval} ); % Display convergence
            %xopt    = simulannealbnd(cost,self.inputData.axialInd,lb,ub,options);
            
            % Display improvements
            P_bl  = -costFunction(x0,  inputData,optimizeYaw,optimizeAxInd,optimizeTurbines); % Calculate baseline power
            P_opt = -costFunction(xopt,inputData,optimizeYaw,optimizeAxInd,optimizeTurbines); % Calculate optimal power
            disp(['Initial power: ' num2str(P_bl/10^6) ' MW']);
            disp(['Optimized power: ' num2str(P_opt/10^6) ' MW']);
            disp(['Relative increase: ' num2str((P_opt/P_bl-1)*100) '%.']);
            
            % Overwrite current settings with optimized oness
            if P_opt > P_bl
                if optimizeYaw; self.inputData.yawAngles(optimizeTurbines) = xopt(1:length(optimizeTurbines)); end
                if optimizeAxInd
                    if inputData.axialControlMethod == 0
                        self.inputData.pitchAngles(optimizeTurbines) = xopt(end-length(optimizeTurbines)+1:end); 
                        self.inputData.axialInd(optimizeTurbines)    = NaN*ones(1,length(optimizeTurbines));
                        % The implicit values for axialInd calculated from
                        % blade pitch angles can be found in outputData,
                        % under the 'turbine.axialInd' substructure.
                    elseif inputData.axialControlMethod == 2
                        self.inputData.pitchAngles(optimizeTurbines) = NaN*ones(1,length(optimizeTurbines));
                        self.inputData.axialInd(optimizeTurbines)    = xopt(end-length(optimizeTurbines)+1:end); 
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
        
        
        %% Visualize single FLORIS simulation results
        function [] = visualize(self,plotLayout,plot2D,plot3D,frame)

            % Check if there is output data available for plotting
            if ~isstruct(self.outputData)
                disp([' outputData is not (yet) available/not formatted properly.' ...
                    ' Please run a (single) simulation, then call this function.']);
                return;
            end

            % Default visualization settings, if not specified
            if ~exist('plotLayout','var');  plotLayout = false; end
            if ~exist('plot2D','var');      plot2D     = false; end
            if ~exist('plot3D','var');      plot3D     = true;  end
            if ~exist('frame','var');       frame      = 'IF';  end
            % Set visualization settings
            self.outputFlowField.plotLayout      = plotLayout;
            self.outputFlowField.plot2DFlowfield = plot2D;
            self.outputFlowField.plot3DFlowfield = plot3D;
            
            % Call the visualization function
            self.outputFlowField = floris_visualization(self.inputData,self.outputData,self.outputFlowField,frame);
        end
    end
end