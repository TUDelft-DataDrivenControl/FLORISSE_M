clear all; clc; close all;

%% Run a single simulation without optimization (G1)
disp('Running a single simulation...');
FLORIS_sim = floris('generic_2turb_scaled','TUM_G1','uniform','greedy',...
                    'PorteAgel','PorteAgel','Katic',...
                    'PorteAgel','PorteAgel_default'); % Initialize FLORIS class with specific settings
FLORIS_sim.run();            % Run a single simulation with the settings 'FLORIS.inputData'
FLORIS_sim.visualize(1,1,1,'WF'); % Generate a 2D visualization and a 3D visualization in wind-aligned frame
%FLORIS_sim.visualize(1,0,0,'WF'); 
disp(' '); disp(' ');

