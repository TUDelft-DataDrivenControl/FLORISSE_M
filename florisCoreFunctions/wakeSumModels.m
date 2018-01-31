function [out] = wakeSumModels(wakeSumModel,U_inf,U_uw,Vni,inputType)
%% Wake summing methodology
% Inputs
%  U_uw  = wind speed at upstream turbine
%  U_inf = freestream wind speed at hub height
%  V     = Relative vol. flowrate divided by freestream velocity and swept rotor area

% if nargin <= 4
%     % inputType defines whether Vni has already been pre-multiplied by
%     % U_inf / U_uw respectively, or not. 
%     % for inputType == 1, Vni HAS NOT been premultiplied (used for turbine)
%     % for inputType == 2, Vni HAS     been premultiplied (used for flow)
%     inputType = 1;
% end

% Wake addition method ('Katic','Voutsinas')
% Combine the effects of multiple turbines' wakes
switch wakeSumModel
    case 'Katic' % Using Katic (traditional FLORIS)
%         if inputType == 2; Vni = Vni/U_inf; end;
        out = (U_inf*(1-Vni)).^2;
    case 'Voutsinas' % Using Voutsinas (Porte-Agel)
        % To compute the energy deficit use the inflow
        % speed of the upwind turbine instead of Uinf
%         if inputType == 2; Vni = Vni/U_uw; end;
        out = (U_uw*(1-Vni)).^2;
    otherwise
        error(['Wake summation model with name ''' wakeSumModel ''' not specified. (Note: input is case-sensitive)']);
end
end

