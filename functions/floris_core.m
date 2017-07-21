function [outputData] = floris_core(inputData,dispTimer)

% Required to disable timer for optimization calls
if nargin <= 1
    dispTimer = true; 
end 

% Turbine operation settings in wind frame
turbines = struct(...
    'YawWF',        num2cell(inputData.yawAngles), ...   % Yaw misalignment with flow (counterclockwise, wind frame)
    'Tilt',         num2cell(inputData.tiltAngles), ...  % Tilt misalignment with flow
    'bladePitch',   num2cell(inputData.pitchAngles), ... % Collective blade pitch angles
    'axialInd',     num2cell(inputData.axialInd),...     % Axial induction control setting (used only if model.axialIndProvided == true)
    'hub_height',   num2cell(inputData.hub_height),...
    'rotorRadius',  num2cell(inputData.rotorRadius),...
    'rotorArea',    num2cell(inputData.rotorArea),...
    'eta',          num2cell(inputData.generator_efficiency),...
    'windSpeed',[],'Cp',[],'Ct',[],'power',[],...
    'downstream',[],'ThrustAngle',[],'wakeNormal',[]);

% Wake properties
wakes = struct( 'Ke',num2cell(zeros(1,length(turbines))),'mU',{[]}, ...
    'zetaInit',[],'wakeRadiusInit',[],'centerLine',[], ...
    'rZones',[],'cZones',[],'cFull',[],'boundary',[],'V',[]);


%% Internal code of FLORIS
% Determine wind farm layout in wind-aligned frame. Note that the
% turbines are renumbered in the order of appearance w.r.t wind direction
[turbines,wtRows] = floris_frame(inputData,turbines);

% The first row of turbines has the freestream as inflow windspeed
[turbines(wtRows{1}).windSpeed] = deal(inputData.uInfWf);

% Start the core model. Without any visualization this is all that runs, It
% computes the power produced at all turbines given the flow and turbine settings
timer.core = tic;
for turbirow = 1:length(wtRows) % for first to last row of turbines
    for turbNum = wtRows{turbirow} % for each turbine in this row
        
        % Determine Cp, Ct, axialInduction and power for a turbine
        turbines(turbNum) = floris_cpctpower(inputData,turbines(turbNum));
        
        % calculate ke, mU, and initial wake deflection & diameter
        wakes(turbNum) = floris_initwake( inputData,turbines(turbNum),wakes(turbNum) );
        
        % Compute the X locations of the downstream turbines rows
        wakes(turbNum).centerLine(1,:) = arrayfun(@(x) x.LocWF(1), turbines(cellfun(@(x) x(1),wtRows(turbirow+1:end)))).';
        wakes(turbNum).centerLine(1,end+1) = turbines(end).LocWF(1)+300;
        
        % Compute the wake centerLines position at the downstream turbine x-coordinates
        wakes(turbNum) = floris_wakeCenterLinePosition(inputData,turbines(turbNum), wakes(turbNum));
    end
    
    % If this is not the last turbine row compute the windspeeds at the next row
    if turbirow < length(wtRows)
        % Pass all the upstream turbines and wakes including the next
        % downstream row to the function: wt_rows{1:turbirow+1}
        % Return only the downstream turbine row: wt_rows{turbirow+1}.
        turbines(wtRows{turbirow+1}) = floris_compute_windspeed(...
            turbines([wtRows{1:turbirow+1}]),wakes([wtRows{1:turbirow+1}]),inputData,wtRows,turbirow);
    end
end
if dispTimer; disp(['TIMER: core operations: ' num2str(toc(timer.core)) ' s.']); end

% Prepare output data
outputData = struct('turbines',turbines,...
                    'wakes',wakes,...
                    'power',[turbines.power]);
end