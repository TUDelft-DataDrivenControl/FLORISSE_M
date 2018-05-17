classdef model_definition
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
            
            % Make an empty modelData struct
            obj.modelData = struct();
            obj.modelData = linear_wake_deflection(obj.modelData);
            % Put the relevant deflection parameters into the modelData
            % struct and store a function handle to the chosen model
            switch deflectionModel
                case 'jimenez'
                    obj.modelData = jimenez_params(obj.modelData);
                    obj.deflectionModel = @jimenez_deflection;
                case 'rans'
                    obj.modelData = self_similar_gaussian_rans_params(obj.modelData);
                    obj.deflectionModel = @rans_deficit_deflection;
                otherwise
                    error('Deflection model with name: "%s" is not defined', deflectionModel);
            end
            
            % Put the relevant velocity deficit parameters into the modelData
            % struct and store a function handle to the chosen model
            switch velocityDeficitModel
                case 'jensenGauss'
                    obj.modelData = jensen_params(obj.modelData);
                    obj.velocityDeficitModel = @jensen_gaussian_velocity;
                case 'zones'
                    obj.modelData = zoned_params(obj.modelData);
                    obj.velocityDeficitModel = @zoned_velocity;
                case 'larsen'
                    obj.velocityDeficitModel = @larsen_velocity;
                case 'selfSimilar'
                    obj.modelData = self_similar_gaussian_rans_params(obj.modelData);
                    obj.velocityDeficitModel = @self_similar_gaussian_velocity;
                otherwise
                    error('Velocity model with name: "%s" is not defined', velocityDeficitModel);
            end
            
            % Store a function handle to the wake combination model
            switch wakeCombinationModel
                case 'quadratic'
                    obj.wakeCombinationModel = @quadratic_rotor_velocity;
                otherwise
                    error('Wake combination model with name: "%s" is not defined', wakeCombinationModel);
            end
            
            % Store a function handle to the added turbulence model
            switch addedTurbulenceModel
                case 'crespoHernandez'
                    obj.modelData = crespo_hernandez_params(obj.modelData);
                    obj.addedTurbulenceModel = @crespo_hernandez;
                otherwise
                    error('Added turbulence model with name: "%s" is not defined', addedTurbulenceModel);
            end
        end
        
        function wake = create_wake(obj, turbine, turbineCondition, turbineControl, turbineResult)
            %CREATE_WAKE Pass the selected deflectionModel and
            %wakeDeficitModel to a wake object and return that wake to FLORIS
            %   Detailed explanation goes here
            wakeVelDefObj = obj.velocityDeficitModel(obj.modelData, turbine, turbineCondition, turbineControl, turbineResult);
            wakeDeflObj = obj.deflectionModel(obj.modelData, turbine, turbineCondition, turbineControl, turbineResult);
            wakeTurbulenceObj = obj.addedTurbulenceModel(obj.modelData, turbine, turbineCondition, turbineControl, turbineResult);
            
            % Pass all the created functions to the wake struct
            wake.deficit = @(x, y, z) wakeVelDefObj.deficit(x, y, z);
            wake.boundary = @(x, y, z) wakeVelDefObj.boundary(x, y, z);
            wake.deflection = @(x) wakeDeflObj.deflection(x);
            wake.added_TI = @(x, ti0) wakeTurbulenceObj.added_TI(x, ti0);
        end
    end
end

