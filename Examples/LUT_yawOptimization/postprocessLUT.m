clear all
addpath('bin')

% LUT file
LUTfile = 'LUTs/LUT_6turb_yaw.csv';
databaseIn = importYawLUT(LUTfile);

% Filter settings
WSrange_fixed = [5 12]; % Fixed yaw angles between this range
multiplicationTerms = ones(1,6); %[20/16.07 20/17.34];

% Plot settings
TiPlotIndices = [1]; % which TI indices to plot; a vector
sigma_opt = [1.5 1.5]; % Gaussian smoother standard deviations, [WD, WS]
WS_outliers = []; % These entries are discarded/overwritten when filtering
plotInitialLUT = true;
plotFilteredLUT = true;

% Output settings
saveFilteredLUT = true;
filteredOutputname = [LUTfile(1:end-4) 'Filtered.mat'];


%% Look at optimized yaw angles RAW
if plotInitialLUT
    plotLUTYawWD(databaseIn,TiPlotIndices) % Plot initial lines
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
        databaseYaw{turbi} = squeeze(databaseLUT_processed.yawT{turbi}(TIi,:,:));

        if databaseIn.nWS == 1
            databaseYaw{turbi} = databaseYaw{turbi}'; % Transpose
        end

        yawAnglesFixed{turbi} = mean(databaseYaw{turbi}(fixedIndices,:),1);
    
    % Multiply with constant factors
    yawAnglesFixed{turbi} = yawAnglesFixed{turbi} * multiplicationTerms(turbi);
            
    % Linear interpolation to zero outside of fixed range
    for ii = 1:(fixedIndices(1)-1)
        databaseYaw{turbi}(ii,:) = (ii-1)*yawAnglesFixed{turbi}/(fixedIndices(1)-1);
    end
    for ii = fixedIndices
        databaseYaw{turbi}(ii,:) = yawAnglesFixed{turbi};
%         databaseYaw2tmp(ii,:) = yawAnglesFixedT2;
    end
    for ii = fixedIndices(end)+1:databaseIn.nWS
        databaseYaw{turbi}(ii,:) = yawAnglesFixed{turbi}-(ii-fixedIndices(end))*yawAnglesFixed{turbi}/(databaseIn.nWS-fixedIndices(end));
        
%         databaseYaw2tmp(ii,:) = yawAnglesFixedT2-(ii-fixedIndices(end))*yawAnglesFixedT2/(databaseIn.nWS-fixedIndices(end));
    end
    
    % Overwrite LUT
    databaseLUT_processed.yawT{turbi}(TIi,:,:) = databaseYaw{turbi};
    end
end

%% Look at optimized yaw angles FILTERED
if plotFilteredLUT
    plotLUTYawWD(databaseLUT_processed,TiPlotIndices) % Plot filtered lines
%     plotLUTsurf(databaseLUTopt,TiPlotIndices)
end

if saveFilteredLUT
    disp('Saving post-processed .csv file...')
    databaseLUT = databaseLUT_processed;
    save(filteredOutputname,'databaseLUT')
end