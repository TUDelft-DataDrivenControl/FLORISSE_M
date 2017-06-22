clear all; close all; clc;

% Initialize FLORIS class 
FLORIS = floris();  

% Initialize model settings
FLORIS.init(); % This chooses the default setting, which is: FLORIS.init('default','NREL5MW','9turb');

% Run FLORIS with default settings
FLORIS.run();

% Plot FLORIS results
FLORIS.visualize();  % Options: visualize(Plot layout (T/F), plot 2D (T/F), plot 3D (T/F))