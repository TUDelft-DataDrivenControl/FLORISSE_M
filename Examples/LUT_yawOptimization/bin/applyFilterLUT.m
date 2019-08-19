function [databaseYawFiltered] = applyFilterLUT(databaseYaw,sigma,WS_outlier_indcs)
% ASSUMPTION: LUT IS UNIFORMLY SPACED IN WD AND WS
% Empty matrix
databaseYawFiltered = databaseYaw;

if nargin <= 2
    WS_outlier_indcs = [];
end

if ~isempty(WS_outlier_indcs)
    WS_indcs = 1:size(databaseYawFiltered,2); % All indices
    for i = 1:length(WS_outlier_indcs)
        WS_indcs(WS_indcs==WS_outlier_indcs(i))=nan; % Remove outliers
    end

    % For all TIs
    for WDstdi = 1:size(databaseYaw,4)
        for TIi = 1:size(databaseYaw,1)
            % Isolate matrix
            databaseYawTmp = squeeze(databaseYaw(TIi,:,:,WDstdi));

            % Clean up outliers
            for iic = 1:length(WS_outlier_indcs)
                indx_out = WS_outlier_indcs(iic);
                oldEntries = databaseYawTmp(indx_out,:);
                if (any(indx_out < WS_indcs) & any(indx_out > WS_indcs)) % In between
                    ub = min(find(indx_out < WS_indcs));
                    lb = max(find(indx_out > WS_indcs));
                    newEntries = ((indx_out-lb)*databaseYawTmp(ub,:) + ...
                        (ub-indx_out)*databaseYawTmp(lb,:))./(ub-lb);
                elseif any(indx_out < WS_indcs) % Only values above: threshold
                    ub = min(find(indx_out < WS_indcs));
                    newEntries = databaseYawTmp(ub,:);
                elseif any(indx_out > WS_indcs) % Only values below: threshold
                    lb = max(find(indx_out > WS_indcs));
                    newEntries = databaseYawTmp(lb,:);
                else
                    error('Cannot determine how to remove outliers.')
                end
                databaseYawTmp(indx_out,:) = newEntries; % Overwrite values
            end
            databaseYawFiltered(TIi,:,:,WDstdi) = databaseYawTmp; % Update out matrix
        end
    end
end

% Apply gaussian smoothing filters
for WSi = 1:size(databaseYawFiltered,2)
    databaseYawFiltered(:,WSi,:,:) = imgaussfilt3(squeeze(databaseYawFiltered(:,WSi,:,:)),sigma);
end
    
%     % Shave edges
%     if shaveEdges > 0
%         if shaveEdges == 1
%             databaseYawFiltered(TIi,1,:)   = 0; % First WS
%             databaseYawFiltered(TIi,end,:) = 0; % Last WS
%         else
%             nWD = size(databaseYawFiltered,3);
%             
%             % Linear interpolation to smoothen the ends to zero for low WS
%             tmp_values_lb = squeeze(databaseYawFiltered(TIi,shaveEdges+1,:)); % Lower WS
%             for ix = 1:shaveEdges
%                 for id = 1:nWD % for all WDs
%                     % Linear interpolation between 0 and tmp_values_lb
%                     databaseYawFiltered(TIi,ix,id) = ...
%                         interp1([1 shaveEdges+1],[0 tmp_values_lb(id)],ix);
%                 end
%             end
%             
%             % Linear interpolation to smoothen the ends to zero for high WS
%             tmp_values_ub = squeeze(databaseYawFiltered(TIi,end-shaveEdges,:)); % Upper WS
%             for ix = 1:shaveEdges
%                 for id = 1:nWD % for all WDs
%                     % Linear interpolation between 0 and tmp_values_lb
%                     databaseYawFiltered(TIi,end-ix+1,id) = ...
%                         interp1([nWD-shaveEdges nWD],[tmp_values_ub(id) 0],nWD-ix+1);
%                 end
%             end
%         end
%     end
end

