function [ wt_order,sortvector,site,yawAngles_if,wt_locations_wf ] = floris_frame( site,turb,yawAngles_wf,wt_locations_if )
% Calculate incoming flow direction
site.windDirection = atand(site.v_inf_if/site.u_inf_if);    % Wind dir in degrees
site.u_inf_wf      = sqrt(site.u_inf_if^2+site.v_inf_if^2); % axial flow speed in wind frame
site.v_inf_wf      = 0;                                     % lateral flow speed in wind frame
yawAngles_if       = site.windDirection+yawAngles_wf;       % Yaw angles (counterclockwise, inertial frame)
wt_locations_wf    = (rotz(-site.windDirection)*wt_locations_if')'; % Wind frame turbine locations in wind frame

% Order turbines from front to back, and project them on positive axes
[LocX,sortvector] = sort(wt_locations_wf(:,1));
wt_locations_wf = wt_locations_wf(sortvector,:);
wt_locations_wf(:,2) = wt_locations_wf(:,2)-min([wt_locations_wf(:,2)]); % shift upwards
wt_locations_wf(:,1) = wt_locations_wf(:,1)-min([wt_locations_wf(:,1)]); % shift sideways

rowi = 1; j = 1;
while j <= size(wt_locations_wf,1)
    wt_order{rowi} = [j j+find(abs(LocX(j)-LocX(j+1:end))<1e0)'];
    j       = j + length(wt_order{rowi});
    rowi    = rowi + 1;
end;
end

