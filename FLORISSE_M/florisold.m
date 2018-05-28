classdef floris<handle
    %This is the main FLORIS object
    % space
    
    properties
        inputData
        outputData
        outputFlowField
        outputDataAEP
    end
    
    methods
        function self = floris(siteType,turbType,atmoType,controlType,...
                        wakeDeficitModel,wakeDeflectionModel,wakeSumModel,...
                        wakeTurbulenceModel,modelDataFile)
            %Constructor function initializes default inputData
            
            addpath(genpath('inputFiles'))    % Input functions
            addpath(genpath('coreFunctions')) % Core functions
            addpath('submodelDefinitions')    % Model functions
            addpath('siteDefinitions')        % Site functions
%             addpath('florisCoreFunctions'); % Airfoil data
            
            % Default setup settings (see in floris_loadSettings.m for explanations)
            if ~exist('siteType','var');            siteType            = 'generic_9turb'; end % Wind farm topology ('1turb','9turb')
            if ~exist('turbType','var');            turbType            = 'nrel5mw';    end % Turbine type ('NREL5MW')
            if ~exist('atmoType','var');            atmoType            = 'uniform';    end % Atmospheric inflow ('uniform','boundary')
            if ~exist('controlType','var');         controlType         = 'pitch';      end % Actuation method ('pitch','greedy','axialInduction')         
            if ~exist('wakeDeficitModel','var');    wakeDeficitModel    = 'PorteAgel';  end % Single wake model ('Zones','Gauss','Larsen','PorteAgel')
            if ~exist('wakeDeflectionModel','var'); wakeDeflectionModel = 'PorteAgel';  end % Single wake model ('Zones','Gauss','Larsen','PorteAgel')
            if ~exist('wakeSumModel','var');        wakeSumModel        = 'Katic';      end % Wake addition method ('Katic','Voutsinas')
            if ~exist('wakeTurbulenceModel','var'); wakeTurbulenceModel = 'PorteAgel';  end % Turbine-induced turbulence ('PorteAgel','nothing')
            if ~exist('modelDataFile','var');       modelDataFile       = 'PorteAgel_default';  end % Single wake model ('Zones','Gauss','Larsen','PorteAgel')

            % Site definition
            run([siteType]); 
            
            % Turbine specifications
            run(['turbineDefinitions/' turbType '/specifications.m']); 
            inputData.rotorRadius           = turbine.rotorRadius   * ones(1,nTurbs);
            inputData.generator_efficiency  = turbine.genEfficiency * ones(1,nTurbs);
            inputData.hub_height            = turbine.hubHeight     * ones(1,nTurbs);
            inputData.pP                    = turbine.pP; % yaw power correction parameter
            inputData.LocIF(:,3)            = inputData.hub_height;
            inputData.rotorArea             = pi*inputData.rotorRadius.^2;
            
            % Create single wake model object
            inputData.wakeModel = createWakeObject(wakeDeflectionModel,...
                                                   wakeDeficitModel,...
                                                   wakeSumModel,...
                                                   wakeTurbulenceModel,...
                                                   modelDataFile);
            
            %% Turbine axial control methodology
            % Herein we define how the turbine are controlled. In the traditional
            % FLORIS model, we directly control the axial induction factor of each
            % turbine. However, to apply this in practise, we still need a mapping to
            % the turbine generator torque and the blade pitch angles. Therefore, we
            % have implemented the option to directly control and optimize the blade
            % pitch angles 'pitch', under the assumption of optimal generator torque
            % control. Additionally, we can also assume fully greedy control, where we
            % cannot adjust the generator torque nor the blade pitch angles ('greedy').
            
            
            self.inputData = inputData;
        end
        
        
        %% FLORIS single execution
        function [outputData] = run(self)
            % Run a new FLORIS simulation and additionally reset existing
            % output data (e.g., old flow field)
            [self.outputData] = floris_core(self.inputData);
            self.outputFlowField = [];
            
            % Results saved internally, but also returns externally if desired.
            if nargout > 0; outputData = self.outputData; end
        end
        
    end
end