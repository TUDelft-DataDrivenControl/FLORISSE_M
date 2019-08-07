function layout = sns_amalia_layout()
    D = 178.3; % Rptor diameter
    
    load('centers_Amalia.mat');
    x_amalia = (1/80.0) * (Centers_turbine(:,1)-mean(Centers_turbine(:,1)));
    y_amalia = (1/80.0) * (Centers_turbine(:,2)-mean(Centers_turbine(:,2)));
    for iTurb = 1:length(x_amalia)
        locIf{iTurb,1} = [x_amalia(iTurb)-min(x_amalia) y_amalia(iTurb)-min(y_amalia)];
    end

    locIf = cellfun(@(loc) D*loc, locIf, 'UniformOutput', false);
    turbines = struct('turbineType', dtu10mw(),'locIf',locIf );
    layout = layout_class(turbines, 'sensitivity_layout_10mw');
end