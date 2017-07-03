classdef floris<handle
    properties
        inputData
        outputData
        outputFlowField
        outputDataAEP
    end
    methods
        %% Constructor function initializes default inputData
        function self = floris(modelType,turbType,siteType)
            addpath('functions');
            
            % Default setup
            if ~exist('siteType','var');    siteType  = '9turb';   end;
            if ~exist('turbType','var');    turbType  = 'NREL5MW'; end;
            if ~exist('modelType','var');   modelType = 'default'; end;
            
            % Call function
            self.inputData = floris_loadSettings(modelType,turbType,siteType);
        end
        
        
        
        %% FLORIS single execution
        function [self,outputData] = run(self)
            % Run FLORIS simulation and reset visualization
            [self.outputData] = floris_core(self.inputData);
            self.outputFlowField = [];
            
            % Results saved internally, but also returns externally if desired.
            if nargout > 0; outputData = self.outputData; end;
        end
        
      
        function [self] = optimize(self,optimizeYaw,optimizeAxInd);
            inputData = self.inputData;
            disp(['Performing optimization: optimizeYaw = ' num2str(optimizeYaw) ', optimizeAxInd: ' num2str(optimizeAxInd) '.']);
            
            % Define initial guess and bounds
            x0 = []; lb = []; ub = [];
            if optimizeYaw;   
                x0 = [x0, inputData.yawAngles]; 
                lb = [lb, deg2rad(-25)*ones(inputData.nTurbs,1)];
                ub = [ub, deg2rad(+25)*ones(inputData.nTurbs,1)];
            end;
            if optimizeAxInd; 
                x0 = [x0, inputData.AxInd];     
                lb = [lb, 0.000*ones(length(self.inputData.axialInd),1)];
                ub = [ub, 0.333*ones(length(self.inputData.axialInd),1)];
            end;
            
            % Cost function
            function J = costFunction(x,inputData,optimizeYaw,optimizeAxInd)
                if optimizeYaw;   inputData.yawAngles = x(1:inputData.nTurbs); end;
                if optimizeAxInd; inputData.AxInd     = x(end-nTurbs+1:end);   end;

                [outputData] = floris_core(inputData,0);
                J            = -sum(outputData.power);
            end
            
            cost = @(x)costFunction(x,self.inputData,optimizeYaw,optimizeAxInd);
              
            % Optimizer settings and optimization execution
            %options = optimset('Display','final','MaxFunEvals',1000 ); % Display nothing
            %options = optimset('Algorithm','sqp','Display','final','MaxFunEvals',1000,'PlotFcns',{@optimplotx, @optimplotfval} ); % Display convergence
            options = optimset('Display','final','MaxFunEvals',1000,'PlotFcns',{@optimplotx, @optimplotfval} ); % Display convergence
            xopt    = fmincon(cost,x0,[],[],[],[],lb,ub,[],options);
            
            % Simulated annealing
            %options = optimset('Display','iter','MaxFunEvals',1000,'PlotFcns',{@optimplotx, @optimplotfval} ); % Display convergence
            %xopt    = simulannealbnd(cost,self.inputData.axialInd,lb,ub,options);
            
            % Overwrite current settings with optimized
            if optimizeYaw;   self.inputData.yawAngles = xopt(1:inputData.nTurbs); end;
            if optimizeAxInd; self.inputData.AxInd     = xopt(end-nTurbs+1:end);   end;
            
            % Update outputData for optimized settings
            self.run(); 
            
            % Display improvements
            P_bl  = -costFunction(x0,  inputData,optimizeYaw,optimizeAxInd); % Calculate baseline power
            P_opt = -costFunction(xopt,inputData,optimizeYaw,optimizeAxInd); % Calculate optimal power
            disp(['Initial power: ' num2str(P_bl/10^6) ' MW']);
            disp(['Optimized power: ' num2str(P_opt/10^6) ' MW']);
            disp(['Relative increase: ' num2str((P_opt/P_bl-1)*100) '%.']);
            end;
            
            function [self] = optimizeYaw(self)
                self.optimize(true,false);
            end;
            function [self] = optimizeAxInd(self)
                self.optimize(false,true);
            end;
                       
            
            %% Visualize single FLORIS simulation results
            function [] = visualize(self,plotLayout,plot2D,plot3D)
                
                % Check if there is output data available for plotting
                if ~isstruct(self.outputData)
                    disp([' outputData is not (yet) available/not formatted properly.' ...
                        ' Please run a (single) simulation, then call this function.']);
                    return;
                end;
                
                % Default visualization settings, if not specified
                if ~exist('plotLayout','var');  plotLayout = true;  end;
                if ~exist('plot2D','var');      plot2D     = true;  end;
                if ~exist('plot3D','var');      plot3D     = false; end;
                
                % Set visualization settings
                self.outputFlowField.plotLayout      = plotLayout;
                self.outputFlowField.plot2DFlowfield = plot2D;
                self.outputFlowField.plot3DFlowfield = plot3D;
                
                self.outputFlowField = floris_visualization(self.inputData,self.outputData,self.outputFlowField);
            end;
            
            
            %% Run FLORIS AEP calculations (multiple wind speeds and directions)
            function [self,outputDataAEP] = AEP(self,windRose)
                % WindRose is an N x 2 matrix with uIf in 1st column and
                % vIf in 2nd. The simulation will simulate FLORIS for each row.
                
                % Simulate over each uIf-vIf set (matrix row)
                for i = 1:size(windRose,1);
                    self.inputData.uInfIf       = windRose(i,1);
                    self.inputData.vInfIf       = windRose(i,2);
                    [self.outputDataAEP{i}]   = self.run();
                end;
                
                % Results saved internally, but also returns externally if desired.
                if nargout > 0; outputDataAEP = self.outputDataAEP; end;
            end
        end
    end