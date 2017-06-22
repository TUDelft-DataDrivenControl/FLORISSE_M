function [ wake ] = floris_overlap( downstreamRows,WtRows,wake,turbines )

    % List all turbines that are affected by this turbine
    for dw_turbirow = downstreamRows
        for dwTurbine = WtRows{dw_turbirow}
           wakeOverlapTurb = zeros(1,3);
           for zone = 1:3
               
               % Locate the downwind turbine in the wake
               [~,turbLocIndex] = min(abs(wake.centerLine(1,:)-turbines(dwTurbine).LocWF(1)));
               % Calculate overlap areas (intersection) of wake on dw turbines
               wakeOverlapTurb(zone) = floris_intersect(wake.diameters(turbLocIndex,zone)/2,turbines(dwTurbine).rotorDiameter/2,...
                   abs(wake.centerLine(2,turbLocIndex)-turbines(dwTurbine).LocWF(2)));
               
               for zonej = 1:(zone-1) % minus overlap areas of lower zones
                   wakeOverlapTurb(zone) = wakeOverlapTurb(zone)-wakeOverlapTurb(zonej);
               end;
               
               % Save the overlap as a ratio with respect to rotorArea
               wake.OverlapAreaRel(dwTurbine,zone) = wakeOverlapTurb(zone)/turbines(dwTurbine).rotorArea;
           end;
        end;
    end
    
end