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
                              
%                 
%                 if plotCostFun && Layouti == 1 && WDi == WDidx_of_interest && TIi == 1 %&& WSi == 1
% %                 if plotCostFun && Layouti == 1 && TIi == 1 %&& WSi == 1
%                     if plot1Dfun
%                         figure('Position',[33.8000 109.8000 892 612.8000])
%                         subplot(2,3,1);
%                         WSiindx = find(relSearchRange.WS==0);
%                         plot(relSearchRange.WD*180/pi,squeeze(costJ(TIii,WSiindx,:)),'-x');
%                         title(['$J=' jFunctionString '$'],'interpreter','latex')
%                         xlabel('\Delta \phi (deg)')
%                         ylabel(['$J(\Delta U =0)$'],'interpreter','latex')
%                         grid on
%                         subplot(2,3,2);
%                         WDiindx = find(relSearchRange.WD==0);
%                         plot(relSearchRange.WS,squeeze(costJ(TIii,:,WDiindx)),'-x');
%                         xlabel('\Delta U_ (m/s)')
%                         ylabel('$J(\Delta \phi= 0)$','interpreter','latex')
%                         xlim([-1.5 1.5])
%                         legend(['obs(J) = ' num2str(obsvO(WDi))])
%                         grid on
%                         subplot(2,3,4);
%                         WSiindx = find(relSearchRange.WS==0);
%     %                     plot(relSearchRange.WD*180/pi,squeeze(J(TIii,WSiindx,:)),'-x');
%                         plot(relSearchRange.WD*180/pi,squeeze(Mfiltered(TIii,WSiindx,:)),'-x');
% %                         title(['WS=' num2str(wsTrue) ', TI=' num2str(tiTrue) ', WD= ' num2str(wdTrue*180/pi)])
%                         title(['$M=' mFunctionString '$'],'interpreter','latex')
%                         xlabel('\Delta \phi (deg)')
%                         ylabel('$M(\Delta {U}=0)$','interpreter','latex')
%     %                     ylim([0 4])
%                         grid on
% %                         legend(['obs(J) = ' num2str(obsvO(WDi))])                    
%                         subplot(2,3,5);
%                         WDiindx = find(relSearchRange.WD==0);
%     %                     plot(relSearchRange.WS,squeeze(J(TIii,:,WDiindx)),'-x');
%                         plot(relSearchRange.WS,squeeze(Mfiltered(TIii,:,WDiindx)),'-x');
%                         xlabel('\Delta U_ (m/s)')
%                         ylabel('$M(\Delta {\phi}=0)$','interpreter','latex')
%     %                     ylim([0 10])
%                         xlim([-1.5 1.5])
% %                         legend(['obs(J) = ' num2str(obsvO(WDi))])
%                         grid on
%                     end
%                     if plot2Dfun
%                         figure()
%                         [X,Y] = meshgrid(relSearchRange.WS,relSearchRange.WD*180/pi);
%                         surf(X,Y,log(squeeze(Mfiltered(TIii,:,:))'+1));
%                         xlabel('$\Delta U_\infty$','interpreter','latex')
%                         ylabel('$\Delta \phi$','interpreter','latex')
%                         zlabel('$\textrm{log}(\mathcal{M})$','interpreter','latex')
%                         zlim([0 4.5e7])
%                         axis tight
%                         view(150.34,27.44)
%                         title(['$U_\infty =' num2str(wsTrue) '$ ms$^{-1}$, $I_\infty =' num2str(tiTrue) '$, $\phi = ' num2str(wdTrue*180/pi) '$ deg'],'interpreter','latex')
%                     end
%                 end
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