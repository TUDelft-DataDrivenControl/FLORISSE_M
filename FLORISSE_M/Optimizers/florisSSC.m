% clear all; close all; clc;
%
% MATLAB can use zeroMQ, but it is not necessarily so straight-forward. The easiest solution found was
% using "jeroMQ", which can be downloaded from https://github.com/zeromq/jeromq. After installation,
% Update the path below and you should be all set.
%
% For more information, check out:
% https://mathworks.com/matlabcentral/answers/269061-how-do-i-integrate-zeromq-library-with-matlab-i-want-my-matlab-program-to-be-a-subscriber-of-zeromq
% 
% Note: to install jeroMQ, you need to have 'maven' installed. When using Maven to install jeroMQ,
% you may run into an error about the unit testing. If so, disable them and run again using
% 'mvn install -DskipTests'
%
% Recommended Java JDK version: 1.8.0_171 (tested by excluding unit tests)
%
%

% Setup zeroMQ server
% zmqServer = zeromqObj('/home/bmdoekemeijer/OpenFOAM/zeroMQ/jeromq-0.4.4-SNAPSHOT.jar',1085,3600,true);

% Add FLORIS path and setup layout
addpath(genpath('FLORISSE_M/FLORISSE_M'))
turbines = struct('turbineType', dtu10mw() , ...
                      'locIf', {[608.0  964.8]; [608.0  1500.0]; [608.0  2035.2]; ...
                                [1500.0 964.8]; [1500.0 1500.0]; [1500.0 2035.2];...
                                [2392.0 964.8]; [2392.0 1500.0]; [2392.0 2035.2]});
layout = layout_class(turbines, 'ccta_9turb'); 

% Purposely initialize with poor initial conditions (to assess estimation)
%layout.ambientInflow = ambient_inflow_log('WS', 8.0,'HH', 90.0,'WD', 0,'TI0', .06);
layout.ambientInflow = ambient_inflow_log('WS', 6.5,'HH', 119.0,'WD', deg2rad(0.0),'TI0', .01);
controlSet = control_set(layout, 'yawAndRelPowerSetpoint');
subModels = model_definition('','rans','','selfSimilar','','quadraticRotorVelocity','', 'crespoHernandez');                    
florisRunner = floris(layout, controlSet, subModels);

% Set FLORIS model parameters to the values found by offline calibration
xopt = [-0.001338132885368   3.160208854425835  -0.002675041439218  0.327610240042950   0.174472079310193   0.000968572145479]; % From constrained optimization: fitFLORIS.m  
florisOpt.model.modelData.ad    = xopt(1);
florisOpt.model.modelData.alpha = xopt(2);
florisOpt.model.modelData.bd    = xopt(3);
florisOpt.model.modelData.beta  = xopt(4);
florisOpt.model.modelData.ka	= xopt(5);
florisOpt.model.modelData.kb    = xopt(6);

% Initial control settings
yawAngleArrayOut   = 270.0*ones(1,layout.nTurbs);
pitchAngleArrayOut = 0.0*ones(1,layout.nTurbs);
controlTimeInterval  = 600; % Time to wait after applying control signal
measurementSignalAvgTime = 300; % Time to average data. Needs to be >= controlTimeInterval
sigma_WD = deg2rad(6)  % 6 deg for 8 m/s by M. Bertele, WES
dataSend = setupZmqSignal(yawAngleArrayOut,pitchAngleArrayOut);

