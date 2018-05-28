classdef floris < handle
    %FLORIS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        layout
        controlSet
        model
        turbineConditions
        turbineResults
    end
    
    methods
        function obj = floris(layout, controlSet, model)
            %FLORIS Construct an instance of this class
            %   Detailed explanation goes here
            
            if ~isa(layout.ambientInflow, 'ambient_inflow_interface')
                error('You must set an ambientFlow in layout %s.', layout.description)
            end
            obj.layout = layout;
            obj.controlSet = controlSet;
            obj.model = model;
            turbineCondition = struct('avgWS', {[]}, ...
                                      'TI',    {[]}, ...
                                      'rho',   {[]});
            obj.turbineConditions = repmat(turbineCondition, obj.layout.nTurbs, 1);
            % The turbineResults property wil hold a struct array with one struct per turbine.
            turbineResult = struct('affectedBy',    {[]}, ...
                                   'cp',            {[]}, ...
                                   'ct',            {[]}, ...
                                   'axialInduction',{[]}, ...
                                   'wake',          {[]}, ...
                                   'power',         {[]});
            obj.turbineResults = repmat(turbineResult, obj.layout.nTurbs, 1);
        end
        
        function run(obj)
            %RUN Iterate through the turbines and compute the flow and powers
            %   Detailed explanation goes here
            if ~isempty([obj.turbineConditions(:).avgWS])
                warning('floris.run has already been triggered, aborting new run')
                return
            end
            for turbIndex = 1:obj.layout.nTurbs
                turbNum = obj.layout.idWf(turbIndex);
                % Compute the conditions at the rotor of this turbine
                obj.compute_condition(turbNum);
                % Compute CP, CT and power of this turbine
                obj.compute_result(turbNum);
                % Compute which turbines are affected by this turbine
                obj.find_affected_by(turbIndex, turbNum);
            end
        end
        
        function compute_condition(obj, turbNumDw)
            %COMPUTE_CONDITION Compute the conditions at the rotor of this turbine
            %   This function uses the ambientInflow and upwind turbines
            %   whose wake hits the rotor to determine the specific
            %   conditions at the rotor of this turbine.
            
            if isempty(obj.turbineResults(turbNumDw).affectedBy)
                obj.turbineConditions(turbNumDw).avgWS = obj.layout.ambientInflow.Vref;
                obj.turbineConditions(turbNumDw).TI = obj.layout.ambientInflow.TI0;
                obj.turbineConditions(turbNumDw).rho = obj.layout.ambientInflow.rho;
                return
            end
            
            sumKed  = 0; % Sum of kinetic energy deficits (outer sum of Eq. 22)
            TiVec = obj.layout.ambientInflow.TI0; % Turbulence intensity vector
            locationDw = obj.layout.locWf(turbNumDw, :);
            Uhh = obj.layout.ambientInflow.Vfun(locationDw(3)); % Free-stream velocity at hubheigth
            
            for turbNumAffector = obj.turbineResults(turbNumDw).affectedBy.'
                % Compute predicted deficit by turbNumAffector
                locationUw = obj.layout.locWf(turbNumAffector, :);
                deltax = locationDw(1)-locationUw(1);
                [dy, dz] = obj.turbineResults(turbNumAffector).wake.deflection(deltax);
                rotRadius = obj.layout.turbines(turbNumDw).turbineType.rotorRadius;

                dY_wc = @(y) y+locationDw(2)-locationUw(2)-dy;
                dZ_wc = @(z) z+locationDw(3)-locationUw(3)-dz;
                % Create a mask that is 1 where the wake exists and 0 where it
                % does not exists
                mask = @(y,z) obj.turbineResults(turbNumAffector).wake.boundary(deltax,dY_wc(y),dZ_wc(z));
                % Make a velocity function that combines the free stream and
                % wake velocity by using the mask. The velocity function is
                % normalized with respect the to the free stream.
                VelocityFun = @(y,z) (mask(y,z).*obj.turbineResults(turbNumAffector).wake.deficit(deltax,dY_wc(y),dZ_wc(z)));
                polarfun = @(theta,r) VelocityFun(r.*cos(theta),r.*sin(theta)).*r;
                polarfunBound = @(theta,r) mask(r.*cos(theta),r.*sin(theta)).*r;
                
                % Compute the size of the area affected by the wake
                wakeArea = quad2d(polarfunBound,0,2*pi,0,rotRadius,'Abstol',15,...
                'Singular',false,'FailurePlot',true,'MaxFunEvals',3500);
                overlap = wakeArea/obj.layout.turbines(turbNumDw).turbineType.rotorArea;
                % relative volumetric flowrate deficit
                Q = quad2d(polarfun,0,2*pi,0,rotRadius,'Abstol',15,...
                'Singular',false,'FailurePlot',true,'MaxFunEvals',3500);
                Vni = 1-Q/obj.layout.turbines(turbNumDw).turbineType.rotorArea;
                
                
