classdef floris < matlab.mixin.Copyable%handle
    %FLORIS This is the main class of the FLORIS program
    %   This class iterated through all the turbines and determines their
    %   production and the behaviour of their wakes
    
    properties
        layout
        controlSet
        model
        turbineConditions
        turbineResults
    end
    
    methods (Static)
        function s = saveobj(obj)
            s = obj;
        end
        
        function obj = loadobj(s)
            obj = s;
            
            for i = 1:length(s.layout.turbines)
                obj.layout.turbines(i).turbineType.controlMethod = ...
                    obj.controlSet.controlMethod;
            end
        end
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
            obj.clearOutput();
        end
        
        function clearOutput(obj)
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
            if has_run(obj)
                error('floris.run has already been triggered. Aborting new run.')
            end
            for turbWfIndex = 1:obj.layout.nTurbs
                turbIfIndex = obj.layout.idWf(turbWfIndex);
                % Compute the conditions at the rotor of this turbine
                obj.compute_condition(turbIfIndex);
                % Compute CP, CT and power of this turbine
                obj.compute_result(turbIfIndex);
                % Compute which turbines are affected by this turbine
                obj.find_affected_by(turbWfIndex, turbIfIndex);
            end
        end
        
        function hasRunBoolean = has_run(obj)
            hasRunBoolean = ~isempty([obj.turbineConditions(:).avgWS]);
        end
        
        function compute_condition(obj, turbIfIndex)
            %COMPUTE_CONDITION Compute the conditions at the rotor of this turbine
            %   This function uses the ambientInflow and upwind turbines
            %   whose wake hits the rotor to determine the specific
            %   conditions at the rotor of this turbine.
            
            if isempty(obj.turbineResults(turbIfIndex).affectedBy)
                obj.turbineConditions(turbIfIndex).avgWS = obj.layout.ambientInflow.Vref;
                obj.turbineConditions(turbIfIndex).TI = obj.layout.ambientInflow.TI0;
                obj.turbineConditions(turbIfIndex).rho = obj.layout.ambientInflow.rho;
                return
            end
            sumKed  = 0; % Sum of kinetic energy deficits (outer sum of Eq. 22)
            TiVec = obj.layout.ambientInflow.TI0; % Turbulence intensity vector
            locationDw = obj.layout.locWf(turbIfIndex, :);
            Uhh = obj.layout.ambientInflow.Vfun(locationDw(3)); % Free-stream velocity at hub height

            for turbNumAffector = obj.turbineResults(turbIfIndex).affectedBy.'
                % Compute predicted deficit by turbNumAffector
                locationUw = obj.layout.locWf(turbNumAffector, :);
                deltax = locationDw(1)-locationUw(1);
                [dyWake, dzWake] = obj.turbineResults(turbNumAffector).wake.deflection(deltax);
                rotRadius = obj.layout.turbines(turbIfIndex).turbineType.rotorRadius;
                
                dy = locationDw(2)-locationUw(2)-dyWake;
                dz = locationDw(3)-locationUw(3)-dzWake;
                
                % Compute the portion of the swept area that is affected by
                % the wake from turbNumAffector and compute the relative
                % volumetric flowrate deficit Q
                [overlap, RVdef] = obj.turbineResults(turbNumAffector).wake.deficit_integral(deltax, dy, dz, rotRadius);
                
                % Calculate turbine-added turbulence at location deltax
                TiVec = [TiVec overlap*obj.turbineResults(turbNumAffector).wake.added_TI(deltax)];
                % Combine the effects of multiple turbines' wakes
                U_uw  = obj.turbineConditions(turbNumAffector).avgWS;
                sumKed = sumKed+obj.model.wakeCombinationModel(Uhh, U_uw, RVdef);
            end
            
            obj.turbineConditions(turbIfIndex).avgWS = Uhh-sqrt(sumKed);
            obj.turbineConditions(turbIfIndex).TI = norm(TiVec);
            if imag(obj.turbineConditions(turbIfIndex).avgWS)>0
                keyboard
                % If you end up here, please check the turbine spacing. Are any
                % turbines located in the near wake of another one? Is the
                % windspeed abnormally high or low? Have you made any changes
                % to C_T? Somewhere, the wind speed at a rotor plane is smaller
                % than 0, prompting this error.
            end
            obj.turbineConditions(turbIfIndex).rho = obj.layout.ambientInflow.rho;
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
        
        function find_affected_by(obj, turbWfIndex, turbIfIndex)
            %FIND_AFFECTED_BY Check which downwind turbines are affected by this turbine
            %   This function uses the wake of this turbine to check if any
            %   donwind turbines re affected by its operation. At first
            %   glance all turbines outside of 1200m wide downwind band are
            %   discarded. The remaining turbines go through a calculation
            %   to see if the wake affects them. The outline of a downwind
            %   turbine is discretized in 6.28/.05 = approx 125 points. If
            %   any of these points are inside the wake the turbine is said
            %   to have been affected.
            locationWfUw = obj.layout.locWf(turbIfIndex, :);
            % Only look at turbines that are further downstream than this one
            indexWfList = obj.layout.idWf(turbWfIndex+1:obj.layout.nTurbs);
            % Only look at turbines that lie within a 1200m wide downwind band
            possibleIndexesIf = indexWfList(abs(obj.layout.locWf(indexWfList, 2)-locationWfUw(2))<600);
            if isempty(possibleIndexesIf); return; end
            
            % Loop through the possible indexes and see if this turbine affects the downwind turbine
            for turbNumIfDw = possibleIndexesIf.'
                locationWfDw = obj.layout.locWf(turbNumIfDw, :);
                deltax = locationWfDw(1)-locationWfUw(1);
                
                rotRadius = obj.layout.turbines(turbNumIfDw).turbineType.rotorRadius;
                [dy, dz] = obj.turbineResults(turbIfIndex).wake.deflection(deltax);
                
                % Check if any of the rotor outlines fall in the wake boundary
                if any(obj.turbineResults(turbIfIndex).wake.boundary(deltax, ...
                           rotRadius*sin(0:.05:2*pi)+locationWfDw(2)-locationWfUw(2)-dy, ...
                           rotRadius*cos(0:.05:2*pi)+locationWfDw(3)-locationWfUw(3)-dz))
                       % If yes, add this turbNumUw to their affected_by array
                       obj.turbineResults(turbNumIfDw).affectedBy(end+1,:) = turbIfIndex;
                end
            end
        end
    end
end

