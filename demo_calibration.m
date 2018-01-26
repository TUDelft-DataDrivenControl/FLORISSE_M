clear all; close all; clc;

% Initialize default FLORIS class
FLORIS = floris('2turb','NREL5MW','uniform','pitch','PorteAgel',...
                'Katic','PorteAgel');
           
%% Generate an example calibrationData for 9-turbine case, 2 flow measurements                          
calibrationData(1).caseName  = '2x1_5MW_WD270_yaw0'; % Case name, for personal use (not necessary)
calibrationData(1).inputData = FLORIS.inputData;     % Set of default inputData

% Flow measurements from LES/Experimental
calibrationData(1).flow(1)   = struct('x',153.64,'y',400.05,'z',90,... % Flow measurement at (x,y,z)
                                      'value',7.92,...               % Flow measurement value (U)
                                      'weight',1);                 % Weight in the cost function
calibrationData(1).flow(2)   = struct('x',537.73,'y',400.05,'z',90,... % Flow measurement at (x,y,z)
                                      'value',6.70,...               % Flow measurement value (U)
                                      'weight',0.3);                 % Weight in the cost function
calibrationData(1).flow(3)   = struct('x',921.83,'y',400.05,'z',90,... % Flow measurement at (x,y,z)
                                      'value',5.15,...               % Flow measurement value (U)
                                      'weight',0.7);                 % Weight in the cost function
calibrationData(1).flow(4)   = struct('x',1305.92,'y',400.05,'z',90,... % Flow measurement at (x,y,z)
                                      'value',3.51,...               % Flow measurement value (U)
                                      'weight',0.3);                 % Weight in the cost function
calibrationData(1).flow(5)   = struct('x',1690.02,'y',400.05,'z',90,... % Flow measurement at (x,y,z)
                                      'value',5.22,...               % Flow measurement value (U)
                                      'weight',0.7);                 % Weight in the cost function
                                  
  
% Power measurements from LES/Experimental                                                           
calibrationData(1).power(1)  = struct('turbId',1,...       % Turbine nr. corresponding to measurement
                                      'value',1685438,...  % Measured value (LES/experimental) in W
                                      'weight',1e-10);     % Weight in cost function                               
calibrationData(1).power(2)  = struct('turbId',2,...       % Turbine nr. corresponding to measurement
                                      'value',843140,...   % Measured value (LES/experimental) in W
                                      'weight',1e-10);      % Weight in cost function                                                         

% % Make a secondary artificial calibrationData struct()
% calibrationData(2) = calibrationData(1);
% calibrationData(2).inputData.uInfWf = 11.0;
% 
% % Make a third artificial calibrationData struct()
% calibrationData(3) = calibrationData(1);
% calibrationData(3).inputData.uInfWf = 10.0;


%% Manual cost function evaluations
% disp('Testing random calls to the cost function...');
% J=calibrationCostFunc([],{},calibrationData) % default values
% J=calibrationCostFunc([0.40,0.0040],{'ka','kb'},calibrationData) % overwrite ka, kb
% J=calibrationCostFunc([8.0,deg2rad(0.0)],{'uInfWf','windDirection'},calibrationData) % overwrite WS, WD
% J=calibrationCostFunc([8.0,deg2rad(90.)],{'uInfWf','windDirection'},calibrationData) % overwrite WS, WD
% J=calibrationCostFunc([8.0,deg2rad(180)],{'uInfWf','windDirection'},calibrationData) % overwrite WS, WD
% J=calibrationCostFunc([8.0,deg2rad(270)],{'uInfWf','windDirection'},calibrationData) % overwrite WS, WD

% %% Parameter optimization
% paramSet = {'ka','kb'}; % Parameters to be tuned
% x0 = [0.40,0.0040]; % Initial guess for parameters
% lb = [0.20,0.0020]; % Lower bound
% ub = [0.80,0.0080]; % Upper bound
% FLORIS.calibrate(paramSet,x0,lb,ub,calibrationData);

% %% Wind speed estimation
% paramSet = {'uInfWf','windDirection'}; % Parameters to be tuned
% x0 = [12.0,0.30]; % Initial guess for parameters
% lb = [04.0,-pi/2]; % Lower bound
% ub = [15.0,+pi/2]; % Upper bound
% FLORIS.calibrate(paramSet,x0,lb,ub,calibrationData);

%% TI estimation
paramSet = {'TI_0'}; % Parameters to be tuned
x0 = [0.05]; % Initial guess for parameters
lb = [0.00]; % Lower bound
ub = [0.25]; % Upper bound
FLORIS.calibrate(paramSet,x0,lb,ub,calibrationData);