%                 [PHI,Rmesh] = meshgrid([0:.1:2*pi 2*pi],0:rotRadius);
%                 figure;surf(Rmesh.*cos(PHI), Rmesh.*sin(PHI), polarfun(PHI,Rmesh)./Rmesh,'edgeAlpha',0);
%                 title(1-Q/obj.layout.turbines(turbNumDw).turbineType.rotorArea); daspect([1 1 .001]);
%                 
%                 [y,z] = meshgrid(-100:100,-89:100);
%                 wakeV = obj.turbineResults(turbNumAffector).wake.deficit(deltax,dY_wc(y),dZ_wc(z));
%                 figure;surf(y, z, wakeV,'edgeAlpha',0);
%                 keyboard

                % Calculate turbine-added turbulence at location deltax
                TiVec = [TiVec overlap*obj.turbineResults(turbNumAffector).wake.added_TI(deltax, TiVec(1))];
                % Combine the effects of multiple turbines' wakes
                U_uw  = obj.turbineConditions(turbNumAffector).avgWS;
                sumKed = sumKed+obj.model.wakeCombinationModel(Uhh,U_uw,Vni);
            end
            
            obj.turbineConditions(turbNumDw).avgWS = Uhh-sqrt(sumKed);
            obj.turbineConditions(turbNumDw).TI = norm(TiVec);
            if imag(obj.turbineConditions(turbNumDw).avgWS)>0
                keyboard
                % If you end up here, please check the turbine spacing. Are any
                % turbines located in the near wake of another one? Is the
                % windspeed abnormally high or low? Have you made any changes
                % to C_T? Somewhere, the wind speed at a rotor plane is smaller
                % than 0, prompting this error.
            end
            obj.turbineConditions(turbNumDw).rho = obj.layout.ambientInflow.rho;
            % Combine all the added turbulence model using the 2-norm
        end
        
        function compute_result(obj, turbNum)
            %COMPUTE_RESULT Compute CP, CT and power of turbine turbNum
            %   Compute CP, CT and power of turbine turbNum and create its wake
            
            % Use the turbine type to compute the operational parameters of the turbine
            obj.turbineResults(turbNum) = obj.layout.turbines(turbNum).turbineType.cPcTpower(...
                                                obj.turbineConditions(turbNum), ...
                                                obj.controlSet.turbineControls(turbNum), ...
                                                obj.turbineResults(turbNum));
            % Create the wake for this turbine according to the specified model
            obj.turbineResults(turbNum).wake = obj.model.create_wake(...
                                                obj.layout.turbines(turbNum), ...
                                                obj.turbineConditions(turbNum), ...
                                                obj.controlSet.turbineControls(turbNum), ...
                                                obj.turbineResults(turbNum));
        end
        
        function find_affected_by(obj, turbIndex, turbNumUw)
            %FIND_AFFECTED_BY Check which downwind turbines are affected by this turbine
            %   This function uses the wake of this turbine to check if any
            %   donwind turbines re affected by its operation. At first
            %   glance all turbines outside of 1200m wide downwind band are
            %   discarded. The remaining turbines go through a calculation
            %   to see if the wake affects them. The outline of a downwind
            %   turbine is discretized in 6.28/.05 = approx 125 points. If
            %   any of these points are inside the wake the turbine is said
            %   to have been affected.
            
            locationUw = obj.layout.locWf(turbNumUw, :);
            % Only look at turbines that lie within a 1200m wide downwind band
            indexList = turbIndex+1:obj.layout.nTurbs;
            possibleIndexes = indexList(obj.layout.locWf(indexList, 2)<600);
            % Loop through the possible indexes and see if this turbine affects the downwind turbine
            for turbNumDw = obj.layout.idWf(possibleIndexes).'
                locationDw = obj.layout.locWf(turbNumDw, :);
                deltax = locationDw(1)-locationUw(1);
                
                rotRadius = obj.layout.turbines(turbNumDw).turbineType.rotorRadius;
                [dy, dz] = obj.turbineResults(turbNumUw).wake.deflection(deltax);
                
                % Check if any of the rotor outlines fall in the wake boundary
                if any(obj.turbineResults(turbNumUw).wake.boundary(deltax, ...
                           rotRadius*sin(0:.05:2*pi)+locationDw(2)-locationUw(2)-dy, ...
                           rotRadius*cos(0:.05:2*pi)+locationDw(3)-locationUw(3)-dz))
                       % If yes, add this turbNumUw to their affected_by array
                       obj.turbineResults(turbNumDw).affectedBy(end+1,:) = turbNumUw;
                end
            end
        end
    end
end

