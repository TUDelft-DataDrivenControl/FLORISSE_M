inputData.adjustInitialWakeDiamToYaw = false; % Adjust the intial swept surface overlap

inputData.alpha = 2.32;     % near wake parameter
inputData.beta  = .154;     % near wake parameter
inputData.veer  = 0;        % veer of atmosphere
inputData.ad    = -4.5;     % lateral wake displacement bias parameter (a + bx)
inputData.bd    = -.01;     % lateral wake displacement bias parameter (a + bx)

inputData.TIthresholdMult = 30; % threshold distance of turbines to include in \"added turbulence\"
inputData.TIa   = .73;      % magnitude of turbulence added
inputData.TIb   = .8325;    % contribution of turbine operation
inputData.TIc   = .0325;    % contribution of ambient turbulence intensity
inputData.TId   = -.32;     % contribution of downstream distance from turbine

inputData.ka	= .3837;    % wake expansion parameter (ka*TI + kb)
inputData.kb 	= .0037;    % wake expansion parameter (ka*TI + kb)
%     inputData.ky    = @(I) inputData.ka*I + inputData.kb;
%     inputData.kz    = @(I) inputData.ka*I + inputData.kb;

% For more information, see the publication from Bastankah and
% Porte-Agel (2016) with doi:10.1017/jfm.2016.595.