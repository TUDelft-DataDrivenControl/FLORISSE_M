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
            addpath(genpath('coreFunctions')) % Model functions
            addpath('submodelDefinitions')    % Model functions
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
            
            switch controlType
                case {'pitch'}
                    % Choice of how a turbine's axial control setting is determined
                    % 0: use pitch angles and Cp-Ct LUTs for pitch and WS,
                    % 1: greedy control   and Cp-Ct LUT for WS,
                    % 2: specify axial induction directly.
                    inputData.axialControlMethod = 0;
                    inputData.pitchAngles = zeros(1,nTurbs); % Blade pitch angles, by default set to greedy
                    inputData.axialInd    = nan*ones(1,nTurbs); % Axial inductions  are set to NaN to find any potential errors
                    
                    % Determine Cp and Ct interpolation functions as a function of WS and blade pitch
                    for airfoilDataType = {'cp','ct'}
                        lut       = csvread(['turbineDefinitions/' turbType '/' airfoilDataType{1} 'Pitch.csv']); % Load file
                        lut_ws    = lut(1,2:end);          % Wind speed in LUT in m/s
                        lut_pitch = deg2rad(lut(2:end,1)); % Blade pitch angle in LUT in radians
                        lut_value = lut(2:end,2:end);      % Values of Cp/Ct [dimensionless]
                        inputData.([airfoilDataType{1} '_interp']) = @(ws,pitch) interp2(lut_ws,lut_pitch,lut_value,ws,pitch);
                    end
                    
                    % Greedy control: we cannot adjust gen torque nor blade pitch
                case {'greedy'}
                    inputData.axialControlMethod = 1;
                    inputData.pitchAngles = nan*ones(1,nTurbs); % Blade pitch angles are set to NaN to find any potential errors
                    inputData.axialInd    = nan*ones(1,nTurbs); % Axial inductions  are set to NaN to find any potential errors
                    
                    % Determine Cp and Ct interpolation functions as a function of WS
                    lut                 = load(['turbineDefinitions/' turbType '/cpctgreedy.mat']);
                    inputData.cp_interp = @(ws) interp1(lut.wind_speed,lut.cp,ws);
                    inputData.ct_interp = @(ws) interp1(lut.wind_speed,lut.ct,ws);
                    
                    % Directly adjust the axial induction value of each turbine.
                case {'axialInduction'}
                    inputData.axialControlMethod = 2;
                    inputData.pitchAngles = nan*ones(1,nTurbs); % Blade pitch angles are set to NaN to find any potential errors
                    inputData.axialInd    = 1/3*ones(1,nTurbs); % Axial induction factors, by default set to greedy
                    
                otherwise
                    error(['Control methodology with name: "' controlType '" not defined']);
            end
            
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