function [avgGainPercent,minGainPercent,maxGainPercent,databaseLUTout] = runLUTcases(databaseLUT,florisRunner,WD_N,WD_std)
if nargin < 2
    % Wind direction profile
    WD_N = 1; % Number of points
    WD_std = 5*pi/180; % Standard dev. (rad)
end

% ------------------------------

nWS = databaseLUT.nWS;
nWD = databaseLUT.nWD;
nTI = databaseLUT.nTI;
WS_range = databaseLUT.WS_range;
WD_range = databaseLUT.WD_range;
TI_range = databaseLUT.TI_range;

% Create empty output tensors
[Pbl,Popt] = deal(zeros(nTI,nWS,nWD));

% Create probablistic wind direction profile
% Discretize probability distribution
if WD_N == 1
    rho_range = [0];
elseif WD_N == 2
    rho_range = [-0.5 0.5]*WD_std;
elseif WD_N == 3
    rho_range = [-1 0 1]*WD_std;
elseif WD_N == 4
    rho_range = [-1 -1/3 1/3 1]*WD_std;
elseif WD_N > 4
    rho_range = linspace(-WD_std*2,WD_std*2,WD_N);
else
    error('Please make sure WD_std is in radians, not degrees.');
end
if WD_std == 0
    error('Please specify a nonzero STD (even when WD_N == 1).');
end

fx = @(x) (1/WD_std) * (1/sqrt(2*pi)) * exp( (-x.^2)/(2*WD_std^2));
WD_probability = fx(rho_range); % Values from Normal dist.
WD_probability = WD_probability/sum(WD_probability); % Normalized

% Do runs
tic
disp(['Evaluating the average gain (%) for ' num2str(nTI) 'x' num2str(nWS) 'x' num2str(nWD) ' cases (' num2str(nTI*nWS*nWD) ').']);
for TIi = 1:nTI
    parfor WSi = 1:nWS
        for WDi = 1:nWD
            florisRunnerTmp = copy(florisRunner);
            florisRunnerTmp.layout.ambientInflow.TI0 = TI_range(TIi);
            florisRunnerTmp.layout.ambientInflow.Vref = WS_range(WSi);
            florisRunnerTmp.layout.ambientInflow.windDirection = WD_range(WDi)*pi/180;
            
            % Run baseline
            florisRunnerTmp.controlSet.yawAngleWFArray = zeros(1,florisRunnerTmp.layout.nTurbs);
            Pbl(TIi,WSi,WDi) = runLUTcases_runFLORIS(florisRunnerTmp,rho_range,WD_probability);
            
            % Run optimized
            for turbi = 1:florisRunnerTmp.layout.nTurbs
                florisRunnerTmp.controlSet.yawAngleWFArray(turbi) = databaseLUT.yawT{turbi}(TIi,WSi,WDi)*pi/180;
            end
            Popt(TIi,WSi,WDi) = runLUTcases_runFLORIS(florisRunnerTmp,rho_range,WD_probability);
        end
    end
end
toc
    
%% Calculate statistics
relGain = Popt(:)./Pbl(:) - 1;
relGain = relGain(~isnan(relGain) & ~isinf(relGain)); % Remove NaNs and Infs
minGainPercent = min(relGain)  * 100 % Percentage
maxGainPercent = max(relGain)  * 100 % Percentage
avgGainPercent = mean(relGain) * 100 % Percentage

%% Generate output database
databaseLUTout = databaseLUT;
databaseLUTout.Pbl  = Pbl;
databaseLUTout.Popt = Popt;
databaseLUTout.minGainPercent = minGainPercent;
databaseLUTout.maxGainPercent = maxGainPercent;
databaseLUTout.avgGainPercent = avgGainPercent;
end
