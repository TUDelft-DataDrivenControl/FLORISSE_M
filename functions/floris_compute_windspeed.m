function [ dwTurbs ] = floris_compute_windspeed( turbines,wakes,inputData,wt_rows,turbirow )

    for  dw_turbi = wt_rows{turbirow+1}% for all turbines in dw row
        % Sum of kinetic energy deficits
        sumKed  = 0; % outer sum of Eq. 22
        % Turbulence intensity vector
        TiVec = inputData.TI_0;
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
                
                if strcmp(inputData.deflType,'PorteAgel') || strcmp(inputData.wakeType,'PorteAgel')
                    if (Vni < 1)&&(deltax < turbines(uw_turbi).rotorRadius*inputData.TIthresholdMult)
                        R = round(turbines(dw_turbi).rotorRadius+1);
                        [Y,Z]=meshgrid(-R:R,-R:R);

                        overlapRatio = nnz((hypot(Y,Z)<turbines(dw_turbi).rotorRadius)&...
                            (wakes(uw_turbi).boundary(turbines(uw_turbi).TI,deltax,Y+turbines(dw_turbi).LocWF(2)-wakes(uw_turbi).centerLine(2,turbLocIndex),...
                            Z+turbines(dw_turbi).LocWF(3)-wakes(uw_turbi).centerLine(3,turbLocIndex))))/...
                            nnz(hypot(Y,Z)<turbines(dw_turbi).rotorRadius);

                        TI_calc = inputData.TIa*(turbines(uw_turbi).axialInd^inputData.TIb)*...
                            (inputData.TI_0^inputData.TIc)*...
                            ((deltax/(2*turbines(uw_turbi).rotorRadius))^inputData.TId);

                        TiVec = [TiVec overlapRatio*TI_calc];
                    end
                end

                switch inputData.wakeSum
                    case 'Katic'
                        sumKed = sumKed+(inputData.Ufun(turbines(dw_turbi).hub_height)*(1-Vni)).^2;
                    case 'Voutsinas'
                        % To compute the energy deficit use the inflow
                        % speed of the upwind turbine instead of Uinf
                        sumKed = sumKed+(turbines(uw_turbi).windSpeed*(1-Vni)).^2;
                end
            end
        end
        turbines(dw_turbi).windSpeed = inputData.Ufun(turbines(dw_turbi).hub_height)-sqrt(sumKed);
        turbines(dw_turbi).TI = norm(TiVec);
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
        bladeR = turbines(dw_turbi).rotorRadius;
        Q   = turbines(dw_turbi).rotorArea;

        dY_wc = @(y) y+turbines(dw_turbi).LocWF(2)-wakes(uw_turbi).centerLine(2,turbLocIndex);
        dZ_wc = @(z) z+turbines(dw_turbi).LocWF(3)-wakes(uw_turbi).centerLine(3,turbLocIndex);
        
        if max(wakes(uw_turbi).boundary(turbines(uw_turbi).TI,deltax,dY_wc(bladeR*sin(0:.05:2*pi)),dZ_wc(bladeR*cos(0:.05:2*pi))))
            
            zabs = @(z) z+(wakes(uw_turbi).centerLine(3,turbLocIndex));
            mask = @(y,z) wakes(uw_turbi).boundary(turbines(uw_turbi).TI,deltax,dY_wc(y),dZ_wc(z));

            VelocityFun =@(y,z) (~mask(y,z).*inputData.Ufun(zabs(z))+...
                mask(y,z).*wakes(uw_turbi).V(inputData.Ufun(zabs(z)),turbines(uw_turbi).TI,turbines(uw_turbi).axialInd,deltax,dY_wc(y),dZ_wc(z)))./inputData.Ufun(zabs(z));
            polarfun = @(theta,r) VelocityFun(r.*cos(theta),r.*sin(theta)).*r;
            
            Q = quad2d(polarfun,0,2*pi,0,turbines(dw_turbi).rotorRadius,'Abstol',15,...
                'Singular',false,'FailurePlot',true,'MaxFunEvals',3500);

%             [PHI,R] = meshgrid([0:.1:2*pi 2*pi],0:bladeR);
%             figure;surf(R.*cos(PHI), R.*sin(PHI), polarfun(PHI,R)./R);
%             title(Q/turbines(dw_turbi).rotorArea); daspect([1 1 .001]);
%             keyboard
        end
    end

end