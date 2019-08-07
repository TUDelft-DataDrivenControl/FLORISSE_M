function layout = sns_6turb_layout()
    D = 178.3; % Rptor diameter
    locIf = cellfun(@(loc) D*loc, {[0, 0]; [5, 0]; [10 0]; [0 3]; [5 3]; [10 3]}, 'UniformOutput', false);
    turbines = struct('turbineType', dtu10mw(),'locIf',locIf );
    layout = layout_class(turbines, 'sensitivity_layout_10mw');
end