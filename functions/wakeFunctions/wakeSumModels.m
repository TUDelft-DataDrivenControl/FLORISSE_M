function [out] = wakeSumModels(wakeSumModel,U_inf,U_uw,Vni)
%% Wake summing methodology
% Inputs
%  U_uw  = wind speed at upstream turbine
%  U_inf = freestream wind speed at hub height
%  V     = Relative vol. flowrate divided by freestream velocity and swept rotor area

% Wake addition method ('Katic','Voutsinas')
% Combine the effects of multiple turbines' wakes
switch wakeSumModel
    case 'Katic' % Using Katic (traditional FLORIS)
        out = (U_inf*(1-Vni)).^2;
    case 'Voutsinas' % Using Voutsinas (Porte-Agel)
        % To compute the energy deficit use the inflow
        % speed of the upwind turbine instead of Uinf
        out = (U_uw*(1-Vni)).^2;
    otherwise
        error(['Wake summation model with name ''' wakeSumModel ''' not specified. (Note: input is case-sensitive)']);
end
end

