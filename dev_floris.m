clear all; close all; clc;

% Initialize FLORIS class with specific set of settings
FLORIS = floris('9turb','NREL5MW','uniform','pitch','PorteAgel','Katic','PorteAgel');

% Run a single simulation
FLORIS.run();

% Generate 2D flow field visualization
FLORIS.visualize(0,1,0); 