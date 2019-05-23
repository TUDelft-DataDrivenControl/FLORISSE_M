function [obsvJ] = sensitivityRose(florisRunnerIn,sensanalysis_WD_range,...
    WS_abssearchrange,TI_abssearchrange,WD_abssearchrange,noiseYaw,...
    noisePwr,wdMeasWeight)
% THIS FUNCTION CALCULATES THE SENSITIVITY FOR ONE SPECIFIC FLORISRUNNER
% OBJECT OVER THE COMPLETE WIND ROSE 

% Import variables
florisRunnerTrue = florisRunnerIn;

nTurbs = florisRunnerTrue.layout.nTurbs;
wsTrue = florisRunnerTrue.layout.ambientInflow.Vref;
wdTrue = florisRunnerTrue.layout.ambientInflow.windDirection;
tiTrue = florisRunnerTrue.layout.ambientInflow.TI0;

% Default inputs
if nargin < 6
    noiseYaw = 0;
    noisePwr = 0;
end 

nWdSensitivity = length(sensanalysis_WD_range);
nSubWS = length(WS_abssearchrange);
nSubTI = length(TI_abssearchrange);
nSubWD = length(WD_abssearchrange);

dwd_lengthscale = WD_abssearchrange(end)-WD_abssearchrange(1);
dws_lengthscale = WS_abssearchrange(end)-WS_abssearchrange(1);
dti_lengthscale = TI_abssearchrange(end)-TI_abssearchrange(1);

% Evaluate the cost function for the entire wind rose
% for WDi = 1:nWdSensitivity
parfor WDi = 1:nWdSensitivity
    florisRunnerLocal = copy(florisRunnerTrue); % Copy florisRunner obj
    
    wdTrue = sensanalysis_WD_range(WDi); % Update wdTrue
    powerTrue = evalForWD(florisRunnerTrue,wdTrue,wdTrue,0,0); % Calculate true power from FLORIS
    
    WD_subrange = wdTrue + WD_abssearchrange; % Determine absolute WD range
    [J,dxSqrd,msePwr] = deal(zeros(nSubTI,nSubWS,nSubWD));
    for WSii = 1:nSubWS
        wsEst = WS_abssearchrange(WSii); % Update estimated wind speed
        florisRunnerLocal.layout.ambientInflow.Vref = wsEst;
        dws = abs(wsTrue - wsEst);
        for TIii = 1:nSubTI
            tiEst = TI_abssearchrange(TIii);
            florisRunnerLocal.layout.ambientInflow.TI0 = tiEst;
            dti = abs(tiTrue - tiEst);
            for WDii = 1:nSubWD
                wdEst = WD_subrange(WDii);
                dwd = abs(wdEst-wdTrue); % Distance between arguments
                if dwd > pi % Radial distance
                    dwd = 2*pi - dwd;
                end
                if dwd < 0 || dwd > pi
                    error('Something went wrong here.')
                end
                
                powerOut = evalForWD(florisRunnerLocal,wdTrue,wdEst,noiseYaw,noisePwr);
                msePwr(TIii,WSii,WDii) = mean((powerOut-powerTrue).^2) * 1e-12;

%                 % Add measurement noise
%                 rmseNoise = 0.0 * 1e5; % noise in [W]
%                 rmsePwr(TIii,WSii,WDii) = max([0,rmsePwr(TIii,WSii,WDii)-rmseNoise*1e-6]);
                
                % Fix numerical errors
                if msePwr(TIii,WSii,WDii) < 10*eps
                    msePwr(TIii,WSii,WDii) = 0;
                end
                
                % squared distancedxSqrd
                dxSqrd_tmp = 0;
                if nSubWD > 1
                    dxSqrd_tmp = dxSqrd_tmp + (dwd / dwd_lengthscale)^2;
                end
                if nSubWS > 1
                    dxSqrd_tmp = dxSqrd_tmp + (dws / dws_lengthscale)^2;
                end
                if nSubTI > 1
                    dxSqrd_tmp = dxSqrd_tmp + (dti / dti_lengthscale)^2;
                end
                dxSqrd(TIii,WSii,WDii) = dxSqrd_tmp;
                
                % Calculate error (The lower J, the less observable the system is)
%                 J(TIii,WSii,WDii) = ...
%                     rmsePwr(TIii,WSii,WDii)/dxSqrd(TIii,WSii,WDii) + ... % Power RMSE
%                     wdMeasWeight*sqrt(nTurbs)*(dwd.^2); % Vane RMSE

                J(TIii,WSii,WDii) = ...
                    (msePwr(TIii,WSii,WDii) + wdMeasWeight*sqrt(nTurbs)*abs(dwd))/dxSqrd(TIii,WSii,WDii) ;
            end
        end
    end
        
    obsvJ(WDi) = min(J(~isnan(J) & dxSqrd > 1e-8)); % Find and save weakest link (least observable)
end
end


function powerOut = evalForWD(florisRunnerIn,windDirectionTrue,windDirectionEval,noiseYawAngles,noisePower)
% Default noise values
if nargin < 4
    noiseYawAngles = 0.0;
end
if nargin < 5
    noisePower = 0.0;
end

% Update and run
florisRunnerLocal = copy(florisRunnerIn);
florisRunnerLocal.clearOutput();
florisRunnerLocal.layout.ambientInflow.windDirection = windDirectionEval;

% % Maintain same relative yaw angle in wind-aligned frame
% florisRunnerLocal.controlSet.yawAngleWFArray = ...
%     florisRunnerLocal.controlSet.yawAngleWFArray + ...
%     noiseYawAngles * randn(1,florisRunnerLocal.layout.nTurbs);

% % Maintain same relative yaw angle in inertial frame
florisRunnerLocal.controlSet.yawAngleIFArray = ...
    windDirectionTrue * ones(1,florisRunnerLocal.layout.nTurbs) + ...
    noiseYawAngles   * randn(1,florisRunnerLocal.layout.nTurbs);
% disp(florisRunnerLocal.controlSet.yawAngleIFArray)

% Run and export power
florisRunnerLocal.run();
powerOut = [florisRunnerLocal.turbineResults.power] + ...
    noisePower * randn(1,florisRunnerLocal.layout.nTurbs);
end