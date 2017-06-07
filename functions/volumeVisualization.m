function s = volumeVisualization(x,y,z,v)

% Based on a program by Loren Shure

%% Create a variable to store pointers to the various planes
hAxis = [];         %initialize handle to axis
hSlicePlanes = [];  %initialize handle to slice plane
% minmax holds the min and max values of the flowfield
minmax = [min(x(:)),max(x(:));min(y(:)),max(y(:));min(z(:)),max(z(:))];

%% Plot the volume initially
initDisplay()

%% Nested Functions
    function addSlicePlane(Loc,Dim)
        % addSlicePlane   Add a slice plane at specified coordinate.
        dims = {[],[],[]};
        dims{Dim} = minmax(Dim,1)+Loc*diff(minmax(Dim,:));

        newSlicePlane = slice(hAxis, x, y, z, v, dims{1}, dims{2}, dims{3});
        hSlicePlanes   = [ hSlicePlanes, newSlicePlane ];
        set(newSlicePlane,'FaceColor'      ,'interp',...
            'EdgeColor'      ,'none'  ,...
            'DiffuseStrength',.8       );
    end

    function deleteLastSlicePlane()
        if ~isempty(hSlicePlanes)
            delete(hSlicePlanes(end));
            hSlicePlanes = hSlicePlanes(1:end-1);
        end
    end

    function initDisplay()
        % initDisplay  Initialize Display

        % Draw back and bottom walls
        if isempty(hAxis) || ~ishandle(hAxis)
            hAxis = gca;
            hold on;
            hAxis.BoxStyle = 'full';
        end
        hx = slice(hAxis, x, y, z, v,minmax(1,2),         [],         []) ;
        hy = slice(hAxis, x, y, z, v,         [],minmax(2,2),         []) ;
        hz = slice(hAxis, x, y, z, v,         [],         [],minmax(3,1)) ;

        % Make everything look nice
        set([hx hy hz],'FaceColor','interp','EdgeColor','none')
        set(hAxis,'FontSize',18,'FontWeight','Bold');
        xlabel('X'); ylabel('Y');  zlabel('Z')
        daspect([1,1,1])
        axis tight
        box on
        view(-38.5,16)
        colormap(parula(30));
    end
%% final code
s.addSlicePlane    = @addSlicePlane    ;
s.deleteLastSlicePlane = @deleteLastSlicePlane;
end