function [h1,h2,h3] = plotGP(nr,x,mu,std)
% Plot the Gaussian Process function, given the mean (mu)
% and standard deviation (std) of the GP at input values x. 
%   Inputs:
%   - nr: defines the figure number.
%   - x: input value vector for the GP.
%   - mu: mean values of the GP at x.
%   - std: standard deviation values of the GP at x. 
%   Outputs:
%   - h1: figure handle for the plotted mean.
%   - h2: figure handle for the uncertainty bound given by 2*std.

% Check dimension of the input
dx = size(x,1);

% Initiate figure
figure(nr);
clf(nr);
hold on;
grid on;
box on; 

if dx == 1
    % Plot mean and confidence bound
    h2 = patch([x,fliplr(x)],[mu-2*std, fliplr(mu+2*std)],1,'FaceColor',[0.9,0.9,1],'EdgeColor','none'); 
    set(gca, 'layer', 'top'); 
    h1 = plot(x, mu,'Color',[0,0.45,0.75],'LineWidth',1); 
    % define axis lengths
    xlim([min(x),max(x)])
    ylim([floor(min(mu-2*std)),ceil(max(mu+2*std))])
    % label axes
    xlabel('Input')
    ylabel('Output')
elseif dx == 2
    if iscell(x)
        [Xmesh1,Xmesh2] = ndgrid(x{1},x{2});
    else
        [Xmesh1,Xmesh2] = ndgrid(x(1,:),x(2,:));
    end
    h2 = surface(Xmesh1,Xmesh2,mu-2*std);
    h3 = surface(Xmesh1,Xmesh2,mu+2*std);
    h1 = surface(Xmesh1,Xmesh2,mu);
    
    % set colouring and lines
    set(h2,'FaceAlpha',0.5);
    set(h2,'LineStyle','none');
    set(h2,'FaceColor',[0.8,0.8,1]);
    set(h3,'FaceAlpha',0.5);
    set(h3,'LineStyle','none');
    set(h3,'FaceColor',[0.8,0.8,1]);
    set(h1,'FaceAlpha',0.8);
    set(h1,'FaceColor',[0,0.45,0.75]);
    
    % define axis lengths
    zlim([floor(min(min(mu-2*std))),ceil(max(max(mu+2*std)))])
    if iscell(x)
        xlim([min(x{1}),max(x{1})])
        ylim([min(x{2}),max(x{2})])
    else
        xlim([min(x(1,:)),max(x(1,:))])
        ylim([min(x(2,:)),max(x(2,:))])
    end
    
    % label axes
    xlabel('Input 1')
    ylabel('Input 2')
    zlabel('Output')
    view([315,10]);
else
    disp('Gaussian Process results are only visualized if the dimensions of the input n < 3.')
end

end