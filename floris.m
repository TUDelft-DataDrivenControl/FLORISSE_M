clear all; close all; clc;
addpath functions
tic;

%% Script settings
plotLayout    = true;
plotFlowfield = true; % visualisation in wind-aligned frame
   vis.resx  = 30;    % resolution in x-axis (windframe)
   vis.resy  = 30;    % resolution in y-axis (windframe)

%% Simulation setup
model.name = 'default';  % load default model parameters
turb.name  = 'nrel5mw';  % load turbine settings (NREL 5MW baseline)

% Wind turbine locations in internal frame 
wt_locations_if = [300,    100.0,  90.0; ...
                   300,    300.0,  90.0; ...
                   300,    500.0,  90.0; ...
                   1000,   100.0,  90.0; ...
                   1000,   300.0,  90.0; ...
                   1000,   500.0,  90.0; ...
                   1600,   100.0,  90.0; ...
                   1600,   300.0,  90.0; ...
                   1600,   500.0,  90.0];

% Turbine operation settings in wind frame               
turb.axialInduction = +0.33*ones(1,size(wt_locations_if,1)); % Axial induction control setting used only if specified by FLORIS
yawAngles_wf        = 10.0*ones(1,size(wt_locations_if,1));  % Yaw misalignment with flow (counterclockwise, wind frame)

% Atmospheric settings
site.u_inf_if   = [6];          % x-direction flow speed (inertial frame)
site.v_inf_if   = [-2];           % y-direction flow speed (inertial frame)
site.rho        = 1.1716;        % Air density


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Internal code of FLORIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
model = floris_param_model(model);  % Import model settings
turb  = floris_param_turbine(turb); % Import turbine settings

% Determine wind farm layout in wind-aligned frame
[ wt_order,sortvector, site,yawAngles_if,wt_locations_wf ] = floris_frame(site,turb,yawAngles_wf,wt_locations_if ); 

% Setup visualisation grid
if plotFlowfield
    vis.x  = -200:vis.resx:(max(wt_locations_wf(:,1))+1000);
    vis.y  = -200:vis.resy:(max(wt_locations_wf(:,2))+200);
    vis.z  = turb.hub_height*ones(size(vis.x));
    vis.U  = site.u_inf_wf  *ones(length(vis.x),length(vis.y));
end;

