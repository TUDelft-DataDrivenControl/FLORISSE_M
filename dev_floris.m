clear all; close all; clc;

% Initialize FLORIS class with specific set of settings
FLORIS = floris('9turb','NREL5MW','uniform','pitch','PorteAgel','Katic','PorteAgel');

% Run a single simulation
FLORIS.run();

% Generate 2D flow field visualization
FLORIS.visualize(0,1,0); 

% Test all possible combinations of options
for atmoType = {'uniform','boundary'}
    for controlType = {'pitch','greedy','axialInduction'}
        for wakeType = {'Zones','Gauss','Larsen','PorteAgel'}
            for wakeSum = {'Katic','Voutsinas'}
                for deflType = {'Jimenez','PorteAgel'}
                    FLORIS = floris('9turb','NREL5MW',atmoType{1},controlType{1},wakeType{1},wakeSum{1},deflType{1});
                    FLORIS.run();
%                     FLORIS.visualize(1,0,0);
                    clear FLORIS
                end
            end
        end
    end
end