function [ dwTurbs ] = floris_compute_windspeed( turbines,wakes,inputData,wt_rows,turbirow )


    % Calculate the effect of all upstream turbines on the current turbine row
    for  dw_turbi = wt_rows{turbirow+1}
        % Calculate the effect of all upstream turbines on the current turbine
        sumKed  = 0; % Sum of kinetic energy deficits (outer sum of Eq. 22)
        TiVec = inputData.TI_0; % Turbulence intensity vector
        
        for uw_turbrow = 1:turbirow % for all turbine rows upstream of this current turbine
            for uw_turbi = wt_rows{uw_turbrow} % for each turbine in that row
                % displacement in x-direction between uw_turbi and dw_turbi [m]
                deltax = turbines(dw_turbi).LocWF(1)-turbines(uw_turbi).LocWF(1);
                [~,turbLocIndex] = min(abs(wakes(uw_turbi).centerLine(1,:)-turbines(dw_turbi).LocWF(1)));
                
                % Q is the volumetric flowrate relative divided by
                % freestream velocity
                if strcmp(inputData.wakeType,'Zones')
                    Q = FlorisQ(); % Herein we calculate overlap areas between 
                    % different wake zones of uw_turbi and the rotor plane 
                    % of dw_turbi.
                elseif strcmp(inputData.wakeType,'PorteAgel')
                    Q = PorteAgelQ();
                else
                    Q = integralQ(0); % Herein we use a numerical integral 
                    % function to  determine the overlap ratios between a 
                    % wake shape and the rotor plane. This function works
                    % best when the velocity function is continuous
                end

                % Vni = Relative volumetric flow rate divided by freestream
                % velocity and swept rotor area
                Vni = Q/turbines(dw_turbi).rotorArea;
                if (Vni > 1); keyboard; end
                
                if strcmp(inputData.deflType,'PorteAgel') || strcmp(inputData.wakeType,'PorteAgel')
                    % Herein we calculate the overlap area of the wake with
                    % the rotor area by generating many sample points
                    % (meshgrid) at a resolution of 1m x 1m, and counting
                    % the number of points that lie in both the wake and
                    % the rotor plane.
                    if (Vni < 1)&&(deltax < turbines(uw_turbi).rotorRadius*inputData.TIthresholdMult)
                        R = round(turbines(dw_turbi).rotorRadius+1);
                        [Y,Z]=meshgrid(-R:R,-R:R); % Generating grid points

                        % Determine overlap ratio by counting number of
                        % elements that coincide with both planes.
                        overlapRatio = nnz((hypot(Y,Z)<turbines(dw_turbi).rotorRadius)&...
                            (wakes(uw_turbi).boundary(deltax,Y+turbines(dw_turbi).LocWF(2)-wakes(uw_turbi).centerLine(2,turbLocIndex),...
                            Z+turbines(dw_turbi).LocWF(3)-wakes(uw_turbi).centerLine(3,turbLocIndex))))/...
                            nnz(hypot(Y,Z)<turbines(dw_turbi).rotorRadius);
                        % Determine effects of turbulence intensity
                        TI_calc = inputData.TIa*(turbines(uw_turbi).axialInd^inputData.TIb)*...
                            (inputData.TI_0^inputData.TIc)*...
                            ((deltax/(2*turbines(uw_turbi).rotorRadius))^inputData.TId);

                        TiVec = [TiVec overlapRatio*TI_calc];
                    end
                end

                % Combine the effects of multiple turbines' wakes
                switch inputData.wakeSum
                    case 'Katic' % Using Katic (traditional FLORIS)
                        sumKed = sumKed+(inputData.Ufun(turbines(dw_turbi).hub_height)*(1-Vni)).^2;
                    case 'Voutsinas' % Using Voutsinas (Porte-Agel)
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

    
    % Function to determine Q (normalized velocity deficit on the turbine
    % swept area) for the wake model with multiple zones.
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
           Q = Q - 2*turbines(uw_turbi).axialInd*wakes(uw_turbi).cZones(deltax,zone)*wakeOverlapTurb(zone);
        end
    end

    function Q = PorteAgelQ()
        Q = turbines(dw_turbi).rotorArea;
        bladeR = turbines(dw_turbi).rotorRadius;

        dY_wc = @(y) y+turbines(dw_turbi).LocWF(2)-wakes(uw_turbi).centerLine(2,turbLocIndex);
        dZ_wc = @(z) z+turbines(dw_turbi).LocWF(3)-wakes(uw_turbi).centerLine(3,turbLocIndex);
        if any(wakes(uw_turbi).boundary(deltax,dY_wc(bladeR*sin(0:.05:2*pi))',dZ_wc(bladeR*cos(0:.05:2*pi))'))
            Q = turbines(dw_turbi).rotorArea-wakes(uw_turbi).FW_int(deltax, dY_wc(0), dZ_wc(0), bladeR);
            % Compare the power series approximation to a numerical method
%             Qacc = integralQ(0);
%             display(dw_turbi)
%             display([Q, Qacc])
%             display(100*(Q/Qacc)-100)
%             display(Q/Qacc)
        end
    end

    % Function to determine Q (normalized velocity deficit on the turbine
    % swept area) for any kind of wake model following a numerical
    % integration approach.
    function Q = integralQ(p)
        bladeR = turbines(dw_turbi).rotorRadius;
        Q   = turbines(dw_turbi).rotorArea;

        dY_wc = @(y) y+turbines(dw_turbi).LocWF(2)-wakes(uw_turbi).centerLine(2,turbLocIndex);
        dZ_wc = @(z) z+turbines(dw_turbi).LocWF(3)-wakes(uw_turbi).centerLine(3,turbLocIndex);
        if any(wakes(uw_turbi).boundary(deltax,dY_wc(bladeR*sin(0:.05:2*pi))',dZ_wc(bladeR*cos(0:.05:2*pi))'))
            
            zabs = @(z) z+(wakes(uw_turbi).centerLine(3,turbLocIndex));
            mask = @(y,z) wakes(uw_turbi).boundary(deltax,dY_wc(y),dZ_wc(z));

            VelocityFun =@(y,z) (~mask(y,z).*inputData.Ufun(zabs(z))+...
                mask(y,z).*wakes(uw_turbi).V(inputData.Ufun(zabs(z)),deltax,dY_wc(y),dZ_wc(z)))./inputData.Ufun(zabs(z));
            polarfun = @(theta,r) VelocityFun(r.*cos(theta),r.*sin(theta)).*r;
            
            Q = quad2d(polarfun,0,2*pi,0,turbines(dw_turbi).rotorRadius,'Abstol',15,...
                'Singular',false,'FailurePlot',true,'MaxFunEvals',3500);

            if p == 1% || dw_turbi == 5
                [PHI,Rmesh] = meshgrid([0:.1:2*pi 2*pi],0:bladeR);
                figure;surf(Rmesh.*cos(PHI), Rmesh.*sin(PHI), polarfun(PHI,Rmesh)./Rmesh);
                title(Q/turbines(dw_turbi).rotorArea); daspect([1 1 .001]);
                keyboard
            end
        end
    end

end