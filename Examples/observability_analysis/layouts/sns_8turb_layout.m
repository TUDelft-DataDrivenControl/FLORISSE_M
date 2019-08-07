function layout = sns_8turb_layout()
    D = 178.3; % Rptor diameter
    locIf = cellfun(@(loc) D*loc, {[4, 8]; [9, 9]; [4, 13]; [0,6];[12 11]; [13 6]; [8 4]; [4 0]}, 'UniformOutput', false);
    turbines = struct('turbineType', dtu10mw(),'locIf',locIf );
    layout = layout_class(turbines, 'sensitivity_layout_10mw');
end