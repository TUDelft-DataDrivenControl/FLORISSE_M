function layout_obj = WE19_6_turb()
    % 6-turbine case
    locIf = {[608.5  1232.55];
             [608.5  1767.45];
             [1500.0 1232.55];
             [1500.0 1767.45];
             [2391.5 1232.55];
             [2391.5 1767.45]};

    % Put all the turbines in a struct array
    turbines = struct('turbineType',dtu10mw(),'locIf',locIf);
    layout_obj = layout_class(turbines, 'we19_6_turb');
end


