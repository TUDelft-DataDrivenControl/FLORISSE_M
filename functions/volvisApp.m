function volvisApp(x,y,z,v)
% volvisApp provides interactive volume visualization
%
% Ex:
% [x,y,z,v] = flow;
% volvisApp(x,y,z,v)

%% Initalize visualization
figure;
s = volumeVisualization(x,y,z,v);
s.addSlicePlane(s.xMin);

%% Add uicontrol
hSlider = uicontrol(...
    'Units','normalized', ...
    'Position',[.75 .05 .2 .05], ...
    'Style','slider', ...
    'Min',s.xMin, ...
    'Max',s.xMax, ...
    'Value',s.xMin, ...
    'Callback',@updateSliderPosition);

%%
    function updateSliderPosition(varargin)
        s.deleteLastSlicePlane();
        xloc = get(hSlider,'Value');
        s.addSlicePlane(xloc);
    end

end