function [costMatrix] = calculateCostRose(layouts,trueRange,relSearchRange)
addpath(genpath('../../FLORISSE_M'))
addpath('bin')

%% Setup
% Construct farms
for i = 1:length(layouts)
    florisRunner{i} = snsGenerateFLORIS(layouts{i});
end

tic
nLayouts = length(layouts);
nWS = length(trueRange.WS);
nTI = length(trueRange.TI);
nWD = length(trueRange.WD);
if rem(nWD,2) == 0
    disp('WARNING: RECOMMENDED TO DISCRETIZE WD AT AN UNEVEN NUMBER: '' trueRange.WD ''.')
end

for Layouti = 1:nLayouts
    florisRunnerTrue = copy(florisRunner{Layouti});
    disp(['Determining all roses for layout{' num2str(Layouti) '} (' num2str(Layouti) '/' num2str(nLayouts) ').'])
    for WSi = 1:nWS
        wsTrue = trueRange.WS(WSi);
        florisRunnerTrue.layout.ambientInflow.Vref = wsTrue;
        disp(['  Determining rose for WS_true = ' num2str(trueRange.WS(WSi)) ' m/s (' num2str(WSi) '/' num2str(nWS) ').'])
        for TIi = 1:nTI
            tiTrue = trueRange.TI(TIi);
            florisRunnerTrue.layout.ambientInflow.TI0 = tiTrue;
            disp(['    Calculating observability for TI_true = ' num2str(tiTrue) ' (' num2str(TIi) '/' num2str(nTI) ').']); % Progress
            
            % Determine estimation errors/cost over all WDs for this layout, WS and TI
            costFunInfo{Layouti,WSi,TIi} = costRoseOverWDs(florisRunnerTrue,trueRange.WD,relSearchRange);
        end
    end
    
    %     % Check for symmetry in the observability circle
    %     if max(abs(diff(sumJ(Layouti,1,1,1:(nWD-1)/2)-sumJ(Layouti,1,1,(nWD-1)/2+1:end-1)))) < 1e-6
    %         disp(['The observability rose of layout{' num2str(Layouti) '} appears to be symmetrical.']);
    %     else
    %         disp(['The observability rose of layout{' num2str(Layouti) '} appears to be non-symmetrical.']);
    %     end
end
toc

% Create the output matrix
costMatrix = struct(...
    'trueRange',trueRange,...
    'relSearchRange',relSearchRange,...
    'costFunInfo',{costFunInfo});
costMatrix.layouts = layouts;
end

function [costFunInfo] = costRoseOverWDs(florisRunnerIn,trueRangeWD,relSearchRange)
% THIS FUNCTION CALCULATES THE SENSITIVITY FOR ONE SPECIFIC FLORISRUNNER
% OBJECT OVER THE COMPLETE WIND ROSE

% Import variables
florisRunnerTrue = florisRunnerIn;

nTurbs = florisRunnerTrue.layout.nTurbs;
wsTrue = florisRunnerTrue.layout.ambientInflow.Vref;
wdTrue = florisRunnerTrue.layout.ambientInflow.windDirection;
tiTrue = florisRunnerTrue.layout.ambientInflow.TI0;

nWdSensitivity = length(trueRangeWD);
nSubWD = length(relSearchRange.WD);
nSubWS = length(relSearchRange.WS);
nSubTI = length(relSearchRange.TI);

dwd_lengthscale = relSearchRange.WD(end)-relSearchRange.WD(1);
dws_lengthscale = relSearchRange.WS(end)-relSearchRange.WS(1);
dti_lengthscale = relSearchRange.TI(end)-relSearchRange.TI(1);

% Evaluate the cost function for the entire wind rose
parfor WDi = 1:nWdSensitivity
    florisRunnerLocal = copy(florisRunnerTrue); % Copy florisRunner obj
    
    wdTrue = trueRangeWD(WDi); % Update wdTrue
    [powerTrue,uTrue] = evalForWD(florisRunnerTrue,wdTrue,wdTrue); % Calculate true power from FLORIS
    [dxSqrd,msePwr,mseU,mseUwse] = deal(zeros(nSubTI,nSubWS,nSubWD)); % Initialize empty matrices
    
    for WSii = 1:nSubWS
        wsEst = wsTrue + relSearchRange.WS(WSii); % Update estimated WS
        florisRunnerLocal.layout.ambientInflow.Vref = wsEst;
        dws = abs(wsTrue - wsEst);
        
        for TIii = 1:nSubTI
            tiEst = tiTrue + relSearchRange.TI(TIii);
            florisRunnerLocal.layout.ambientInflow.TI0 = tiEst; % Update estimated TI
            dti = abs(tiTrue - tiEst);
            
            for WDii = 1:nSubWD
                wdEst = wdTrue + relSearchRange.WD(WDii);
                dwd = abs(wdEst-wdTrue); % Distance between arguments
                if dwd > pi % Radial distance
                    dwd = 2*pi - dwd;
                end
                if dwd < 0 || dwd > pi
                    error('Something went wrong here.')
                end
                
                [powerOut,uOut] = evalForWD(florisRunnerLocal,wdTrue,wdEst);
                uOutWSE = uOut*((cos(-dwd))^(1.88/3)); % WS predicted by WSE under yawed power signal
                mseUwse(TIii,WSii,WDii) = mean((uOutWSE-uTrue).^2);
                msePwr(TIii,WSii,WDii)  = mean((powerOut-powerTrue).^2);
                mseU(TIii,WSii,WDii)    = mean((uOut-uTrue).^2);
                
                % Fix numerical errors
                if msePwr(TIii,WSii,WDii) < 10*eps
                    msePwr(TIii,WSii,WDii) = 0;
                end
                if mseU(TIii,WSii,WDii) < 10*eps
                    mseU(TIii,WSii,WDii) = 0;
                end
                if mseUwse(TIii,WSii,WDii) < 10*eps
                    mseUwse(TIii,WSii,WDii) = 0;
                end
                
                % Calculate squared distancedxSqrd
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
            end
        end
    end
    
    % Collect useful outputs
    costFunInfo{WDi} = struct(...
        'msePwr',msePwr,...
        'mseU',mseU,...
        'mseUwse',mseUwse,...
        'dxSqrd',dxSqrd,...
        'nTurbs',nTurbs,...
        'wsTrue',wsTrue,...
        'wdTrue',wdTrue,...
        'tiTrue',tiTrue,...
        'relSearchRange',relSearchRange...
        );
end
end

function [powerOut,uOut] = evalForWD(florisRunnerIn,windDirectionTrue,windDirectionEval)
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
    windDirectionTrue * ones(1,florisRunnerLocal.layout.nTurbs);
% disp(florisRunnerLocal.controlSet.yawAngleIFArray)

% Run and export power & WS
florisRunnerLocal.run();
powerOut = [florisRunnerLocal.turbineResults.power];
uOut = [florisRunnerLocal.turbineConditions.avgWS];
end