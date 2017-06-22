function [inputData,outputData] = floris_run(inputData,timeCPU)
if nargin <= 1
    timeCPU = true;
end;
% Turbine operation settings in wind frame
% Yaw misalignment with flow (counterclockwise, wind frame)
% Axial induction control setting (used only if model.axialIndProvided == true)
turbines = struct(  'YawWF',num2cell(inputData.yawAngles), ...
    'axialInd',num2cell(inputData.axialInd),...
    'hub_height',num2cell(inputData.hub_height),...
    'rotorDiameter',num2cell(inputData.rotorDiameter),...
    'rotorArea',num2cell(inputData.rotorArea),...
    'eta',num2cell(inputData.generator_efficiency),...
    'windSpeed',[],'Cp',[],'Ct',[], ...
    'power',[]);%,'downstream',[]);

wakes = struct( 'Ke',num2cell(zeros(1,length(turbines))),'mU',{[]}, ...
    'zetaInit',[],'wakeDiameterInit',[],'centerLine',[], ...
    'diameters',[],'OverlapAreaRel',[]);

%% Internal code of FLORIS
% Determine wind farm layout in wind-aligned frame. Note that the
% turbines are renumbered in the order of appearance w.r.t wind direction
[inputData,turbines,wtRows] = floris_frame(inputData,turbines);
% The first row of turbines has the freestream as inflow windspeed
[turbines(wtRows{1}).windSpeed] = deal(inputData.uInfWf);

% Start the core model. Without any visualization this is all that runs, It
% computes the power produced at all turbines given the flow and
% turbine settings
timer.core = tic;
for turbirow = 1:length(wtRows) % for first to last row of turbines
    for turbNum = wtRows{turbirow} % for each turbine in this row
        
        % Determine Cp, Ct, axialInduction and power for a turbine
        turbines(turbNum) = floris_cpctpower(inputData,turbines(turbNum));
        
        % calculate ke, mU, and initial wake deflection & diameter
        wakes(turbNum) = floris_initwake( inputData,turbines(turbNum),wakes(turbNum) );
        
        % Compute  the X locations of  the downstream turbines rows
        wakes(turbNum).centerLine(1,:) = arrayfun(@(x) x.LocWF(1), turbines(cellfun(@(x) x(1),wtRows(turbirow+1:end)))).';
        wakes(turbNum).centerLine(1,end+1) = turbines(end).LocWF(1)+300;
        
        % Compute the wake centerLines and diameters at those X locations
        wakes(turbNum) = floris_wakeCenterLine_and_diameter(inputData,turbines(turbNum), wakes(turbNum));
        
        % Calculate overlap of this turbine on downstream turbines
        wakes(turbNum) = floris_overlap( (turbirow+1):length(wtRows),wtRows,wakes(turbNum),turbines );
    end
    
    % If this is not the last turbine row compute the windspeeds at the next row
    if turbirow < length(wtRows)
        % Pass all the upstream turbines and wakes including the next
        % downstream row to the function: wt_rows{1:turbirow+1}
        % Return only the downstream turbine row: wt_rows{turbirow+1}.
        turbines(wtRows{turbirow+1}) = floris_compute_windspeed(...
            turbines([wtRows{1:turbirow+1}]),wakes([wtRows{1:turbirow}]),inputData,wtRows,turbirow);
    end;
end;
if timeCPU
    disp(['TIMER: core operations: ' num2str(toc(timer.core)) ' s.']);
end;

% Prepare output data
outputData = struct('turbines',turbines,...
                    'wakes',wakes,...
                    'power',[turbines.power],...
                    'wtRows',{wtRows});
end