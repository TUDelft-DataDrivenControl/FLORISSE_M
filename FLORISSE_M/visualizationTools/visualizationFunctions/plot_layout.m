function [ ] = plot_layout( inputData,turbines,wakeCenterLines )

    D      = 2 * inputData.rotorRadius(1);
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
        plot((turbIF(1,j)+ [-1, 1]*turbines(j).rotorRadius*sin(YawIfs(j)))/D,...
             (turbIF(2,j)+ [1, -1]*turbines(j).rotorRadius*cos(YawIfs(j)))/D,'LineWidth',3); hold on;
        text(turbIF(1,j)/D+0.25,turbIF(2,(j))/D+0.25,['T' num2str(turbines(j).turbId_IF)]);
    end
    disp('NOTE: Turbines may have a different numbering in IF and WF.');
    disp(' Inspect the variables turbines(i).turbId_IF and turbines(i).turbId_WF, respectively.');

    % Set labels and image size
    ylabel('Internal y-axis [D]');
    xlabel('Internal x-axis [D]');
    title('Inertial frame');
    grid on; axis equal; hold on;
    xlim([min(turbIF(1,:)) max(turbIF(1,:))]/D + [-4 +4]);
    ylim([min(turbIF(2,:)) max(turbIF(2,:))]/D + [-4 +4]);
    
    % Plot wind direction
    quiver(min(turbIF(1,:))/D-3, mean(turbIF(2,:))/D,...
           inputData.uInfIf/5,inputData.vInfIf/5,'LineWidth',1,'MaxHeadSize',5);
    text(min(turbIF(1,:))/D-3,mean(turbIF(2,:))/D+1,'U_{\infty}');
    
    % Plot the turbines in the wind aligned frame
    subplot(1,2,2); hold on;
    for j = 1:Nt
        p = plot((turbWF(1,j) + [-1, 1]*turbines(j).rotorRadius*sin(YawWfs(j)))/D,...
                 (turbWF(2,j) + [1, -1]*turbines(j).rotorRadius*cos(YawWfs(j)))/D,...
                 'LineWidth',3);
            plot(([turbWF(1,j) wakeCenterLines{j}(1,:)])/D,...
                 ([turbWF(2,j) wakeCenterLines{j}(2,:)])/D,...
                 '--','DisplayName','Wake Centerline','Color',get(p,'Color'));
        text(turbWF(1,j)/D-0.25,turbWF(2,j)/D+0.75,['T' num2str(turbines(j).turbId_IF)]);
    end
    
    ylabel('Aligned y-axis [D]');
    xlabel('Aligned x-axis [D]');
    title('Wind-aligned frame');
    grid on; axis equal; hold on;
    xlim([min(turbWF(1,:)) max(turbWF(1,:))]/D + [-4 +4]);
    ylim([min(turbWF(2,:)) max(turbWF(2,:))]/D + [-4 +4]);
    vInfWf = 0; % FLORIS does not model lateral or vertical speeds
    quiver(min(turbWF(1,:))/D-3.5, mean(turbWF(2,:))/D,...
           inputData.uInfWf/5,vInfWf/5,'LineWidth',1,'MaxHeadSize',5);
    text(min(turbWF(1,:))/D-3.5,mean(turbWF(2,:))/D+1,'U_{\infty}');
end