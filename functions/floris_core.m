function [outputData] = floris_core(inputData,dispTimer)
% This is the FLORIS core code, which does all the computations using the
% settings specified in the inputData struct. Typically, floris_core.m is
% called through the FLORIS object, not directly by a user.
%

% A secondary input is added to disable the disp() statements for the
% optimization algorithms, which typically require thousands of calls to
% the FLORIS model. The following statement still allows one to call the
% floris_core(..) code without specifying dispTimer explicitly.
if nargin <= 1
    dispTimer = true; 
end 

% 'turbines' is an array of struct() objects, one for each turbine inside 
% the farm. It includes the operation settings in wind-aligned frame.
turbines = struct(...
    'YawWF',        num2cell(inputData.yawAngles), ...   % Yaw misalignment with flow (counterclockwise, wind frame) [radians]
    'Tilt',         num2cell(inputData.tiltAngles), ...  % Tilt misalignment with ground [radians]
    'bladePitch',   num2cell(inputData.pitchAngles), ... % Collective blade pitch angles [radians]
    'axialInd',     num2cell(inputData.axialInd),...     % Axial induction control setting [-] (if applicable)
    'hub_height',   num2cell(inputData.hub_height),...   % Turbine hub height [m]
    'rotorRadius',  num2cell(inputData.rotorRadius),...  % Rotor radius in [m]
    'rotorArea',    num2cell(inputData.rotorArea),...    % Rotor swept area in [m2]
    'eta',          num2cell(inputData.generator_efficiency),... % Turbine generator efficiency [-]
    'windSpeed',    [],... % Mean windspeed over the turbine rotor [m/s]
    'TI',           [],... % Turbulence intensity ratio [-] (e.g. 0.10 is 10%)
    'Cp',           [],... % Power coefficient [-]
    'Ct',           [],... % Thrust coefficient [-]
    'power',        [],... % Turbine generated power [W]
...%     'downstream',   [],... % Closest downstream turbine [ NOT USED? ]
    'ThrustAngle',  [],... % Angle of the thrust vector, which extends the yaw angle effects to include tilt [radians]. for tilt = 0, ThrustAngle = YawAngle.
    'wakeNormal',   []);   % Unit vector normal to the mean wake plane (for tilt = 0, this is [0 0 1], e.g. the z-axis)


% 'wakes' is an array of struct() objects, one for each turbine inside 
% the farm. It includes the wake parameters of interest.
wakes = struct(...
    'Ke',           num2cell(zeros(1,length(turbines))),... % Wake expansion coefficient
    'mU',           {[]}, ...
    'zetaInit',     [],...
    'wakeRadiusInit',[],... % Initial wake radius [m]
    'centerLine',   [], ... % Centerline position [m]
    'rZones',       [],...  % Radius of wake zones [m] (only if wakeType = 'Zones')
    'cZones',       [],...  % Center location of wake zones [m] (only if wakeType = 'Zones')
...     'cFull',        [],... [NOT USED?]
    'boundary',     [],...  % A boolean telling whether a point (y,z) lies within the wake radius of turbine(i) at distance x
    'V',            []);    % Cont. function for flow speed [m/s] in the wake


%% Internal code of FLORIS
% Determine wind farm layout in wind-aligned frame. Note that the
% turbines are renumbered in the order of appearance w.r.t wind direction
[turbines,wtRows] = floris_frame(inputData,turbines);

% The first row of turbines has the freestream as inflow windspeed
for turbNum = wtRows{1}
    turbines(turbNum).windSpeed = inputData.Ufun(turbines(turbNum).hub_height);
    turbines(turbNum).TI = inputData.TI_0;
end

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