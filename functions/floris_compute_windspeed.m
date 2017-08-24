function [ dwTurbs ] = floris_compute_windspeed( turbines,wakes,inputData,wt_rows,turbirow )

    for  dw_turbi = wt_rows{turbirow+1}% for all turbines in dw row
        % Sum of kinetic energy deficits
        sumKed  = 0; % outer sum of Eq. 22
        for uw_turbrow = 1:turbirow % for all rows upstream of this current row
            for uw_turbi = wt_rows{uw_turbrow} % for each turbine in that row
                deltax = turbines(dw_turbi).LocWF(1)-turbines(uw_turbi).LocWF(1);
                [~,turbLocIndex] = min(abs(wakes(uw_turbi).centerLine(1,:)-turbines(dw_turbi).LocWF(1)));
                
                % Q is the normalized velocity deficit on the turbine swept area
                if strcmp(inputData.wakeType,'Zones') && strcmp(inputData.atmoType,'uniform')
                    Q = FlorisQ();
                else
                    Q = integralQ();
                end
                
                % Vni = Wake velocity of upwind turbine at this location
                % multiplied with the relative overlap between the wake and
                % turbine swept area
                Vni = Q/turbines(dw_turbi).rotorArea;

                switch inputData.wakeSum
                    case 'Katic'
%                         (inputData.Ufun(turbines(dw_turbi).hub_height)*(1-Vni)).^2
%                         keyboard

                        sumKed = sumKed+(inputData.Ufun(turbines(dw_turbi).hub_height)*(1-Vni)).^2;
                    case 'Voutsinas'
                        % To compute the energy deficit use the inflow
                        % speed of the upwind turbine instead of Uinf
                        sumKed = sumKed+(turbines(uw_turbi).windSpeed*(1-Vni)).^2;
                end
            end
        end
        turbines(dw_turbi).windSpeed = inputData.Ufun(turbines(dw_turbi).hub_height)-sqrt(sumKed);
        if imag(turbines(dw_turbi).windSpeed)>0
            keyboard
        end
    end
    dwTurbs = turbines(wt_rows{turbirow+1});

    function Q = FlorisQ()
        Q   = turbines(dw_turbi).rotorArea;
        wakeOverlapTurb = [0 0 0];
        for zone = 1:3
           wakeOverlapTurb(zone) = floris_intersect(wakes(uw_turbi).rZones(deltax,zone),turbines(dw_turbi).rotorRadius,...
             hypot(turbines(dw_turbi).LocWF(2)-(wakes(uw_turbi).centerLine(2,turbLocIndex)),...
                   turbines(dw_turbi).LocWF(3)-(wakes(uw_turbi).centerLine(3,turbLocIndex))));

           for zonej = 1:(zone-1) % minus overlap areas of lower zones
               wakeOverlapTurb(zone) = wakeOverlapTurb(zone)-wakeOverlapTurb(zonej);
           end
           Q = Q + 2*turbines(uw_turbi).axialInd*wakes(uw_turbi).cZones(deltax,zone)*wakeOverlapTurb(zone);
        end
    end

    function Q = integralQ()

        Q   = turbines(dw_turbi).rotorArea;
        % Compute the distance between the center of the downwind turbine and the wake centerline of the upwind turbine
        d = wakes(uw_turbi).boundary(deltax)+turbines(dw_turbi).rotorRadius;
        % Compute the distance to the center of the wake of the downwind turbine for some (y,z), (0,0) is the wake centerline
        Rdwt = @(y,z) hypot(turbines(dw_turbi).LocWF(2)+y-(wakes(uw_turbi).centerLine(2,turbLocIndex)),...
                turbines(dw_turbi).LocWF(3)+z-(wakes(uw_turbi).centerLine(3,turbLocIndex)));
        
        if Rdwt(0,0)<d
            zabs = @(z) z+(wakes(uw_turbi).centerLine(3,turbLocIndex));
            VelocityFun =@(y,z) ((Rdwt(y,z)>=wakes(uw_turbi).boundary(deltax)).*inputData.Ufun(zabs(z))+...
                (Rdwt(y,z)<wakes(uw_turbi).boundary(deltax)).*wakes(uw_turbi).V(inputData.Ufun(zabs(z)),turbines(uw_turbi).axialInd,deltax,Rdwt(y,z)))./inputData.Ufun(zabs(z));
            polarfun = @(theta,r) VelocityFun(r.*cos(theta),r.*sin(theta)).*r;
            
            Q = quad2d(polarfun,0,2*pi,0,turbines(dw_turbi).rotorRadius,'Abstol',15,...
                'Singular',false,'FailurePlot',true,'MaxFunEvals',3500);

%             [PHI,R] = meshgrid([0:.1:2*pi 2*pi],0:turbines(dw_turbi).rotorRadius);
%             figure;surf(R.*cos(PHI), R.*sin(PHI), polarfun(PHI,R)./R);
%             title(Q);
%             keyboard
        end
    end

end