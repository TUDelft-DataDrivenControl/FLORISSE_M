function outputMatrixNew = costFunInfoAnalysis(fileIn,pwMeasWeight,wsMeasWeight,wdMeasWeight,plotSensitivityPlots)
addpath('bin')

% Default parameters
if nargin < 2
    pwMeasWeight = 1.0;
    wsMeasWeight = 1e11;
    wdMeasWeight = 1e13;
end
if nargin < 5
    plotSensitivityPlots = true;
end

%% PLOTS
plotCostFun = false;
    plot1Dfun = true;
    plot2Dfun = false;
% plotSensitivityPlots = true;
    plotRadial = true;
    plotCrucial = false;
saveProcessedData = false;

% --- END OF PLOTS
if ischar(fileIn)
    % load file if is a file path
    load(fileIn)
else
    % set to variable if direct variable input
    outputMatrix = fileIn;
end

trueRange = outputMatrix.trueRange;
nLayouts = size(outputMatrix.sumJ,1);

nWS = length(trueRange.WS);
nTI = length(trueRange.TI);
nWD = length(trueRange.WD);

relSearchRange = outputMatrix.relSearchRange;
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

sumJnew = zeros(nLayouts,nWS,nTI,nWD); % Initialize empty tensor
for Layouti = 1:nLayouts
    try
        nTurbs = outputMatrix.costFunInfo{Layouti,1,1}{1}.nTurbs;
    catch
        nTurbs = outputMatrix.costFunInfo{1}.nTurbs;
    end
    % TRUE OUTER LOOPS
    for WSi = 1:nWS
        wsTrue = trueRange.WS(WSi);
        for TIi = 1:nTI
            tiTrue = trueRange.TI(TIi);
            for WDi = 1:nWD
                wdTrue = trueRange.WD(WDi);
                try
                    costFunInfoLocal = outputMatrix.costFunInfo{Layouti,WSi,TIi}{WDi};
                catch
                    costFunInfoLocal = outputMatrix.costFunInfo{WDi};
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
                            msePwr  = costFunInfoLocal.msePwr(TIii,WSii,WDii)*1e12;
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
%                             dwd_vec(TIii,WSii,WDii) = ((wdTrue - wdEst) / dwd_ls);
%                             dws_vec(TIii,WSii,WDii) = ((wsTrue - wsEst) / dws_ls);
%                             dti_vec(TIii,WSii,WDii) = ((tiTrue - tiEst) / dti_ls);
                            
                            %% ----- COST FUNCTION
                            costJ_parts = [pwMeasWeight*msePwr, ...
                                           wsMeasWeight*mseUwse, ...
                                           wdMeasWeight*(dwd^2)];
