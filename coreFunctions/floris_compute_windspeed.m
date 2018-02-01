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
                
                % Q is the volumetric flowrate relative divided by freestream velocity
                Q = inputData.wakeModel.volFlowRate(wakes(uw_turbi),...
                    turbines(dw_turbi),turbines(uw_turbi),inputData.Ufun,...
                    deltax,turbLocIndex);

                % Vni = Relative volumetric flow rate divided by freestream
                % velocity and swept rotor area
                Vni = Q/turbines(dw_turbi).rotorArea;
%                 if (Vni > 1); keyboard; end
                
                % Calculate turbine-added turbulence at location deltax
                TiVec = [TiVec inputData.wakeModel.turbul(inputData.TI_0,...
                               turbines(dw_turbi),turbines(uw_turbi),...
                               wakes(uw_turbi),turbLocIndex,deltax)];
                           
                % Combine the effects of multiple turbines' wakes
                U_inf = inputData.Ufun(turbines(dw_turbi).hub_height);
                U_uw  = turbines(uw_turbi).windSpeed;
                sumKed = sumKed+inputData.wakeModel.sum(U_inf,U_uw,Vni);

            end
        end
        turbines(dw_turbi).windSpeed = inputData.Ufun(turbines(dw_turbi).hub_height)-sqrt(sumKed);
        turbines(dw_turbi).TI = norm(TiVec);
        if imag(turbines(dw_turbi).windSpeed)>0
            keyboard
            % If you end up here, please check the turbine spacing. Are any
            % turbines located in the near wake of another one? Is the
            % windspeed abnormally high or low? Have you made any changes
            % to C_T? Somewhere, the wind speed at a rotor plane is smaller
            % than 0, prompting this error.
        end
    end
    dwTurbs = turbines(wt_rows{turbirow+1});

    

end