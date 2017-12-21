clear all; close all; clc;

% Initialize default FLORIS class
FLORIS = floris(); 
           
%% Generate an example calibrationData for 9-turbine case, 2 flow measurements                          
calibrationData(1).caseName  = '3x3_5MW_WD270_yaw0'; % Case name, for personal use (not necessary)
calibrationData(1).inputData = FLORIS.inputData;     % Set of default inputData

% Flow measurements from LES/Experimental
calibrationData(1).flow(1)   = struct('x',5.0,'y',5.0,'z',90,... % Flow measurement at (x,y,z)
                                      'value',8.0,...            % Flow measurement value (U)
                                      'weight',1.0);             % Weight in the cost function
calibrationData(1).flow(2)   = struct('x',150.0,'y',150.0,'z',90,... % Flow measurement at (x,y,z)
                                      'value',5.0,...           % Flow measurement value (U)
                                      'weight',0.5);            % Weight in the cost function

% Power measurements from LES/Experimental                                  
for i = 1:3                                  
    calibrationData(1).power(i)  = struct('turbId',i,...    % Turbine nr. corresponding to measurement
                                          'value',5e6,...   % Measured value (LES/experimental) in W
                                          'weight',1);      % Weight in cost function
end
for i = 4:6                                 
    calibrationData(1).power(i)  = struct('turbId',i,...    % Turbine nr. corresponding to measurement
                                          'value',4e6,...   % Measured value (LES/experimental) in W
                                          'weight',0.5);    % Weight in cost function
end
for i = 7:9                                 
    calibrationData(1).power(i)  = struct('turbId',i,...    % Turbine nr. corresponding to measurement
                                          'value',3e6,...   % Measured value (LES/experimental) in W
                                          'weight',0.2);    % Weight in cost function
end                                     

% Make a secondary artificial calibrationData struct()
calibrationData(2) = calibrationData(1);
calibrationData(2).inputData.uInfWf = 11.0;

% Make a third artificial calibrationData struct()
calibrationData(3) = calibrationData(1);
calibrationData(3).inputData.uInfWf = 10.0;


%% Manual cost function evaluations
disp('Testing random calls to the cost function...');
J=calibrationCostFunc([],{},calibrationData) % default values
J=calibrationCostFunc([0.40,0.0040],{'ka','kb'},calibrationData) % overwrite ka, kb
J=calibrationCostFunc([8.80,0.60],{'uInfWf','windDirection'},calibrationData) % overwrite WS, WD


%% Parameter optimization
paramSet = {'ka','kb'}; % Parameters to be tuned
x0 = [0.40,0.0040]; % Initial guess for parameters
lb = [0.20,0.0020]; % Lower bound
ub = [0.80,0.0080]; % Upper bound
FLORIS.calibrate(paramSet,x0,lb,ub,calibrationData);


%% Wind speed estimation
paramSet = {'uInfWf','windDirection'}; % Parameters to be tuned
x0 = [12.0,0.30]; % Initial guess for parameters
lb = [04.0,0.00]; % Lower bound
ub = [15.0,0.60]; % Upper bound
FLORIS.calibrate(paramSet,x0,lb,ub,calibrationData);