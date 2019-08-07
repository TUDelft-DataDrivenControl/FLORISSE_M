function structOut = calculateObsvRose(costIn,jFunctionString,mFunctionString,deadzone)
addpath('bin')

trueRange = costIn.trueRange;
nLayouts = size(costIn.costFunInfo,1);

nWS = length(trueRange.WS);
nTI = length(trueRange.TI);
nWD = length(trueRange.WD);

relSearchRange = costIn.relSearchRange;
nSubWS = length(relSearchRange.WS);
nSubTI = length(relSearchRange.TI);
nSubWD = length(relSearchRange.WD);
dwd_ls = relSearchRange.WD(end)-relSearchRange.WD(1);
dws_ls = relSearchRange.WS(end)-relSearchRange.WS(1);
dti_ls = relSearchRange.TI(end)-relSearchRange.TI(1);

% Numerical correction
if nSubWS == 1 && dws_ls == 0
    dws_ls = 1;
end

%% GO THROUGH LOOPS
O = zeros(nLayouts,nWS,nTI,nWD); % Initialize empty tensor
for Layouti = 1:nLayouts
    try
        nTurbs = costIn.costFunInfo{Layouti,1,1}{1}.nTurbs;
    catch
        nTurbs = costIn.costFunInfo{1}.nTurbs;
    end
    % TRUE OUTER LOOPS
    for WSi = 1:nWS
        wsTrue = trueRange.WS(WSi);
        for TIi = 1:nTI
            tiTrue = trueRange.TI(TIi);
            for WDi = 1:nWD
                wdTrue = trueRange.WD(WDi);
                try
                    costFunInfoLocal = costIn.costFunInfo{Layouti,WSi,TIi}{WDi};
                catch
                    costFunInfoLocal = costIn.costFunInfo{WDi};
                end

                % ESTIMATE INNER LOOPS
                for WSii = 1:nSubWS
                    wsEst = wsTrue + relSearchRange.WS(WSii);
                    dws = abs(wsTrue - wsEst);
                    for TIii = 1:nSubTI
                        tiEst = tiTrue + relSearchRange.TI(TIii);
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
                            msePwr  = costFunInfoLocal.msePwr(TIii,WSii,WDii);
                            mseU    = costFunInfoLocal.mseU(TIii,WSii,WDii);
                            mseUwse = costFunInfoLocal.mseUwse(TIii,WSii,WDii); % WSE equivalent
                            
                            rmsePwr = sqrt(msePwr);
                            rmsePwrDimless = rmsePwr/(wsTrue^3);
                            
                            dxSqrd = 0;
                            if nSubWD > 1
                                dxSqrd = dxSqrd + (dwd/dwd_ls)^2;
                            end
                            if nSubWS > 1
                                dxSqrd = dxSqrd + (dws/dws_ls)^2;
                            end
                            if nSubTI > 1
                                dxSqrd = dxSqrd + (dti/dti_ls)^2;
                            end
                            
                            %% ----- COST FUNCTION
                            J = eval(jFunctionString);
                            costJ(TIii,WSii,WDii) = J;
                            obsvM(TIii,WSii,WDii) = eval(mFunctionString);
                        end
                    end
                end
                
                % Filtering
                Mfiltered = obsvM;
                if deadzone.apply                    
                    Mfiltered(abs(relSearchRange.TI) < deadzone.TI,...
                              abs(relSearchRange.WS) < deadzone.WS,...
                              abs(relSearchRange.WD) < deadzone.WD) = Inf;
                    
                    costJ(abs(relSearchRange.TI) < deadzone.TI,...
                          abs(relSearchRange.WS) < deadzone.WS,...
                          abs(relSearchRange.WD) < deadzone.WD) = Inf;                       
                end
                
                % Save outputs of M
                costJ_array{Layouti,WSi,TIi,WDi} = costJ;
                obsvM_array{Layouti,WSi,TIi,WDi} = obsvM;
                obsvMfilt_array{Layouti,WSi,TIi,WDi} = Mfiltered;
                
                % Calculate observability O
                [obsvO,idx] = min(Mfiltered(:)); % Pick O as worst case scenario (lowest value of M)
                O(Layouti,WSi,TIi,WDi) = obsvO;
            end
        end
    end   
end

% Construct output matrix
structOut = costIn; % Copy input information to output matrix
structOut.deadzone = deadzone; % Append deadzone to struct
structOut.J = costJ_array; % Add J to output struct
structOut.M = obsvM_array; % Add M to output struct
structOut.Mfilt = obsvMfilt_array; % Add filtered M to output struct
structOut.O = O; % Add observability to output struct