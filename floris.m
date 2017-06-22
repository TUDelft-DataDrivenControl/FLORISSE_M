classdef floris<handle
    properties
        inputData
        outputData
        outputDataAEP
    end
    methods        
        %% Initialization
        function self = init(self,modelType,turbType,siteType)
            addpath('functions');
            
            % Default setup
            if exist('siteType') == 0;  siteType  = '9turb';   end;
            if exist('turbType') == 0;  turbType  = 'NREL5MW'; end;
            if exist('modelType')== 0;  modelType = 'default'; end;
            
            % Call function
            self.inputData = floris_loadSettings(modelType,turbType,siteType);
        end
       
        % Optimization functions etc. can be added here
        % ....
        % ....
        
        %% FLORIS single execution
        function [self,outputData] = run(self,inputData)
            % Check if inputData specified manually. If not, use internal inputData.
            if exist('inputData') == 0; inputData = self.inputData; end;
            
            % Check if init() has been run at least once before.
            if isstruct(inputData)== 0;
                disp([' Please initialize the model before simulation by the init() command.']);
                return;
            end;
            
            % Run FLORIS simulation
            [self.inputData,self.outputData] = floris_run(inputData);
            
            % Results saved internally, but also returns externally if desired.
            if nargout > 0; outputData = self.outputData; end;
        end
        
        
        %% Visualize single FLORIS simulation results
        function [] = visualize(self,plotLayout,plot2D,plot3D)
            inputData  = self.inputData;
            outputData = self.outputData;
            
            if isstruct(outputData) == 0
                disp([' outputData is not (yet) available/not formatted properly.' ...
                      ' Please run a (single) simulation, then call this function.']);
                return;
            end; 
            
            % Default visualization settings, if not specified
            if exist('plotLayout') == 0; plotLayout = true;  end;
            if exist('plot2D')     == 0; plot2D     = true;  end;
            if exist('plot3D')     == 0; plot3D     = false; end;
            
            % Set visualization settings
            inputData.plotLayout      = plotLayout;
            inputData.plot2DFlowfield = plot2D;
            inputData.plot3DFlowfield = plot3D;
            
            floris_visualization(inputData,outputData);
        end;
        
        
        %% Run FLORIS AEP calculations (multiple wind speeds and directions)
        function [self,outputDataAEP] = AEP(self,windRose)
            % WindRose is an N x 2 matrix with uIf in 1st column and 
            % vIf in 2nd. The simulation will simulate FLORIS for each row.
            inputData = self.inputData;
            
            % Simulate over each uIf-vIf set (matrix row)
            for i = 1:size(windRose,1);
                inputData.uInfIf      = WS_range(windRose,1);
                inputData.vInfIf      = WS_range(windRose,2);
                self.outputDataAEP{i} = floris_run(inputData);
            end;
            
            % Results saved internally, but also returns externally if desired.
            if nargout > 0; outputDataAEP = self.outputDataAEP; end;
        end        
    end
end