classdef turbine_type < handle
    %turbine_prototype This is the superclass for any turbine.
    %   This class inherits from handle. Each turbine object should thus be
    %   considered an immutable description of its characteristics. The
    %   time variable functions of the turbine should not be stored here.
    
    properties
        controlMethod
        rotorRadius
        genEfficiency
        hubHeight
        pP
    end
    properties (Access = private)
        allowableControlMethods
        dataPath
        cpInterp
        ctInterp
    end
    
    methods
        function obj = turbine_type(rotorRadius, genEfficiency, hubHeight, pP, path, allowableControlMethods)
            %turbine_prototype Construct an instance of this class
            %   The turbine characters are saved as properties
            obj.controlMethod = nan;
            obj.dataPath = path;
            obj.allowableControlMethods = allowableControlMethods;
            
            obj.rotorRadius = rotorRadius;
            obj.genEfficiency = genEfficiency;
            obj.hubHeight = hubHeight;
            obj.pP = pP;
        end
        
        function set.controlMethod(obj, controlMethod)
            %set_cp_and_ct_functions Create cp and ct functions
            % Herein we define how the turbine are controlled. In the traditional
            % FLORIS model, we directly control the axial induction factor of each
            % turbine. However, to apply this in practise, we still need a mapping to
            % the turbine generator torque and the blade pitch angles. Therefore, we
            % have implemented the option to directly control and optimize the blade
            % pitch angles 'pitch', under the assumption of optimal generator torque
            % control. Additionally, we can also assume fully greedy control, where we
            % cannot adjust the generator torque nor the blade pitch angles ('greedy').
            
            % Choice of how a turbine's axial control setting is determined
            % pitch:          use pitch angles and Cp-Ct LUTs for pitch and WS,
            % greedy:         greedy control   and Cp-Ct LUT for WS,
            % axialInduction: specify axial induction directly.
            

            if isnan(controlMethod)
                return
            end
            if ~any(strcmp(obj.allowableControlMethods, controlMethod))
                error('Turbine of class "%s", does not support control method: "%s"',...
                      class(obj), controlMethod)
            end
            obj.controlMethod = controlMethod;
            switch controlMethod
                % use pitch angles and Cp-Ct LUTs for pitch and WS,
                case {'pitch'}
                    % Determine Cp and Ct interpolation functions as a
                    % function of WS and blade pitch
                    airfoilDataType = {'cp','ct'};
                    for i = [1, 2]
                        % Load file
                        lut = csvReadCCompatible([obj.dataPath '/' airfoilDataType{1} 'Pitch.csv']);
                        % lut = csvread([obj.dataPath '/' airfoilDataType{1} 'Pitch.csv']);
                        % lut = load([obj.dataPath '/' airfoilDataType{i} 'Pitch.mat']);
                        % Wind speed in LUT in m/s
                        lut_ws    = lut(1,2:end)*.9999;
                        % Blade pitch angle in LUT in radians
                        lut_pitch = lut(2:end,1)*.9999;
%                         lut_pitch = deg2rad(lut(2:end,1));
                        % Values of Cp/Ct [dimensionless]
                        lut_value = lut(2:end,2:end)*.9999;
                        
                        % Define the lookup tables
                        [X,Y] = meshgrid(lut_ws,lut_pitch);
                        obj.([airfoilDataType{i} 'Interp']) = @(ws,pitch) codegen_interp2(X,Y,lut_value,ws,pitch);
%                         obj.([airfoilDataType{i} 'Interp']) = @(ws,pitch) interp2(lut_ws,lut_pitch,lut_value,ws,pitch);
                    end
                    
                % Greedy control: Optimized control settings are determined
                % based on the windspeed
                case {'greedy'}
                    % Determine Cp and Ct interpolation functions as a function of WS
%                     lut = load([obj.dataPath '/cpctgreedy.mat']);
%                     obj.cpInterp = @(ws) interp1(lut.wind_speed,lut.cp,ws);
%                     obj.ctInterp = @(ws) interp1(lut.wind_speed,lut.ct,ws);
                    
                % Directly adjust the axial induction value of each turbine.
                case {'axialInduction'}
