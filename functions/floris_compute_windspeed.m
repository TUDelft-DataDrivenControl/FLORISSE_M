function [ dwTurbs ] = floris_compute_windspeed( turbines,wakes,site,turbType,wt_rows,turbirow )

    for  dw_turbi = wt_rows{turbirow+1}% for all turbines in dw row
        sout   = 0; % outer sum of Eq. 22
        for uw_turbrow = 1:turbirow % for all rows upstream of this current row
            for uw_turbi = wt_rows{uw_turbrow} % for each turbine in that row
                sinn   = 0; % inner sum of Eq. 22
                deltax = turbines(dw_turbi).LocWF(1)-turbines(uw_turbi).LocWF(1);
                for zone = 1:3
                    ciq = (turbType.rotorDiameter/(turbType.rotorDiameter + 2*wakes(uw_turbi).Ke*wakes(uw_turbi).mU(zone)*deltax))^2; % Eq. 16
                    sinn = sinn + ciq*wakes(uw_turbi).OverlapAreaRel(dw_turbi,zone);
                end;

                sout = sout + (turbines(uw_turbi).axialInd*sinn)^2;
            end;
        end;
        turbines(dw_turbi).windSpeed = site.uInfWf*(1-2*sqrt(sout));
    end;

    dwTurbs = turbines(wt_rows{turbirow+1});
end