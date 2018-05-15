function [Q] = flowRateIntegrals(modelData,uw_wake,dw_turbine,uw_turbine,U_inf,deltax,turbLocIndex)

%% Volumetric flow rate calculation
switch modelData.deficitModel
    
    %% Porte-Agel
    case 'PorteAgel'
        % Q is the volumetric flowrate relative divided by freestream velocity
        Q      = dw_turbine.rotorArea;
        bladeR = dw_turbine.rotorRadius;
        
        dY_wc = @(y) y+dw_turbine.LocWF(2)-uw_wake.centerLine(2,turbLocIndex);
        dZ_wc = @(z) z+dw_turbine.LocWF(3)-uw_wake.centerLine(3,turbLocIndex);
        if any(uw_wake.boundary(deltax,dY_wc(bladeR*sin(0:.05:2*pi))',dZ_wc(bladeR*cos(0:.05:2*pi))'))
            Q = dw_turbine.rotorArea-uw_wake.FW_int(deltax, dY_wc(0), dZ_wc(0), bladeR);
        end
        
    %% For discrete wake zones of traditional FLORIS model
    case 'Zones'
        Q   = dw_turbine.rotorArea;
        wakeOverlapTurb = [0 0 0];
        for zone = 1:3
            wakeOverlapTurb(zone) = floris_intersect(uw_wake.rZones(deltax,zone),dw_turbine.rotorRadius,...
                hypot(dw_turbine.LocWF(2)-(uw_wake.centerLine(2,turbLocIndex)),...
                dw_turbine.LocWF(3)-(uw_wake.centerLine(3,turbLocIndex))));
            
            for zonej = 1:(zone-1) % minus overlap areas of lower zones
                wakeOverlapTurb(zone) = wakeOverlapTurb(zone)-wakeOverlapTurb(zonej);
            end
            Q = Q - 2*uw_turbine.axialInd*uw_wake.cZones(deltax,zone)*wakeOverlapTurb(zone);
        end
        
    %% General numerical integration       
    otherwise
        % Function to determine Q (normalized velocity deficit on the turbine
        % swept area) for any kind of wake model following a numerical
        % integration approach.         
%         p = 0; % Default option, no plotting/debugging
        
        bladeR = dw_turbine.rotorRadius;
        Q      = dw_turbine.rotorArea;
        
        % The integral is centered at the downwind turbine, However
        % computations in this functions are easier if we have coordinates
        % that are centered on the wake of the upwind turbine. dY_wc and
        % dZ_wc are wake centered y and z coordinates.
        dY_wc = @(y) y+dw_turbine.LocWF(2)-uw_wake.centerLine(2,turbLocIndex);
        dZ_wc = @(z) z+dw_turbine.LocWF(3)-uw_wake.centerLine(3,turbLocIndex);
        
        % The outer edge of the downwind rotor is approximated by 2*pi/.05
        % points. If any of these points lay withing the upwind wake the
        % rotor is at least partially covered by that wake
        if any(uw_wake.boundary(deltax,dY_wc(bladeR*sin(0:.05:2*pi))',dZ_wc(bladeR*cos(0:.05:2*pi))'))
            
            % zabs takes the downwind rotor centered coordinate z and
            % computes the absolute z-position. This is used for the u_inf
            % function which can be dependent on the absolute heigth
            zabs = @(z) z+dw_turbine.LocWF(3);
            
            % Create a mask that is 1 where the wake exists and 0 where it
            % does not exists
            mask = @(y,z) uw_wake.boundary(deltax,dY_wc(y),dZ_wc(z));
            
            % Make a velocity function that combines the free stream and
            % wake velocity by using the mask. The velocity function is
            % normalized with respect the to the free stream.
            VelocityFun =@(y,z) (~mask(y,z).*U_inf(zabs(z))+...
                mask(y,z).*uw_wake.V(U_inf(zabs(z)),deltax,dY_wc(y),dZ_wc(z)))./U_inf(zabs(z));
            polarfun = @(theta,r) VelocityFun(r.*cos(theta),r.*sin(theta)).*r;
            
            Q = quad2d(polarfun,0,2*pi,0,dw_turbine.rotorRadius,'Abstol',15,...
                'Singular',false,'FailurePlot',true,'MaxFunEvals',3500);
            
%             if p == 1% || dw_turbi == 5
%                 [PHI,Rmesh] = meshgrid([0:.1:2*pi 2*pi],0:bladeR);
%                 figure;surf(Rmesh.*cos(PHI), Rmesh.*sin(PHI), polarfun(PHI,Rmesh)./Rmesh);
%                 title(Q/dw_turbine.rotorArea); daspect([1 1 .001]);
%                 keyboard
%             end
        end
end
end

