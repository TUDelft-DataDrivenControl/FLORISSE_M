clear all; clc;
addpath functions
timer.script = tic;

%% Script settings
plotLayout    = 1; % plot farm layout w.r.t. inertial and wind frame
plotFlowfield = 1; % visualisation in wind-aligned frame
   vis.resx  =  5; % resolution in x-axis in meters (windframe)
   vis.resy  =  5; % resolution in y-axis in meters (windframe)
   fixYaw    =  1; % Account for yaw in near-turbine region in plots

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
% wt_locations_if = [1118.1, 1279.5, 90; 1881.9, 1720.5, 90];

% Turbine operation settings in wind frame
turb.axialInduction = (1/3)*ones(1,size(wt_locations_if,1));  % Axial induction control setting (used only if model.axialIndProvided == true)
yawAngles_wf        = [-27. 10. -30. 10. 10. -15. 0.0 0.0 0.0]; % Yaw misalignment with flow (counterclockwise, wind frame)

% Atmospheric settings
site.u_inf_if   = 4;        % x-direction flow speed inertial frame (m/s)
site.v_inf_if   = 10;      % y-direction flow speed inertial frame (m/s)
site.rho        = 1.1716;   % Atmospheric air density (kg/m3)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Internal code of FLORIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
model = floris_param_model(model.name);  % Import model settings
turb  = floris_param_turbine(turb.name); % Import turbine settings

% Determine wind farm layout in wind-aligned frame. Note that we renumber
% the turbines in the order of appearance w.r.t wind direction (sortvector)
[wt_order,sortvector,site,yawAngles_if,wt_locations_wf,yawAngles_wf ] = floris_frame(site,turb,yawAngles_wf,wt_locations_if ); 

% Setup visualisation grid
if plotFlowfield
    vis.x  = -200:vis.resx:(max(wt_locations_wf(:,1))+1000);
    vis.y  = -200:vis.resy:(max(wt_locations_wf(:,2))+200);
    vis.U  = site.u_inf_wf*ones(length(vis.x),length(vis.y)); % initialize as freestream
end;

% Setup interpolation from NREl5MWCPCT file
if ~model.axialIndProvided
    load('NREL5MWCPCT.mat');
    Ct_interp = fit(NREL5MWCPCT.wind_speed',NREL5MWCPCT.CT','linearinterp');
    Cp_interp = fit(NREL5MWCPCT.wind_speed',NREL5MWCPCT.CP','linearinterp');
end;

timer.core = tic;
% Calculate properties throughout wind farm
wsw(wt_order{1}) = site.u_inf_wf; % Set wind speed in wind frame at first row of turbines as freestream
for turbirow = 1:length(wt_order) % for first to last row of turbines
    for turbi = wt_order{turbirow} % for each turbine in this row
        
        if model.axialIndProvided
            [ Ct(turbi), Cp(turbi), axialInd(turbi), power(turbi) ] = ... Determine Cp, Ct and power
            floris_cpctpower(model,site.rho,turb,wsw(turbi),yawAngles_wf(turbi),turb.axialInduction(turbi) );
        else
            wind_speed_ax = wsw(turbi)*cosd(yawAngles_wf(turbi))^(model.pP/3.0);
            var_in.Ct = Ct_interp(wind_speed_ax); % calculate Ct from CCblade data
            var_in.Cp = Cp_interp(wind_speed_ax); % calculate Cp from CCblade data
            [ Ct(turbi), Cp(turbi), axialInd(turbi), power(turbi) ] = ... Determine Cp, Ct and power
            floris_cpctpower(model,site.rho,turb,wsw(turbi),yawAngles_wf(turbi),var_in );
        end;
        floris_initwake; % calculate ke, mU, and initial wake properties

        % Calculate effects of this (upstream) turbine on downstream visualization coordinates
        if plotFlowfield
            for sample_x = 1:length(vis.x) % first turbine always starts at 0
                deltax = vis.x(sample_x)-wt_locations_wf(turbi,1);
                if deltax >= 0
                    floris_wakeproperties_vis; % Calculate wake locations and diameters at sample locations
                else
                    wakeOverlapRelVis(turbi,sample_x,1:length(vis.y),1:3) = 0;
                end;
            end;
        end;

        % Calculate effects of upstream turbine on downstream rows/turbines
        for dw_turbirow = turbirow+1:length(wt_order)
            deltax = wt_locations_wf(wt_order{dw_turbirow}(1),1)-wt_locations_wf(turbi,1);
            floris_wakeproperties; % Calculate wake locations, diameters & overlap areas
        end;
    end;
    clear turbi dw_turbirow deltax factor displacement dY zone sample_x

    % Finished calculations on entire row 'turbirow'. Now calculate
    % velocity deficits between upstream row and next row
    if plotFlowfield
        if turbirow < length(wt_order)
            sample_x_max = max(find(vis.x<wt_locations_wf(wt_order{turbirow+1}(1)))); % calculate samples until next row
        else
            sample_x_max = length(vis.x); % calculate samples until end of domain
        end;
        for sample_x = min(find(vis.x>=wt_locations_wf(wt_order{turbirow}(1)))):1:sample_x_max;
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
disp(['TIMER: core operations: ' num2str(toc(timer.core)) ' s.']);