disp(['Entering wind farm controller loop...']);
timeLastControl = 20e3; % -Inf: optimize right away. 0: optimize after controlTimeInterval (no prec), 20e3: optimize after controlTimeInterval (with prec)
[timeVector,measurementVector] = deal([]);
firstRun = true;
while 1
    % Receive information from SOWFA
    dataReceived = zmqServer.receive();
    currentTime  = dataReceived(1,1);
    timeVector = [timeVector; currentTime];
    measurementVector = [measurementVector;dataReceived(1,2:end)];
    
    if firstRun
        dt = rem(currentTime,10)
        firstRun = false;
    end
    
    % Optimize periodically
    if currentTime-timeLastControl >= controlTimeInterval
        disp([datestr(rem(now,1)) '__ Optimizing control at timestamp ' num2str(currentTime) '.']);
        
        % Estimation
        if currentTime >= controlTimeInterval % Past 1st iteration
			% Set up measurements
            measurementIndcs = (timeVector >= (currentTime-measurementSignalAvgTime))
            avgMeasurementVector = mean(measurementVector(measurementIndcs,:),1)
            
            avgMeasurementVector = [20600 3810310 0.66227 681543 4495240 0.69934 758867 3134130 0.62209 595549 1266930 0.51712 347243 1199360 0.51253 333170 1272250 0.51836 351617 1375870 0.52507 358749 1411330 0.52628 364487 1867250 0.55507 436976];
			powerMeasurements = avgMeasurementVector(2:3:end) / 1.225; % Correction fluidDensity
			measurementSet = struct();
			measurementSet.P = struct('values',powerMeasurements,'stdev',[1 1 1 1 1 1 1 1 1]);
			measurementSet.estimParams = {'TI0','Vref'}
			disp(measurementSet.P.values)
			
			disp([datestr(rem(now,1)) '__    Doing estimation cycle.']);
			florisRunner.clearOutput;
			
			% Update WD first
			disp('WD:')
			WD_measurements = 0.+sigma_WD*randn(1,9) % U=8m/s -> std = 6 deg. according to https://www.wind-energ-sci.net/2/615/2017/wes-2-615-2017.pdf
			florisRunner.layout.ambientInflow.windDirection = mean(WD_measurements);
            florisRunner.controlSet.yawAngleIFArray = florisRunner.controlSet.yawAngleIFArray;
			disp(mean(WD_measurements))
			
			% Update WS and TI secondly
            lb = [3  6]';       % [TI WS]
            ub = [15.0  12]';   % [TI WS]
            xopt = estimatorGP(florisRunner,measurementSet,lb,ub);
            
%           estTool = estimator({florisRunner},{measurementSet});
% 			xopt = estTool.gaEstimation([0.03 6.5],[0.20 10.0]) % Estimate
            
			florisRunner.layout.ambientInflow.TI0  = xopt(1);
			florisRunner.layout.ambientInflow.Vref = xopt(2);
			clear xopt
        end
        
        % Optimization
		WD_uncertainty = sigma_WD/sqrt(length(WD_measurements)); % Uncertainty decreases with sqrt(N)
        disp([datestr(rem(now,1)) '__    Doing optimization cycle.']);
        tic;
        [xopt,P_bl,P_opt] = yawOptimizerGP(florisRunner,WD_uncertainty);
        toc
        
        [xopt2,P_bl2,P_opt2] = optimizeControlSettingsRobust(florisRunner,'yawOpt',true,'pitchOpt',false,'axOpt',false,WD_uncertainty,5,true)
%         [xopt,P_bl,P_opt] = optimizeControlSettingsRobust(florisRunner,'yawOpt',true,'pitchOpt',false,'axOpt',false,0.01,1,true)
        florisRunner.controlSet.yawAngleWFArray = florisRunner.controlSet.yawAngleWFArray;
        yawAngleArrayIF = florisRunner.controlSet.yawAngleIFArray;
        pitchAngleArray = zeros(size(yawAngleArrayIF));
                
        % Update message string
        yawAngleArrayOut   = round(270.-rad2deg(yawAngleArrayIF),1);
        pitchAngleArrayOut = round(rad2deg(pitchAngleArray),1);        
        disp([datestr(rem(now,1)) '__    Synthesizing message string.']);
        dataSend = setupZmqSignal(yawAngleArrayOut,pitchAngleArrayOut);
        
        % Update time stamp
        timeLastControl = currentTime;
        [timeVector,measurementVector] = deal([]);
    end
    
    % Send a message (control action) back to SOWFA
    zmqServer.send(dataSend);
end
% Close connection
zmqServer.disconnect()

function [dataOut] = setupZmqSignal(yawAngles,pitchAngles)
	dataOut = [];
    for i = 1:length(yawAngles)
        dataOut = [dataOut yawAngles(i) pitchAngles(i)];
    end
end