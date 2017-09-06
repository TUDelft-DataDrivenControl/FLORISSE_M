function volvisApp(x,y,z,v)
% volvisApp provides interactive volume visualization
%
% Ex:
% [x,y,z,v] = flow;
% volvisApp(x,y,z,v)
% Based on a program by Loren Shure

%% Initalize visualization
figure;
s = volumeVisualization(x,y,z,v);
coords = {'X','Y','Z'};
mapObj = containers.Map(coords,1:3);

startCoordinate = mapObj('Z');
startPosition = .5;
s.addSlicePlane(startPosition,startCoordinate);

%% Add uicontrol
% Create Slider
hSlider = uicontrol(...
    'Units','normalized', ...
    'Position',[.1 .05 .2 .05], ...
    'Style','slider','Value',startPosition, ...
    'Callback',@updateSliderPosition);

% Create three radio buttons in a button group.
bg = uibuttongroup('units','pixels','Position',[1 1 56 84],...
                   'SelectionChangedFcn',@updateSliderPosition);

for i = 1:length(coords)
    uicontrol(bg,'Style','radiobutton',...
                 'String',coords{i},...
                 'value',i==startCoordinate,...
                 'Position',[10 50-(i-1)*25 100 30]);
end

%% Create a callback function for the UI elements that creates a new plane
function updateSliderPosition(varargin)
    s.deleteLastSlicePlane(2);
    s.addSlicePlane(get(hSlider,'Value'),mapObj(bg.SelectedObject.String));
end
end