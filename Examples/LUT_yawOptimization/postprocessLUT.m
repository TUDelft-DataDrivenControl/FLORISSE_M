clear
clc
% close all
addpath('bin')

% LUT file
LUTfile = 'LUT_6turb_yaw_simple.csv';
databaseIn = importYawLUT(LUTfile);

% Filter settings
WSrange_fixed = [5.5 9.5]; % Fixed yaw angles between this range
multiplicationTerms = ones(1,9);

% Plot settings
TiPlotIndices = [1]; % which TI indices to plot; a vector
WDstdPlotIndices = [1 2 3]; % % which std indices to plot; a vector

sigma_opt = [0.7 1.3 0.75]; % Gaussian smoother standard deviations,[TI, WD, WD_std]
WS_outliers = []; % These entries are discarded/overwritten when filtering
plotInitialLUT = false;
plotFilteredLUT = true;

% Output settings
saveFilteredLUT = false;
filteredOutputname = [LUTfile(1:end-4) 'Filtered.mat'];


%% Look at optimized yaw angles RAW
if plotInitialLUT
    plotLUTYawWD(databaseIn,TiPlotIndices,WDstdPlotIndices) % Plot initial lines
%     plotLUTsurf(databaseIn,TiPlotIndices)
end

%% Filter database: gaussian filter, remove outliers and shave edges
nTurbs = length(databaseIn.yawT);
databaseLUT_processed = databaseIn;
WS_outlier_indcs = arrayfun(@(i) find(databaseIn.WS_range==WS_outliers(i)),1:length(WS_outliers));
for turbi = 1:nTurbs
    databaseLUT_processed.yawT{turbi} = applyFilterLUT(databaseIn.yawT{turbi},sigma_opt,WS_outlier_indcs);
end

%% Filter database: consistent yaw angle over multiple WSs, interpolate to zero outside
fixedIndices = find(databaseIn.WS_range>=WSrange_fixed(1) & databaseIn.WS_range<=WSrange_fixed(2));
for TIi = 1:databaseIn.nTI
    for turbi = 1:nTurbs
        databaseYaw{turbi} = squeeze(databaseLUT_processed.yawT{turbi}(TIi,:,:,:));

%         if databaseIn.nWS == 1
%             databaseYaw{turbi} = databaseYaw{turbi}'; % Transpose
%         end

        yawAnglesFixed{turbi} = mean(databaseYaw{turbi}(fixedIndices,:,:),1);
    
    % Multiply with constant factors
    yawAnglesFixed{turbi} = yawAnglesFixed{turbi} * multiplicationTerms(turbi);
            
    % Linear interpolation to zero outside of fixed range
    for ii = 1:(fixedIndices(1)-1)
        databaseYaw{turbi}(ii,:,:) = (ii-1)*yawAnglesFixed{turbi}/(fixedIndices(1)-1);
    end
    for ii = fixedIndices
        databaseYaw{turbi}(ii,:,:) = yawAnglesFixed{turbi};
    end
    for ii = fixedIndices(end)+1:databaseIn.nWS
        databaseYaw{turbi}(ii,:,:) = yawAnglesFixed{turbi}-(ii-fixedIndices(end))*yawAnglesFixed{turbi}/(databaseIn.nWS-fixedIndices(end));
    end
    
    % Overwrite LUT
    databaseLUT_processed.yawT{turbi}(TIi,:,:,:) = databaseYaw{turbi};
    end
end

%% Calculate maximum slopes
for turbi = 1:nTurbs
    diffTIs = abs(diff(databaseLUT_processed.yawT{turbi},1,1));
    diffWSs = abs(diff(databaseLUT_processed.yawT{turbi},1,2));
    diffWDs = abs(diff(databaseLUT_processed.yawT{turbi},1,3));
    diffWDstds = abs(diff(databaseLUT_processed.yawT{turbi},1,4));
    
    maxdiffTIs(turbi) = max(diffTIs(:));
    maxdiffWSs(turbi) = max(diffWSs(:));
    maxdiffWDs(turbi) = max(diffWDs(:));
    maxdiffWDstds(turbi) = max(diffWDstds(:));
end
maxdiffTI = max(maxdiffTIs)
maxdiffWS = max(maxdiffWSs)
maxdiffWD = max(maxdiffWDs)
maxdiffWDstd = max(maxdiffWDstds)


%% Look at optimized yaw angles FILTERED
if plotFilteredLUT
    plotLUTYawWD(databaseLUT_processed,TiPlotIndices,WDstdPlotIndices) % Plot filtered lines
%     plotLUTsurf(databaseLUTopt,TiPlotIndices)
end

if saveFilteredLUT
    disp('Saving post-processed .csv file...')
    databaseLUT = databaseLUT_processed;
    save(filteredOutputname,'databaseLUT')
end