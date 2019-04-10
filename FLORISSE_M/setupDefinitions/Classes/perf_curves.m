classdef perf_curves < handle
    
    properties
        controlMethod % The controlMethod that is being used in this turbine
        structLUT % Struct() containing all the preloaded LUT info
    end
    
    methods
        
        % Initialization of the Cp-Ct mapping (LUTs)
        function obj = perf_curves(controlMethod,Type)
            %TURBINE_TYPE Construct an instance of this class
            %   The turbine characters are saved as properties
            obj.controlMethod = controlMethod;
            
            % Initialize LUTs
            switch controlMethod
                % use pitch angles and Cp-Ct LUTs for pitch and WS,
                case {'pitch'}
                    % TODO: Load the lookup tables for cp and ct as a function of windspeed and pitch
                    % structLUT.pitchRange = [0.0:0.5:5.0];
                    % structLUT.wsRange    = [3.0:1.0:15.0];
                    % structLUT.lutCp      = ...;                     
                    % structLUT.lutCt = ...;
                    
                case {'greedy'}
                    % Load the lookup table for cp and ct -> best to have only one option to provide LuTs?
                    structLUT = read_LUT(Type);
                    
                case {'axialInduction'}
                    % No preparation needed
                    structLUT = struct();
                    
                otherwise
                    error('Control methodology with name: "%s" not defined for the NREL 5MW turbine', controlMethod);
            end
            
            obj.structLUT = structLUT;
            
        end
                
        % Initial values when initializing the turbines
        function [out] = initialValues(obj)
            switch obj.controlMethod
                case {'pitch'}
                    out = struct('pitchAngle', 0);  % Blade pitch angles, by default set to greedy
                case {'greedy'}
                    out = struct(); % Do nothing: leave all variables as NaN
                otherwise
                    error(['Control methodology with name: "' obj.controlMethod '" not defined']);
            end
        end
        
        % Interpolation functions to go from LUT to actual values
        function [cp,ct,adjustCpCtYaw] = calculateCpCt(obj,condition,turbineControl)
            controlMethod = obj.controlMethod;
            structLUT     = obj.structLUT;
            
            switch controlMethod
                case {'pitch'}
                    cp = interp2(structLUT.wsRange, deg2rad(structLUT.pitchRange),...
                        structLUT.lutCp, condition.avgWS, turbineControl.pitchAngle,'linear',0.0);
                    ct = interp2(structLUT.wsRange, deg2rad(structLUT.pitchRange),...
                        structLUT.lutCt, condition.avgWS, turbineControl.pitchAngle,'linear',1e-5);
                    adjustCpCtYaw = true; % do function call 'adjust_cp_ct_for_yaw' after this func.
                    
                case {'greedy'}                    
                    Name = {'WindSpeed','YawMisal','Pitch'};
                    Value = {condition.avgWS,turbineControl.thrustAngle,turbineControl.pitchAngle};
                    VarInd = ismember(fieldnames(structLUT.Variables),Name); % all Variables must be found in name! (in the right order)
                    Variables = struct2cell(structLUT.Variables);
                    cp = interpn(Variables{:},structLUT.Values.Cp,Value{VarInd},'linear',0.0);
                    ct = interpn(Variables{:},structLUT.Values.Ct,Value{VarInd},'linear',1e-5);
                    
                    if not(ismember('YawMisal',fieldnames(structLUT.Variables)))
                        adjustCpCtYaw = true; % do function call 'adjust_cp_ct_for_yaw' after this func.
                    else
                        adjustCpCtYaw = false;
                    end
                    
                otherwise
                    error('Control methodology with name: "%s" not defined', obj.controlMethod);
            end
            
        end
        
    end
end

% local function, not method
function structLuT = read_LUT(Type)
% read LuTs from text files (nested function)

Folder = sprintf('./Settings/Wind Farm/%s/Operating Curves',Type);

% import variables
Variables = readtable([Folder,'/Variables.txt'],'HeaderLines',0,'ReadVariableNames',true,'MultipleDelimsAsOne',true);
Names = Variables.Properties.VariableNames; % keeps order of variables for assignment to struct below
VarGrid = cell(size(Names)); % save variables in cells to enable grid creation via comma-separated-lists
for k=1:length(Names)
    Var = Variables.(Names{k});
    VarGrid{k} = Var(not(isnan(Var))); % delete empty entries in the grid vectors
end
[VarGrid{:}] = ndgrid(VarGrid{:}); % convert grid vectors to arrays
structLuT.Variables = cell2struct(VarGrid,Names,2); % save grids in struct

% import function values
NDims = length(Names);
OpFiles = dir([Folder,'/*.txt']);
for k=1:length(OpFiles)
    
    switch OpFiles(k).name
        
        case 'Variables.txt'
            continue
            
        otherwise
            Data = read_MultiDim([OpFiles(k).folder,'/',OpFiles(k).name],{'\t',';'},NDims,true); % read multi-dimensional LuTs, where order of dimensions conforms to order of variables
            if not(isequal(size(Data),size(VarGrid{1})))
                error('Variable and function dimensionality not compatible!')
            end
            structLuT.Values.(erase(OpFiles(k).name,'.txt')) = Data;
            
    end
    
end

end
