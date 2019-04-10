classdef model_definition < matlab.mixin.Copyable
    %MODEL_DEFINITION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        modelData
        deflectionModel
        velocityDeficitModel
        wakeCombinationModel
        addedTurbulenceModel
    end
    
    methods
        % TODO: Use inputParser to check name-calue pairs
        function obj = model_definition(~, deflectionModel, ...
                                        ~, velocityDeficitModel, ...
                                        ~, wakeCombinationModel, ...
                                        ~, addedTurbulenceModel)
            %MODEL_DEFINITION Construct an instance of this class
            %   Detailed explanation goes here
            
            Folder = './Settings/Wake Parameters/';
            
            % Put the relevant deflection parameters into the modelData struct and store a function handle to the chosen model
            switch deflectionModel
                case 'jimenez'
                    Deflection = readstruct([Folder,'Deflection/Jimenez.txt']);
                    obj.deflectionModel = @jimenez_deflection;
                case 'rans'
                    Deflection = readstruct([Folder,'Deficit/SelfSimilarGaussianRANS.txt']);
                    obj.deflectionModel = @rans_deficit_deflection;
                otherwise
                    error('Deflection model with name: "%s" is not defined', deflectionModel);
            end
            Deflection = append_StructFields(Deflection,readstruct([Folder,'Deflection/Linear.txt'])); % linear wake deflection always present

            % Put the relevant velocity deficit parameters into the modelData
            % struct and store a function handle to the chosen model
            switch velocityDeficitModel
                case 'jensenGauss'
                    Deficit = readstruct([Folder,'Deficit/Jensen.txt']);
                    obj.velocityDeficitModel = @jensen_gaussian_velocity;
                case 'zones'
                    Deficit = readstruct([Folder,'Deficit/Zones.txt']);
                    obj.velocityDeficitModel = @zoned_velocity;
                case 'larsen'
                    obj.velocityDeficitModel = @larsen_velocity;
                case 'selfSimilar'
                    Deficit = readstruct([Folder,'Deficit/SelfSimilarGaussianRANS.txt']);
                    obj.velocityDeficitModel = @self_similar_gaussian_velocity;
                otherwise
                    error('Velocity model with name: "%s" is not defined', velocityDeficitModel);
            end
            
            % Store a function handle to the wake combination model
            switch wakeCombinationModel
                case 'quadraticRotorVelocity'
                    obj.wakeCombinationModel = @quadratic_rotor_velocity;
                case 'quadraticAmbientVelocity'
                    obj.wakeCombinationModel = @quadratic_ambient_velocity;
                otherwise
                    error('Wake combination model with name: "%s" is not defined', wakeCombinationModel);
            end
            
            % Store a function handle to the added turbulence model
            switch addedTurbulenceModel
                case 'crespoHernandez'
                    Turbulence = readstruct([Folder,'Turbulence/CrespoHernandez.txt']);
                    obj.addedTurbulenceModel = @crespo_hernandez;
                otherwise
                    error('Added turbulence model with name: "%s" is not defined', addedTurbulenceModel);
            end
            
            % combine everything in the modelData
            obj.modelData = append_StructFields(Deflection,Deficit,Turbulence);

        end
        
        
        function wake = create_wake(obj, turbine, turbineCondition, turbineControl, turbineResult)
            %CREATE_WAKE Pass the selected deflectionModel and
            %wakeDeficitModel to a wake object and return that wake to FLORIS
            %   Detailed explanation goes here
            wakeVelDefObj = obj.velocityDeficitModel(obj.modelData, turbine, turbineCondition, turbineControl, turbineResult);
            wakeDeflObj = obj.deflectionModel(obj.modelData, turbine, turbineCondition, turbineControl, turbineResult);
            wakeTurbulenceObj = obj.addedTurbulenceModel(obj.modelData, turbine, turbineCondition, turbineControl, turbineResult);
            
            % Pass all the created functions to the wake struct
            wake.deficit_integral = @wakeVelDefObj.deficit_integral;
            wake.deficit = @(x, y, z) wakeVelDefObj.deficit(x, y, z);
            wake.boundary = @(x, y, z) wakeVelDefObj.boundary(x, y, z);
            wake.deflection = @(x) wakeDeflObj.deflection(x);
            wake.added_TI = @(x, ti0) wakeTurbulenceObj.added_TI(x);
        end
    end
    
end

