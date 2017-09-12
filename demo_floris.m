clear all; clc;

%% Run a single simulation without optimization
disp('Running a single simulation...');
FLORIS = floris('9turb','NREL5MW','uniform','pitch','PorteAgel','Katic','PorteAgel');
% FLORIS = floris('9turb','NREL5MW','uniform','pitch','PorteAgel','Katic','Jimenez');
% FLORIS = floris();          % Initialize FLORIS class. Default: floris('default','NREL5MW','9turb');
FLORIS.run();               % Run a single simulation with the settings 'FLORIS.inputData'
FLORIS.visualize(0,1,0);    % Generate all visualizations
% disp('Press a key to continue...'); pause;

%% Optimize yaw angles
FLORIS = floris();  % Initialize FLORIS class. Default: floris('default','NREL5MW','9turb');
FLORIS.inputData.yawAngles = zeros(1,9);     % Set all turbines to greedy
FLORIS.inputData.axialInd  = 0.33*ones(1,9); % Set all turbines to greedy
FLORIS.optimize(true,false);                 % Optimization for yaw angles: same as .optimizeYaw()
%disp('Press a key to continue...'); pause; disp('');

%% Optimize axial induction factor
FLORIS = floris();  % Initialize FLORIS class. Default: floris('default','NREL5MW','9turb');
FLORIS.inputData.yawAngles  = zeros(1,9);     % Set all turbines to greedy
FLORIS.inputData.bladePitch = zeros(1,9);     % Set all turbines to greedy
%FLORIS.inputData.axialInd  = 0.33*ones(1,9); % Set all turbines to greedy
FLORIS.optimize(false,true);                 % Optimization for axial ind: same as .optimizeAxInd()
%disp('Press a key to continue...'); pause; disp('');

%% Optimize both axial induction and yaw
FLORIS = floris();  % Initialize FLORIS class. Default: floris('default','NREL5MW','9turb');
FLORIS.inputData.yawAngles = zeros(1,9);     % Set all turbines to greedy
FLORIS.inputData.axialInd  = 0.33*ones(1,9); % Set all turbines to greedy
FLORIS.optimize(true,true);                  % Optimization for yaw angles and axial induction

%% Floris testoptions

for atmoType = {'uniform','boundary'}
    for controlType = {'pitch','greedy','axialInduction'}
        for wakeType = {'Zones','Gauss','Larsen','PorteAgel'}
            for wakeSum = {'Katic','Voutsinas'}
                for deflType = {'Jimenez','PorteAgel'}

FLORIS = floris('9turb','NREL5MW',atmoType{1},controlType{1},wakeType{1},wakeSum{1},deflType{1});
FLORIS.run();
FLORIS.visualize(1,0,0);
clear FLORIS
                end
            end
        end
    end
end