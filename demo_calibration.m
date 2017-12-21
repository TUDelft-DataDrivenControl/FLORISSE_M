clear all; close all; clc;

% Initialize default FLORIS class
FLORIS = floris(); 
           
%% Generate an example calibrationData for 9-turbine case, 2 flow measurements                          
calibrationData(1).caseName  = '3x3_5MW_WD270_yaw0';
calibrationData(1).inputData = FLORIS.inputData;
calibrationData(1).flow(1)   = struct('x',5.0,'y',5.0,'z',90,...
                                      'value',8.0,...
                                      'weight',1.0);
calibrationData(1).flow(2)   = struct('x',150.0,'y',150.0,'z',90,...
                                      'value',5.0,...
                                      'weight',0.5);
for i = 1:3                                  
    calibrationData(1).power(i)  = struct('turbId',i,...
                                          'value',5e6,...
                                          'weight',1);
end
for i = 4:6                                 
    calibrationData(1).power(i)  = struct('turbId',i,...
                                          'value',4e6,...
                                          'weight',0.5);
end
for i = 7:9                                 
    calibrationData(1).power(i)  = struct('turbId',i,...
                                          'value',3e6,...
                                          'weight',0.2);
end                                     

% Make a secondary calibrationData artificially
calibrationData(2) = calibrationData(1);
calibrationData(2).inputData.uInfWf = 11.0;

% Make a third calibrationData artificially
calibrationData(3) = calibrationData(1);
calibrationData(3).inputData.uInfWf = 10.0;


%% Cost function evaluation
disp('Test random calls to the cost function...');
J=calibrationCostFunc([],{},calibrationData); % default values
J=calibrationCostFunc([0.40,0.0040],{'ka','kb'},calibrationData); % overwrite ka, kb
J=calibrationCostFunc([8.80,0.60],{'uInfWf','windDirection'},calibrationData); % overwrite WS, WD


%% Parameter optimization
paramSet = {'ka','kb'};
x0 = [0.40,0.0040];
lb = [0.20,0.0020];
ub = [0.80,0.0080];
FLORIS.calibrate(paramSet,x0,lb,ub,calibrationData);


%% Wind speed estimation
paramSet = {'uInfWf','windDirection'};
x0 = [12.0,0.30];
lb = [04.0,0.00];
ub = [15.0,0.60];
FLORIS.calibrate(paramSet,x0,lb,ub,calibrationData);