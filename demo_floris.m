clear all; close all; clc;

% Initialize FLORIS class with default settings
FLORIS = floris();  

% Run FLORIS 
FLORIS.run();

% Plot FLORIS results
FLORIS.visualize(1,1,0);  % Options: visualize(Plot layout (T/F), plot 2D (T/F), plot 3D (T/F))