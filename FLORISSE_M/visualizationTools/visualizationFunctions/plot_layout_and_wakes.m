function [ ] = plot_layout_and_wakes(obj)

    ambientInflow = obj.layout.ambientInflow;
    D      = 2 * obj.layout.turbines(1).turbineType.rotorRadius;
    turbIF = [obj.layout.locIf];
    turbWF = [obj.layout.locWf];
    YawIfs = ambientInflow.windDirection+obj.yawAngles;
    YawWfs = obj.yawAngles;
    Nt     = size(turbWF,1);
    
    inputData.uInfIf = cos(ambientInflow.windDirection)*ambientInflow.Vref;
    inputData.vInfIf = sin(ambientInflow.windDirection)*ambientInflow.Vref;
    
    % Plot the turbines in the inertial frame
    figure; subplot(1,2,1);
    
    % Plot the turbines (inertial frame)
    for j = 1:Nt
        plot((turbIF(j, 1)+ [-1, 1]*obj.layout.turbines(j).turbineType.rotorRadius*sin(YawIfs(j)))/D,...
             (turbIF(j, 2)+ [1, -1]*obj.layout.turbines(j).turbineType.rotorRadius*cos(YawIfs(j)))/D,'LineWidth',3); hold on;
        text(turbIF(j, 1)/D+0.25,turbIF(j, 2)/D+0.25,['T' num2str(j)]);
    end
    disp('NOTE: Turbines in the Inertial frame are numbered in their definition order');
    disp(' In the wind frame they are ordered according to their x-coordinate');

    % Set labels and image size
    ylabel('Internal y-axis [D]');
    xlabel('Internal x-axis [D]');
    title('Inertial frame');
    grid on; axis equal; hold on;
    xlim([min(turbIF(:, 1)) max(turbIF(:, 1))]/D + [-4 +4]);
    ylim([min(turbIF(:, 2)) max(turbIF(:, 2))]/D + [-4 +4]);
    
    % Plot wind direction
    quiver(min(turbIF(:, 1))/D-3, mean(turbIF(:, 2))/D,...
           inputData.uInfIf/5,inputData.vInfIf/5,'LineWidth',1,'MaxHeadSize',5);
    text(min(turbIF(:, 1))/D-3,mean(turbIF(:, 2))/D+1,'U_{\infty}');
    
    % Plot the turbines in the wind aligned frame
    subplot(1,2,2); hold on;
    wakeXCoords = [turbWF(:, 1).' max(turbWF(:, 1))+D*(1:5)];
    for j = 1:Nt
        xAr = wakeXCoords-turbWF(j, 1);
        xAr = sort(xAr(xAr>=0));
        p = plot((turbWF(j, 1) + [-1, 1]*obj.layout.turbines(j).turbineType.rotorRadius*sin(YawWfs(j)))/D,...
                 (turbWF(j, 2) + [1, -1]*obj.layout.turbines(j).turbineType.rotorRadius*cos(YawWfs(j)))/D,...
                 'LineWidth',3);
            plot((turbWF(j, 1)+xAr)/D,...
                 (turbWF(j, 2)+obj.turbineResults(j).wake.deflection(xAr))/D,...
                 '--','DisplayName','Wake Centerline','Color',get(p,'Color'));
        text(turbWF(j, 1)/D-0.25,turbWF(j, 2)/D+0.75,['T' num2str(find(obj.layout.idWf==j))]);
    end
    
    ylabel('Aligned y-axis [D]');
    xlabel('Aligned x-axis [D]');
    title('Wind-aligned frame');
    grid on; axis equal; hold on;
    xlim([min(turbWF(:, 1)) max(turbWF(:, 1))]/D + [-4 +4]);
    ylim([min(turbWF(:, 2)) max(turbWF(:, 2))]/D + [-4 +4]);
    vInfWf = 0; % FLORIS does not model lateral or vertical speeds
    quiver(min(turbWF(:, 1))/D-3.5, mean(turbWF(:, 2))/D,...
           ambientInflow.Vref/5,vInfWf/5,'LineWidth',1,'MaxHeadSize',5);
    text(min(turbWF(:, 1))/D-3.5,mean(turbWF(:, 2))/D+1,'U_{\infty}');
end