% Calculate wake location delta Y: Eq. 8-12
factor       = (2.0*model.kd*deltax/turb.rotorDiameter)+1.0;
displacement = (wakeAngleInit(turbi)*(15.0*(factor^4.0)+(wakeAngleInit(turbi)^2.0))/ ...
               ((30.0*model.kd*(factor^5.0))/turb.rotorDiameter))- ...
               (wakeAngleInit(turbi)*turb.rotorDiameter*(15.0+(wakeAngleInit(turbi)^2.0))/(30.0*model.kd));

% Turbine #row's wake centerline location Y at the wind-farm row #column
wake_locY_wf_Turb(turbi,dw_turbirow) = wt_locations_wf(turbi,2) + ...                   % wake location starting point
                                       model.initialWakeDisplacement + ...              % initial wake displacement
                                       (1-model.useWakeAngle) * deltax * model.bd + ... % rotation-induced lateral offset
                                       displacement;                                    % yaw-induced wake displacement

for dw_turbi = wt_order{dw_turbirow}
   wake_dY_Turb(turbi,dw_turbi) = abs(wake_locY_wf_Turb(turbi,dw_turbirow)-wt_locations_wf(dw_turbi,2));
   for zone = 1:3
       wakeDiametersTurb(turbi,dw_turbirow,zone) = wakeDiameter0(turbi) + 2*ke(turbi)*model.me(zone)*deltax; % Calculate wake diameter for zones 1-3: Eq. 13

       % Calculate overlap areas of wake on dw turbines
       wakeOverlapTurb(turbi,dw_turbi,zone)    = floris_overlap(wakeDiametersTurb(turbi,dw_turbirow,zone)/2,turb.rotorDiameter/2,wake_dY_Turb(turbi,dw_turbi));
       for zonej = 1:(zone-1) % minus overlap areas of lower zones
           wakeOverlapTurb(turbi,dw_turbi,zone) = wakeOverlapTurb(turbi,dw_turbi,zone)-wakeOverlapTurb(turbi,dw_turbi,zonej);
       end;
       wakeOverlapRelTurb(turbi,dw_turbi,zone) = wakeOverlapTurb(turbi,dw_turbi,zone)/turb.rotorArea;
   end;
end;