% Calculate properties throughout wind farm
wsw(wt_order{1}) = site.u_inf_wf; % Set wind speed in wind frame at first row of turbines as freestream
for turbirow = 1:length(wt_order) % for first to last row of turbines
    for turbi = wt_order{turbirow} % for each turbine in this row
        
        [ Ct(turbi), Cp(turbi), axialInd(turbi), power(turbi) ] = ... Determine Cp, Ct, axial induction factor and power
        floris_cpctpower(model,site,turb,wsw(turbi),yawAngles_wf(turbi),turb.axialInduction(turbi) );

        % Calculate ke
        ke(turbi) = model.ke + model.keCorrCT*(Ct(turbi)-model.baselineCT);
        
        % Calculate mU: decay rate of wake zones
        if model.useaUbU
            mU{turbi} = model.MU/cosd(model.aU+model.bU*yawAngles_wf(turbi));
        else
            mU{turbi} = model.MU;
        end;
        
        % Calculate initial wake deflection
        wakeAngleInit(turbi) = 0.5*sind(yawAngles_wf(turbi))*Ct(turbi); % Eq. 8
        if model.useWakeAngle
            wakeAngleInit(turbi) = wakeAngleInit(turbi) + model.initialWakeAngle*pi/180; 
        end;
               
        % Calculate initial wake diameter
        if model.adjustInitialWakeDiamToYaw
            wakeDiameter0(turbi) = turb.rotorDiameter*cosd(yawAngles_wf(turbi));
        else
            wakeDiameter0(turbi) = turb.rotorDiameter;
        end;
        
        % Calculate effects of upstream turbine on downstream coordinates
        if plotFlowfield
            for sample_x = 1:length(vis.x) % first turbine always starts at 0
                deltax = vis.x(sample_x)-wt_locations_wf(turbi,1);
                if deltax <= 0
                    wakeOverlapRelVis(turbi,sample_x,1:length(vis.y),1:3) = 0;
                else
                    floris_wakeproperties_vis; % Calculate wake locations and diameters at sample locations
                end;
            end;
        end;

        % Calculate effects of upstream turbine on downstream rows/turbines
        for dw_turbirow = turbirow+1:length(wt_order)
            deltax = wt_locations_wf(wt_order{dw_turbirow}(1),1)-wt_locations_wf(turbi,1);
            floris_wakeproperties; % Calculate wake locations, diameters & overlap areas
            %end;
        end;
    end;
    clear turbi dw_turbirow deltax factor displacement dY zone sample_x

    % Finished calculations on row 'turbrow'. Now calculate velocity deficits
    if plotFlowfield
        if turbirow < length(wt_order)
            sample_x_max = max(find(vis.x<=wt_locations_wf(wt_order{turbirow+1}(1))));
        else
            sample_x_max = length(vis.x);
        end;
        for sample_x = min(find(vis.x>wt_locations_wf(wt_order{turbirow}(1)))):1:sample_x_max;
            for sample_y = 1:length(vis.y) % for all turbines in dw row
                sout   = 0; % outer sum of Eq. 22
                for uw_turbrow = 1:turbirow % for all rows upstream of this current row
                    for uw_turbi = wt_order{uw_turbrow} % for each turbine in that row
                        deltax = vis.x(sample_x)-wt_locations_wf(uw_turbi,1);

                        sinn   = 0; % inner sum of Eq. 22
                        for zone = 1:3
                            ciq = (turb.rotorDiameter/(turb.rotorDiameter + 2*ke(uw_turbi)*mU{uw_turbi}(zone)*deltax))^2; % Eq. 16
                            sinn = sinn + ciq*wakeOverlapRelVis(uw_turbi,sample_x,sample_y,zone);
                        end;

                        sout = sout + (axialInd(uw_turbi)*sinn)^2;
                    end;
                end;
                vis.U(sample_x,sample_y) = site.u_inf_wf*(1-2*sqrt(sout));
            end;
        end;
        clear sample_x_max sout sin deltax ciq 
    end;
    
    % .. and for turbines
    if turbirow < length(wt_order)
        for dw_turbi = wt_order{turbirow+1} % for all turbines in dw row
            
            sout   = 0; % outer sum of Eq. 22
            for uw_turbrow = 1:turbirow % for all rows upstream of this current row
                for uw_turbi = wt_order{uw_turbrow} % for each turbine in that row
                    sinn   = 0; % inner sum of Eq. 22
                    deltax = wt_locations_wf(dw_turbi,1)-wt_locations_wf(uw_turbi,1);
                    for zone = 1:3
                        ciq = (turb.rotorDiameter/(turb.rotorDiameter + 2*ke(uw_turbi)*mU{uw_turbi}(zone)*deltax))^2; % Eq. 16
                        sinn = sinn + ciq*wakeOverlapRelTurb(uw_turbi,dw_turbi,zone);
                    end;
                    
                    sout = sout + (axialInd(uw_turbi)*sinn)^2;
                end;
            end;
            wsw(dw_turbi) = site.u_inf_wf*(1-2*sqrt(sout));
        end;
    end;
end;

