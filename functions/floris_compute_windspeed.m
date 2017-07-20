function [ dwTurbs ] = floris_compute_windspeed( turbines,wakes,inputData,wt_rows,turbirow )

    for  dw_turbi = wt_rows{turbirow+1}% for all turbines in dw row
        sout  = 0; % outer sum of Eq. 22
        for uw_turbrow = 1:turbirow % for all rows upstream of this current row
            for uw_turbi = wt_rows{uw_turbrow} % for each turbine in that row
                deltax = turbines(dw_turbi).LocWF(1)-turbines(uw_turbi).LocWF(1);
                [~,turbLocIndex] = min(abs(wakes(uw_turbi).centerLine(1,:)-turbines(dw_turbi).LocWF(1)));
                
                % inner sum of Eq. 22
                switch inputData.wakeType
                    case 'Zones'
                        Sin = FlorisSin();
                    case 'Gauss'
                        Sin = GaussSin();
                end

                sout = sout + (turbines(uw_turbi).axialInd*Sin)^2;
            end
        end
        turbines(dw_turbi).windSpeed = inputData.uInfWf*(1-2*sqrt(sout));
    end
    dwTurbs = turbines(wt_rows{turbirow+1});

function Sin = FlorisSin()
    Sin   = 0;
    wakeOverlapTurb = [0 0 0];
    for zone = 1:3
       wakeOverlapTurb(zone) = floris_intersect(wakes(uw_turbi).rZones(deltax,zone),turbines(dw_turbi).rotorRadius,...
         hypot(turbines(dw_turbi).LocWF(2)-(wakes(uw_turbi).centerLine(2,turbLocIndex)),...
               turbines(dw_turbi).LocWF(3)-(wakes(uw_turbi).centerLine(3,turbLocIndex))));

       for zonej = 1:(zone-1) % minus overlap areas of lower zones
           wakeOverlapTurb(zone) = wakeOverlapTurb(zone)-wakeOverlapTurb(zonej);
       end
       Sin = Sin + wakes(uw_turbi).cZones(deltax,zone)*wakeOverlapTurb(zone)/turbines(dw_turbi).rotorArea;
    end
end

function Sin = GaussSin()
    Sin   = 0;
    % Compute the distance between the center of the downwind turbine and the wake centerline of the upwind turbine
    d = wakes(uw_turbi).boundary(deltax)+turbines(dw_turbi).rotorRadius;
    % Compute the distance to the center of the downwind turbine for some (y,z), (0,0) is the wake centerline
    Rdwt = @(y,z) hypot(turbines(dw_turbi).LocWF(2)+y-(wakes(uw_turbi).centerLine(2,turbLocIndex)),...
            turbines(dw_turbi).LocWF(3)+z-(wakes(uw_turbi).centerLine(3,turbLocIndex)));

    if Rdwt(0,0)<d
        myfun =@(y,z) wakes(uw_turbi).cFull(deltax,sqrt(y.^2+z.^2))...
            .*(Rdwt(y,z)<turbines(dw_turbi).rotorRadius);
        ll = wakes(uw_turbi).boundary(deltax);

        Q = quad2d(myfun,-ll,ll,-ll,ll,'Abstol',5,...
            'Singular',false,'FailurePlot',true,'MaxFunEvals',3500);
        Sin = Q/turbines(dw_turbi).rotorArea;
    end
% zt = @(x,r) ((abs(r)<=wakes(uw_turbi).rZones(x,2))-(abs(r)<wakes(uw_turbi).rZones(x,1)));
% ztfun =@(y,z) zt(deltax,sqrt((y).^2+z.^2)).*(Rdwt((y),z)<turbines(dw_turbi).rotorRadius);
% figure;fcontour(Rdwt,[-ll,ll,-ll,ll])
% figure;fsurf(myfun,[-ll,ll,-ll,ll])
% keyboard
    end
end