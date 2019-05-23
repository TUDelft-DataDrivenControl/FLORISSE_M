function [outputMatrix] = multidimensionalSensitivity(trueRange,relSearchRange,wdMeasWeight)
addpath(genpath('../../FLORISSE_M'))
addpath('bin')

%% Setup
if nargin < 1
    trueRange = struct(...
        'WD', linspace(0,2*pi,37),... % Discretization of 360 degrees wind rose. Recommended to be uneven number.
        'WS', [8.5],... % 12.0 15.0 17.0]; % Below, at, and above-rated
        'TI', [0.12]); %[0.02 0.07 0.12 0.20];
end
if nargin < 2
    relSearchRange = struct(...
        'WD', linspace(-20.,20.,41) * (pi/180),...
        'WS', linspace(-1.0,1.0,8),...
        'TI', [0.0]); % Get TI exactly right
end
if nargin < 3
    wdMeasWeight = 0;
end
noiseYaw = 0 * (pi/180); % Add gauss. noise over FLORIS evaulations -- Needs attention. Recommended: 0
noisePwr = 0 * 1e5; % Add gauss. noise over FLORIS evaluations -- Needs attention. Recommended: 0

% Layout definitions
locIf = {};
% locIf{end+1} = {[0, 0]}; % 1-turbine case
locIf{end+1} = {[0, 0]; [5, 0]}; % 2-turbine case
% locIf{end+1} = {[0, 0]; [5, 0]; [10 0]; [0 3]; [5 3]; [10 3]}; % Structured 6 turb case
% locIf{end+1} = {[4, 8]; [9, 9]; [4, 13]; [0,6];[12 11]; [13 6]; [8 4]; [4 0]}; % Unstructured 8-turbine case

% % Definition of Amalia wind farm
% load('centers_Amalia.mat');
% x_amalia = (1/80.0) * (Centers_turbine(:,1)-mean(Centers_turbine(:,1)));
% y_amalia = (1/80.0) * (Centers_turbine(:,2)-mean(Centers_turbine(:,2)));
% for iTurb = 1:length(x_amalia)
%     locIf{end+1}{iTurb,1} = [x_amalia(iTurb)-min(x_amalia) y_amalia(iTurb)-min(y_amalia)];
% end

% Construct farms
for i = 1:length(locIf)
    florisRunner{i} = generateFlorisRunner(locIf{i});
end
clear i

tic
nLayouts = length(locIf);
nWS = length(trueRange.WS);
nTI = length(trueRange.TI);
nWD = length(trueRange.WD);
if rem(nWD,2) == 0
    disp('WARNING: RECOMMENDED TO DISCRETIZE WD AT AN UNEVEN NUMBER: '' WDsensitivity_range ''.')
end

sumJ = zeros(nLayouts,nWS,nTI,nWD); % Initialize empty tensor
for Layouti = 1:nLayouts
    florisRunnerTrue = copy(florisRunner{Layouti});
    disp(['Determining all roses for layout{' num2str(Layouti) '} (' num2str(Layouti) '/' num2str(nLayouts) ').'])
    for WSi = 1:nWS
        wsTrue = trueRange.WS(WSi);
        florisRunnerTrue.layout.ambientInflow.Vref = wsTrue;
        disp(['  Determining rose for WS_true = ' num2str(trueRange.WS(WSi)) ' m/s (' num2str(WSi) '/' num2str(nWS) ').'])
        for TIi = 1:nTI
            tiTrue = trueRange.TI(TIi);
            florisRunnerTrue.layout.ambientInflow.TI0 = tiTrue;
            disp(['    Calculating observability for TI_true = ' num2str(tiTrue) ' (' num2str(TIi) '/' num2str(nTI) ').']); % Progress
            
            WD_abssearchrange = 0.0    + relSearchRange.WD;
            WS_abssearchrange = wsTrue + relSearchRange.WS;
            TI_abssearchrange = tiTrue + relSearchRange.TI;
            
            % Determine observability for these true conditions
            sumJ(Layouti,WSi,TIi,:) = sensitivityRose(...
                florisRunnerTrue,trueRange.WD,...
                WS_abssearchrange,...
                TI_abssearchrange,...
                WD_abssearchrange,...
                noiseYaw,noisePwr,...
                wdMeasWeight);
            
        end
    end
    if max(abs(diff(sumJ(Layouti,1,1,1:(nWD-1)/2)-sumJ(Layouti,1,1,(nWD-1)/2+1:end-1)))) < 1e-6
        disp(['The observability rose of layout{' num2str(Layouti) '} appears to be symmetrical.']);
    else
        disp(['The observability rose of layout{' num2str(Layouti) '} appears to be non-symmetrical.']);
    end
end
toc

% Create an output matrix
outputMatrix = struct(...
    'trueRange',trueRange,...
    'relSearchRange',relSearchRange,...
    'sumJ',sumJ,...
    'noiseYaw',noiseYaw,...
    'noisePwr',noisePwr,...
    'locIf',locIf);

% Save everything
save(['tmpOut_' strrep(strrep(datestr(now),' ','_'),':','_') '.mat'])
end