% Plot wake effects on upstream turbine on downstream turbines
if plotLayout
    figure('Position',[372 360 1678 652]);
    Nt = size(wt_locations_wf,1);
    
    subplot(1,2,1);
    for j = 1:Nt
        plot(wt_locations_if(sortvector(j),1)+ 0.5*[-1, 1]*turb.rotorDiameter*sind(yawAngles_if(sortvector(j))),...
             wt_locations_if(sortvector(j),2)+ 0.5*[1, -1]*turb.rotorDiameter*cosd(yawAngles_if(sortvector(j))),'LineWidth',3); hold on;
        text(wt_locations_if(sortvector(j),1),wt_locations_if(sortvector(j),2),['T' num2str(j)]);
    end;
    ylabel('Internal y-axis [m]');
    xlabel('Internal x-axis [m]');
    title('Inertial frame');
    grid on; axis equal; hold on;
    xlim([min([wt_locations_if(:,1)-500]), max(wt_locations_if(:,1))+500]);
    ylim([min([wt_locations_if(:,2)-500]), max(wt_locations_if(:,2))+500]);
    
    quiver(min(wt_locations_if(:,1))-400,mean(wt_locations_if(:,2)),site.u_inf_if*30,site.v_inf_if*30,'LineWidth',1,'MaxHeadSize',5);
    text(min(wt_locations_if(:,1))-400,mean(wt_locations_if(:,2))-50,'U_{inf}');
    
    subplot(1,2,2);   
    for j = 1:Nt
        plot(wt_locations_wf(j,1)+ 0.5*[-1, 1]*turb.rotorDiameter*sind(yawAngles_wf(j)),...
             wt_locations_wf(j,2)+ 0.5*[1, -1]*turb.rotorDiameter*cosd(yawAngles_wf(j)),'LineWidth',3); hold on;
        text(wt_locations_wf(j,1),wt_locations_wf(j,2),['T' num2str(j)]);
    end;
    for turb_row = 1:length(wt_order)-1
        for turbi = wt_order{turb_row}
            x{turbi} = wt_locations_wf(turbi,1);
            y{turbi} = wt_locations_wf(turbi,2);
            for dw_row = turb_row+1:length(wt_order) % for all dw turbines
                x{turbi} = [x{turbi} wt_locations_wf(wt_order{dw_row}(1),1)];
                y{turbi} = [y{turbi} wake_locY_wf_Turb(turbi,dw_row)];
            end;
            hold on;
            plot(x{turbi},y{turbi},'--','DisplayName','Wake Centerline');
        end;
    end;
    ylabel('Aligned y-axis [m]');
    xlabel('Aligned x-axis [m]');
    title('Wind-aligned frame');
    grid on; axis equal; hold on;
    xlim([min(wt_locations_wf(:,1))-500, max(wt_locations_wf(:,1))+500]);
    ylim([min(wt_locations_wf(:,2))-500, max(wt_locations_wf(:,2))+500]);
    quiver(min(wt_locations_wf(:,1))-400,mean(wt_locations_wf(:,2)),site.u_inf_wf*30,site.v_inf_wf*30,'LineWidth',1,'MaxHeadSize',5);
    text(min(wt_locations_wf(:,1))-400,mean(wt_locations_wf(:,2))-50,'U_{inf}');
    
end;

if plotFlowfield
    figure('Position',[372 360 1678 652]);
    contourf(vis.x,vis.y,vis.U','Linecolor','none');
    colormap(jet);
    xlabel('x-direction (m)');
    ylabel('y-direction (m)');
    colorbar;
    caxis([0 site.u_inf_wf])
    for j = 1:size(wt_locations_wf,1)
        hold on;
        plot(wt_locations_wf(j,1)+ 0*[-1, 1]*turb.rotorDiameter*sind(yawAngles_wf(j)),...
             wt_locations_wf(j,2)+ 0*[1, -1]*turb.rotorDiameter*cosd(yawAngles_wf(j)),'LineWidth',3); 
        %text(wt_locations_wf(j,1),wt_locations_wf(j,2),['T' num2str(j)]);
    end;
    axis equal;
end;

clear x y turb_row turbi turbirow dw_row dw_turbi uw_turbi uw_turbrow sout sinn j ciq Nt
toc;