% Plot wake effects on upstream turbine on downstream turbines
hfigures=get(0,'Children');
if plotLayout
    if length(hfigures) > 0
        set(0,'CurrentFigure',hfigures(1)); clf;
    else
        figure('Position',[218.6000 263.4000 944.8000 408.8000]);
    end;
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
    if fixYaw
        % Correction for turbine yaw in flow field in turning radius of turbine
        for turbi = 1:size(wt_locations_wf,1) % for each turbine
            ytop    = wt_locations_wf(turbi,2)+cosd(yawAngles_wf(turbi))*turb.rotorDiameter/2;
            ybottom = wt_locations_wf(turbi,2)-cosd(yawAngles_wf(turbi))*turb.rotorDiameter/2;
            
            [~,celltopy]    = min(abs(ytop   - vis.y));
            [~,cellbottomy] = min(abs(ybottom- vis.y));
            
            for celly = cellbottomy-2:1:celltopy+2
                xlocblade = wt_locations_wf(turbi,1)-sind(yawAngles_wf(turbi))*(vis.y(celly)-wt_locations_wf(turbi,2)); % cell location of turbine blade x
                [~,cellxtower] = min(abs(vis.x-wt_locations_wf(turbi,1)));
                [~,cellxblade] = min(abs(vis.x-xlocblade));
                if vis.y(celly) > wt_locations_wf(turbi,2) % top part
                    if yawAngles_wf(turbi) < 0
                        vis.U(cellxtower:cellxblade,celly) = vis.U(cellxtower-1,celly);
                    else
                        vis.U(cellxblade:cellxtower,celly) = vis.U(cellxtower+1,celly);
                    end;
                else % lower part
                    if yawAngles_wf(turbi) < 0
                        vis.U(cellxblade:cellxtower,celly) = vis.U(cellxtower+1,celly);
                    else
                        vis.U(cellxtower:cellxblade,celly) = vis.U(cellxtower-1,celly);
                    end;
                end;
            end;
        end;
    end;
    if length(hfigures) >= plotLayout+plotFlowfield
        set(0,'CurrentFigure',hfigures(1+plotLayout)); clf;
    else
        figure('Position',[218.6000 263.4000 944.8000 408.8000]);
    end;
    contourf(vis.x,vis.y,vis.U','Linecolor','none');
    colormap(parula(30));
    xlabel('x-direction (m)');
    ylabel('y-direction (m)');
    colorbar;
    caxis([floor(min(vis.U(:))) ceil(site.u_inf_wf)])
    for j = 1:size(wt_locations_wf,1)
        hold on;
        plot(wt_locations_wf(j,1)+ [-0.5, +0.5]*turb.rotorDiameter*sind(yawAngles_wf(j)),...
             wt_locations_wf(j,2)+ [+0.5, -0.5]*turb.rotorDiameter*cosd(yawAngles_wf(j)),'k','LineWidth',3); 
          text(wt_locations_wf(j,1)+30,wt_locations_wf(j,2),['T' num2str(j)]);
    end;
    axis equal;
end;

clear x y turb_row turbi turbirow dw_row dw_turbi uw_turbi uw_turbrow sout sinn j ciq Nt
disp(['TIMER: script: ' num2str(toc(timer.script)) ' s.']);