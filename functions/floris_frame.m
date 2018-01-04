function [ turbines,wtRows ] = floris_frame( inputData,turbines )
%   This function calculates the (rearranged) wind farm layout in the wind-
%   aligned frame ('*Wf'). It also groups turbines together in rows to 
%   avoid unnecessary calculations of the influence of downstream turbines 
%   on their upwind turbines (which of course is none).

    % Rotate and translate wind turbine locations to align with wind dir.
    wtLocationsWf = frame_IF2WF(inputData.windDirection,inputData.LocIF);

    % Order turbines from front to back, and project them on positive axes
    [LocX,sortvector] = sort(wtLocationsWf(:,1));
    wtLocationsWf = wtLocationsWf(sortvector,:);
    
    % Group turbines together in rows (depending on wind direction)
    rowi = 1; j = 1;
    while j <= size(wtLocationsWf,1)
        wtRows{rowi} = [j j+find(abs(LocX(j)-LocX(j+1:end))<1e0)']; % Within 1 meter of each other
        j       = j + length(wtRows{rowi});
        rowi    = rowi + 1;
    end;
    
    % Repopulate the turbine struct ordered by wind direction x-coordinates
    turbines = turbines(sortvector);
    for i = 1:length(sortvector)
        turbines(i).turbId = sortvector(i);
        turbines(i).LocIF  = inputData.LocIF(sortvector(i),:).';
        turbines(i).LocWF  = wtLocationsWf(i,:).';
        % Yaw angles (counterclockwise, inertial frame)
        turbines(i).YawIF = inputData.windDirection+turbines(i).YawWF;
    end;
end
