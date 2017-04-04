function [  ] = quiverMagCol(q,ax )
% Color arrows in a plot such that their length corresponds to their
% magnitude, also make the arrows with the highest speed (These represent
% the unaffected flowfield) partly transparant to increase the visibility
% of the wakes

    % Compute the magnitude of the vectors
    mags = sqrt(sum(cat(2, q.UData(:), q.VData(:), ...
                reshape(q.WData, numel(q.UData), [])).^2, 2));

    % Get the current colormap
    currentColormap = colormap(ax);

    % Now determine the color to make each arrow using a colormap
    [~, ~, ind] = histcounts(mags, size(currentColormap, 1));

    % Now map this to a colormap to get RGB
    cmap = uint8(ind2rgb(ind(:), currentColormap) * 255);
    cmap(:,:,4) = 150;
    cmap(ind==max(ind),:,4) = 50;
    % cmap(ind==64,:,4) = 50;
    cmap = permute(repmat(cmap, [1 3 1]), [2 1 3]);

    % We repeat each color 3 times (using 1:3 below) because each arrow has 3 vertices
    if strcmp(get(q.Head,'Visible'),'on')
        set(q.Head, ...
            'ColorBinding', 'interpolated', ...
            'ColorData', (reshape(cmap(1:3,:,:), [], 4).')./255, ...
            'LineWidth', 2);
    end

    % We repeat each color 2 times (using 1:2 below) because each tail has 2 vertices
    set(q.Tail, ...
        'ColorBinding', 'interpolated', ...
        'ColorData', reshape(cmap(1:2,:,:), [], 4).', ...
        'ColorType', 'truecoloralpha');
