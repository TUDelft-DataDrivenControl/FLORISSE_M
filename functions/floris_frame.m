function [ site,turbines,wt_rows ] = floris_frame( site,turbines,wt_locations_if )
%[ wt_order,sortvector,site,yawAngles_if,wt_locations_wf ] = floris_frame( site,turb,yawAngles_wf,wt_locations_if )
%   This function calculates the (rearranged) wind farm layout in the wind-
%   aligned frame ('*_wf'). It also groups turbines together in rows to 
%   avoid unnecessary calculations of the influence of downstream turbines 
%   on their upwind turbines (which of course is none).

    % Calculate incoming flow direction
    site.windDirection = atand(site.v_inf_if/site.u_inf_if);    % Wind dir in degrees (inertial frame)
    site.u_inf_wf      = hypot(site.u_inf_if,site.v_inf_if);    % axial flow speed in wind frame
    site.v_inf_wf      = 0;                                     % lateral flow speed in wind frame
    wt_locations_wf    = wt_locations_if*rotz(-site.windDirection).'; % Wind frame turbine locations in wind frame

    % Order turbines from front to back, and project them on positive axes
    [LocX,sortvector] = sort(wt_locations_wf(:,1));
    wt_locations_wf = wt_locations_wf(sortvector,:);
    wt_locations_wf(:,2) = wt_locations_wf(:,2)-min(wt_locations_wf(:,2)); % shift vertically (up-down)
    wt_locations_wf(:,1) = wt_locations_wf(:,1)-min(wt_locations_wf(:,1)); % shift horizontally (sideways)

    % Group turbines together in rows (depending on wind direction)
    rowi = 1; j = 1;
    while j <= size(wt_locations_wf,1)
        wt_rows{rowi} = [j j+find(abs(LocX(j)-LocX(j+1:end))<1e0)'];
        j       = j + length(wt_rows{rowi});
        rowi    = rowi + 1;
    end;
    
    % Repopulate the turbine struct ordered by wind direction x-coordinates
    turbines = turbines(sortvector);
    for i = 1:length(sortvector)
        turbines(i).LocIF = wt_locations_if(sortvector(i),:).';
        turbines(i).LocWF = wt_locations_wf(i,:).';
        % Yaw angles (counterclockwise, inertial frame)
        turbines(i).YawIF = site.windDirection+turbines(i).YawWF;
    end
end