function [outputArg1,outputArg2] = mainplotter(florisRunner)
%MAINPLOTTER Summary of this function goes here
%   Detailed explanation goes here

% Check if there is output data available for plotting
if ~florisRunner.has_run()
    disp([' outputData is not (yet) available/not formatted properly.' ...
        ' Please run a (single) simulation, then call this function.']);
    return
end

% Default visualization settings, if not specified
if ~exist('plotLayout','var');  plotLayout = false; end
if ~exist('plot2D','var');      plot2D     = true; end
if ~exist('plot3D','var');      plot3D     = false;  end
if ~exist('frame','var');       frame      = 'IF';  end
% Set visualization settings
self.outputFlowField.plotLayout      = plotLayout;
self.outputFlowField.plot2DFlowfield = plot2D;
self.outputFlowField.plot3DFlowfield = plot3D;

% Call the visualization function
self.outputFlowField = floris_visualization(self.inputData,self.outputData,self.outputFlowField,frame);
end
