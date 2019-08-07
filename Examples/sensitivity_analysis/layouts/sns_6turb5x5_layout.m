function layout = sns_6turb5x5_layout()
    D = 178.3; % Rptor diameter
    locIf = cellfun(@(loc) D*loc, {[0, 0]; [5, 0]; [10 0]; [0 5]; [5 5]; [10 5]}, 'UniformOutput', false);
    turbines = struct('turbineType', dtu10mw(),'locIf',locIf );
    layout = layout_class(turbines, 'sensitivity_layout_10mw');
end