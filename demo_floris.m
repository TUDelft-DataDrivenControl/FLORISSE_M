clear all; close all; clc;

% Initialize FLORIS class
FLORIS = floris();

% Run FLORIS with default settings
FLORIS.run();

% Plot FLORIS results
FLORIS.visualize();