%                             costJ_parts = [pwMeasWeight*msePwr, ...
%                                            wsMeasWeight*mseU, ...
%                                            wdMeasWeight*(dwd^2)];
                                       
                            costJ(TIii,WSii,WDii) = sum(costJ_parts);
                            
                            
                            % Partial contributions
                            obsvM(TIii,WSii,WDii) = costJ(TIii,WSii,WDii)/dxSqrd;
                            JPowerContrib(TIii,WSii,WDii) = costJ_parts(1)/dxSqrd;
                            JwsContrib(TIii,WSii,WDii) = costJ_parts(2)/dxSqrd;
                            % obsvM(TIii,WSii,WDii) = costFunInfoLocal.mseU(TIii,WSii,WDii)/dxSqrd;
                            % obsvM(TIii,WSii,WDii) = (pwMeasWeight * rmsePwrDimless^2 ) / (dxSqrd*nTurbs) + ...
                            %                         (wdMeasWeight * abs(dwd/dwd_ls)^2) / (dxSqrd) + ...
                            %                         (wsMeasWeight * abs(dws/dws_ls)^2) / (dxSqrd) ;
                            
                            % Calculate error (The lower min(J), the less observable the system is)
                        end
                    end
                end
                
                % Filtering
                
                Mfiltered = obsvM;
                applyFilter = true;
                if applyFilter                    
                    deadzone_ti = 0.029;
                    deadzone_ws = 0.249;
                    deadzone_wd = 3.99*pi/180;

                    Mfiltered(abs(relSearchRange.TI) < deadzone_ti,...
                              abs(relSearchRange.WS) < deadzone_ws,...
                              abs(relSearchRange.WD) < deadzone_wd) = Inf;
                    
                    costJ(abs(relSearchRange.TI) < deadzone_ti,...
                          abs(relSearchRange.WS) < deadzone_ws,...
                          abs(relSearchRange.WD) < deadzone_wd) = Inf;   
                               
                    JPowerContrib(abs(relSearchRange.TI) < deadzone_ti,...
                                  abs(relSearchRange.WS) < deadzone_ws,...
                                  abs(relSearchRange.WD) < deadzone_wd) = Inf;   

                    JwsContrib(abs(relSearchRange.TI) < deadzone_ti,...
                                  abs(relSearchRange.WS) < deadzone_ws,...
                                  abs(relSearchRange.WD) < deadzone_wd) = Inf;                                 
                end
                [obsvO(WDi),idx] = min(Mfiltered(:)); % Find worst case scenario
                
                % Determine contribution of power measurements to observability
                if pwMeasWeight < eps
                    JPowerContribRel(WDi,1) = 0;
                elseif abs(obsvO(WDi)) < 100*eps && abs(JPowerContrib(idx)) < 100*eps
                    JPowerContribRel(WDi,1) = 1;
                else
                    JPowerContribRel(WDi,1) = JPowerContrib(idx)/obsvO(WDi);
                end

                % Determine contribution of WS measurements to observability
                if wsMeasWeight < eps
                    JwsContribRel(WDi,1) = 0;
                elseif abs(obsvO(WDi)) < 100*eps && abs(JwsContrib(idx)) < 100*eps
                    JwsContribRel(WDi,1) = 1;
                else
                    JwsContribRel(WDi,1) = JwsContrib(idx)/obsvO(WDi);
                end                
               
                WDidx_of_interest = 1; 
                if plotCostFun && Layouti == 1 && WDi == WDidx_of_interest && TIi == 1 %&& WSi == 1
                    if plot1Dfun
                        figure('Position',[1.5522e+03 25 820.0000 868])
                        subplot(2,2,1);
                        WSiindx = find(relSearchRange.WS==0);
                        plot(relSearchRange.WD*180/pi,squeeze(costJ(TIii,WSiindx,:)),'-x');
                        title(['WS=' num2str(wsTrue) ', TI=' num2str(tiTrue) ', WD= ' num2str(wdTrue*180/pi)])
                        xlabel('\Delta \phi (deg)')
                        ylabel('Jest($\hat{U}=U_{true}$)','interpreter','latex')
    %                     ylim([0 4])
                        grid on
                        legend(['obs(J) = ' num2str(obsvO(WDi))])
                        subplot(2,2,2);
                        WDiindx = find(relSearchRange.WD==0);
                        plot(relSearchRange.WS,squeeze(costJ(TIii,:,WDiindx)),'-x');
                        xlabel('\Delta U_ (m/s)')
                        ylabel('Jest($\hat{\phi}=\phi_{true}$)','interpreter','latex')
    %                     ylim([0 10])
                        xlim([-1.5 1.5])
                        legend(['obs(J) = ' num2str(obsvO(WDi))])
                        grid on
                        subplot(2,2,3);
                        WSiindx = find(relSearchRange.WS==0);
    %                     plot(relSearchRange.WD*180/pi,squeeze(J(TIii,WSiindx,:)),'-x');
                        plot(relSearchRange.WD*180/pi,squeeze(Mfiltered(TIii,WSiindx,:)),'-x');
                        title(['WS=' num2str(wsTrue) ', TI=' num2str(tiTrue) ', WD= ' num2str(wdTrue*180/pi)])
                        xlabel('\Delta \phi (deg)')
                        ylabel('Jobs($\hat{U}=U_{true}$)','interpreter','latex')
    %                     ylim([0 4])
                        grid on
                        legend(['obs(J) = ' num2str(obsvO(WDi))])                    
                        subplot(2,2,4);
                        WDiindx = find(relSearchRange.WD==0);
    %                     plot(relSearchRange.WS,squeeze(J(TIii,:,WDiindx)),'-x');
                        plot(relSearchRange.WS,squeeze(Mfiltered(TIii,:,WDiindx)),'-x');
                        xlabel('\Delta U_ (m/s)')
                        ylabel('Jobs($\hat{\phi}=\phi_{true}$)','interpreter','latex')
    %                     ylim([0 10])
                        xlim([-1.5 1.5])
                        legend(['obs(J) = ' num2str(obsvO(WDi))])
                        grid on
                    end
                    if plot2Dfun
                        figure()
                        [X,Y] = meshgrid(relSearchRange.WS,relSearchRange.WD*180/pi);
                        surf(X,Y,log(squeeze(Mfiltered(TIii,:,:))'+1));
                        xlabel('$\Delta U_\infty$','interpreter','latex')
                        ylabel('$\Delta \phi$','interpreter','latex')
                        zlabel('$\textrm{log}(\mathcal{M})$','interpreter','latex')
                        zlim([0 4.5e7])
                        axis tight
                        view(150.34,27.44)
                        title(['$U_\infty =' num2str(wsTrue) '$ ms$^{-1}$, $I_\infty =' num2str(tiTrue) '$, $\phi = ' num2str(wdTrue*180/pi) '$ deg'],'interpreter','latex')
                    end
                end
                
            end
            sumJnew(Layouti,WSi,TIi,:) = obsvO;
            relContributionPwr(Layouti,WSi,TIi,:) = JPowerContribRel(:,1);
            relContributionWs(Layouti,WSi,TIi,:) = JwsContribRel(:,1);
        end
    end   
end


outputMatrixNew = outputMatrix;
outputMatrixNew.sumJ = sumJnew;
outputMatrixNew.relContributionPwr = relContributionPwr;
outputMatrixNew.relContributionWs = relContributionWs;

if plotSensitivityPlots
    plotSensitivityFigures(outputMatrixNew,0,plotRadial, plotCrucial);
end

if saveProcessedData
    save([fileName(1:end-4) '_M.mat'],'outputMatrixNew')
end