%                     obj.cpInterp = @(ai) 4*ai*(1-ai);
%                     obj.ctInterp = @(ai) 4*ai*(1-ai)^2;
                    
                otherwise
                    error('Control methodology with name: "%s" not defined', controlMethod);
            end
        end
        
        function cpVal = cp(obj, condition, controlStruct)
            %CP returns cp value
            %   Computes the power coefficient for this turbine depending
            %   on the condition at the rotor area and the controlset of
            %   the turbine
            cpVal = obj.cpInterp(condition, controlStruct);
        end
        
        function ctVal = ct(obj, condition, controlStruct)
            %CT returns ct value
            %   Computes the thrust coefficient for this turbine depending
            %   on the condition at the rotor area and the controlset of
            %   the turbine
            ctVal = obj.ctInterp(condition, controlStruct);
        end
    end
end

function lut = csvReadCCompatible(path)
    fid = fopen(path);
    a = fread(fid, '*char');
    fclose(fid);

    iis = 0;
    lls = 1;
    line1 = 1;
    nl = 0;
    for pos = 1:length(a)
        if (a(pos) == ',') && line1
            lls=lls+1;
        end
        if (a(pos) == char(13))||(a(pos) == char(10))
            if nl == 0
                line1 = 0;
                nl = 1;
                iis = iis + 1;
            end
        else
            nl = 0;
        end
    end
    lut = zeros(iis,lls);

    ii=1;
    ll=1;
    num = '                                       ';
    aai =1;
    nl = 0;
    for pos = 1:length(a)
        if (a(pos) == ',')
            lut(ii,ll) = real(str2double(num));
            ll=ll+1;
            num = '                                       ';
            aai =1;
            nl = 0;
        elseif ~(a(pos) == char(13))||(a(pos) == char(10))
            num(aai) = a(pos);
            aai = aai +1;
            nl = 0;
        elseif (a(pos) == char(13))||(a(pos) == char(10))
            if nl == 0
                nl = 1;
                lut(ii,ll) = real(str2double(num));
                ii = ii + 1;
                ll=1;
                num = '                                       ';
                aai =1;
            end
        end
    end
end

function Zi = codegen_interp2(X,Y,Z,xi,yi)
%#codegen
% zi = codegen_interp2(X,Y,Z,xi,yi) gives the same result as
% interp2(X,Y,Z,xi,yi)
% Unlike interp2, codegen_interp2 is compatible with code generation
% Only linear interpolation is available

% Usage restrictions
%   X and Y must have the same size as Z
%   e.g.,  [X,Y] = meshgrid(x,y);
% keyboard
X = X*1.0001;
Y = Y*1.0001;
Z = Z*1.0001;
xi = xi*1.0001;
yi = yi*1.0001;
ndx = 1/(X(1,2)-X(1,1));        ndy = 1/(Y(2,1)-Y(1,1));

idyi=(xi - X(1,1))*ndx+1;       idxi=(yi - Y(1,1))*ndy+1;

if idxi/ceil(idxi)~=1&&idyi/ceil(idyi)~=1
    if any(any(isnan(Z)))
        error('nancrash')
    end
    Z1=Z(ceil(idxi)-1,ceil(idyi)-1);
    Z2=Z(ceil(idxi)-1,ceil(idyi));
    Z3=Z(ceil(idxi),ceil(idyi)-1);
    Z4=Z(ceil(idxi),ceil(idyi));
    
    Zi= Z1*(ceil(idxi)-idxi)*(ceil(idyi)-idyi)+...
        Z2*(ceil(idxi)-idxi)*(1-(ceil(idyi)-idyi))+...
        Z3*(1-(ceil(idxi)-idxi))*(ceil(idyi)-idyi)+...
        Z4*(1-(ceil(idxi)-idxi))*(1-(ceil(idyi)-idyi));
    
elseif idxi/ceil(idxi)~=1&&idyi/ceil(idyi)==1
    Z1=Z(ceil(idxi)-1,idyi);
    Z2=Z(ceil(idxi),idyi);
    
    Zi=Z1*(ceil(idxi)-idxi)+Z2*(1-(ceil(idxi)-idxi));
    
elseif idxi/ceil(idxi)==1&&idyi/ceil(idyi)~=1    
    Z1=Z(idxi,ceil(idyi)-1);
    Z2=Z(idxi,ceil(idyi));
    
    Zi=Z1*(ceil(idyi)-idyi)+Z2*(1-(ceil(idyi)-idyi));
else
    Zi=Z(idxi,idyi);    
end
    
end