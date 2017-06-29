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
       
        % Optimization functions etc. can be added here
        % ....
        % ....
        
        %% FLORIS single execution
        function [self,outputData] = run(self)

            % Check if there ipnutdata has been specified
            if ~isstruct(self.inputData)
                disp(' Please make sure FLORIS.inputData contains valid inputdata');
                return;
            end;
            
            % Run FLORIS simulation and reset visualization
            [self.outputData] = floris_core(self.inputData);
            self.outputFlowField = [];
            
            % Results saved internally, but also returns externally if desired.
            if nargout > 0; outputData = self.outputData; end;
        end
        
        
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