function [ dwTurbs ] = floris_compute_windspeed( turbines,wakes,inputData,wt_rows,turbirow )

    for  dw_turbi = wt_rows{turbirow+1}% for all turbines in dw row
        sout   = 0; % outer sum of Eq. 22
        for uw_turbrow = 1:turbirow % for all rows upstream of this current row
            for uw_turbi = wt_rows{uw_turbrow} % for each turbine in that row
                sinn   = 0; % inner sum of Eq. 22
                deltax = turbines(dw_turbi).LocWF(1)-turbines(uw_turbi).LocWF(1);
                [~,turbLocIndex] = min(abs(wakes(uw_turbi).centerLine(1,:)-turbines(dw_turbi).LocWF(1)));
                wakeOverlapTurb = [0 0 0];
                for zone = 1:3
                   wakeOverlapTurb(zone) = floris_intersect(wakes(uw_turbi).rZones(deltax,zone),turbines(dw_turbi).rotorRadius,...
                       abs(wakes(uw_turbi).centerLine(2,turbLocIndex)-turbines(dw_turbi).LocWF(2)));

                   for zonej = 1:(zone-1) % minus overlap areas of lower zones
                       wakeOverlapTurb(zone) = wakeOverlapTurb(zone)-wakeOverlapTurb(zonej);
                   end
                   sinn = sinn + wakes(uw_turbi).cZones(deltax,zone)*wakeOverlapTurb(zone)/turbines(dw_turbi).rotorArea;
                end
                sout = sout + (turbines(uw_turbi).axialInd*sinn)^2;
            end
        end
        turbines(dw_turbi).windSpeed = inputData.uInfWf*(1-2*sqrt(sout));
    end

    dwTurbs = turbines(wt_rows{turbirow+1});
end