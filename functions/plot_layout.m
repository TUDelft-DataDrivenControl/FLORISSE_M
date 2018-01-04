function [ ] = plot_layout( inputData,turbines,wakeCenterLines )

    turbIF = [turbines.LocIF];
    turbWF = [turbines.LocWF];
    YawIfs = [turbines.YawIF];
    YawWfs = [turbines.YawWF];
    Nt     = size(turbWF,2);
    
    inputData.uInfIf = cos(inputData.windDirection)*inputData.uInfWf;
    inputData.vInfIf = sin(inputData.windDirection)*inputData.uInfWf;
    
    % Plot the turbines in the inertial frame
    subplot(1,2,1);
    
    % Plot the turbines (inertial frame)
    for j = 1:Nt
        plot(turbIF(1,j)+ [-1, 1]*turbines(j).rotorRadius*sin(YawIfs(j)),...
             turbIF(2,j)+ [1, -1]*turbines(j).rotorRadius*cos(YawIfs(j)),'LineWidth',3); hold on;
        text(turbIF(1,j)+30,turbIF(2,(j))+20,['T' num2str(turbines(j).turbId_IF)]);
    end
    disp('NOTE: Turbines have a different numbering in IF and WF.');
    disp(' Inspect the variables turbines(i).turbId_IF and .turbId_WF, respectively.');

    % Set labels and image size
    ylabel('Internal y-axis [m]');
    xlabel('Internal x-axis [m]');
    title('Inertial frame');
    grid on; axis equal; hold on;
    xlim([min(turbIF(1,:))-500 max(turbIF(1,:)+500)]);
    ylim([min(turbIF(2,:))-500 max(turbIF(2,:)+500)]);
    
    % Plot wind direction
    quiver(min(turbIF(1,:))-400,mean(turbIF(2,:)),inputData.uInfIf*30,inputData.vInfIf*30,'LineWidth',1,'MaxHeadSize',5);
    text(min(turbIF(1,:))-400,mean(turbIF(2,:))-50,'U_{inf}');
    
    % Plot the turbines in the wind aligned frame
    subplot(1,2,2); hold on;
    for j = 1:Nt
        p = plot(turbWF(1,j) + [-1, 1]*turbines(j).rotorRadius*sin(YawWfs(j)),...
            turbWF(2,j) + [1, -1]*turbines(j).rotorRadius*cos(YawWfs(j)),'LineWidth',3);
        plot([turbWF(1,j) wakeCenterLines{j}(1,:)],[turbWF(2,j) wakeCenterLines{j}(2,:)],'--','DisplayName','Wake Centerline','Color',get(p,'Color'));
        text(turbWF(1,j) +30,turbWF(2,j) +20,['T' num2str(turbines(j).turbId_IF)]);
    end
    
    ylabel('Aligned y-axis [m]');
    xlabel('Aligned x-axis [m]');
    title('Wind-aligned frame');
    grid on; axis equal; hold on;
    xlim([min(turbWF(1,:))-500, max(turbWF(1,:))+500]);
    ylim([min(turbWF(2,:))-500, max(turbWF(2,:))+500]);
    vInfWf = 0; % FLORIS does not model lateral or vertical speeds
    quiver(min(turbWF(1,:))-400,mean(turbWF(2,:)),inputData.uInfWf*30,vInfWf*30,'LineWidth',1,'MaxHeadSize',5);
    text(min(turbWF(1,:))-400,mean(turbWF(2,:))-50,'U_{inf}');
end