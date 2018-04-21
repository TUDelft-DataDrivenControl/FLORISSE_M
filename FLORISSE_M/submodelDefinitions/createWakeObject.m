classdef createWakeObject<handle
    properties
        modelData
    end
    methods
        % Load model parameter settings
        function self = createWakeObject(deflectionModel,deficitModel,...
                                         sumModel,wakeTurbulenceModel,...
                                         modelDataFile)

            % Load model parameters
            modelDataFileHandle = str2func(modelDataFile);
            self.modelData      = modelDataFileHandle();
            
            % Set model choices
            self.modelData.deflectionModel = deflectionModel;
            self.modelData.deficitModel    = deficitModel;
            self.modelData.sumModel        = sumModel;
            self.modelData.turbulenceModel = wakeTurbulenceModel;
            
        end
        
        % Setup the wake displacement submodel
        function [displ_y,displ_z] = deflection(self,deltaxs,turbine)
            [displ_y,displ_z] = wakeDeflectionModels(self.modelData,...
                                                     deltaxs,...
                                                     turbine);
        end
        
        % Setup the wake deficit submodel
        function [wake] = deficit(self,turbine,wake)            
            [wake] = wakeVelocityModels(self.modelData,...
                                        turbine,...
                                        wake);
        end
        
        % Setup the wake sum submodel
        function [Ked] = sum(self,U_inf,U_uw,Vni)            
            [Ked] = wakeSumModels(self.modelData.sumModel,...
                                  U_inf,U_uw,Vni);
        end
  
        % Setup the wake turbine-added turbulence submodel
        function [TI_out] = turbul(self,TI_0,turbineDw,turbineUw,wakeUw,turbLocIndex,deltax)          
            [TI_out] = wakeTurbulenceModels(self.modelData,TI_0,turbineDw,...
                                            turbineUw,wakeUw,turbLocIndex,deltax);
        end
        
        
        % Volumetric flow rate calculation (necessity for wake deficit model)
        function [Q] = volFlowRate(self,uw_wake,dw_turbine,uw_turbine,U_inf,deltax,turbLocIndex)
            % Q is the volumetric flowrate relative divided by freestream velocity
            Q = flowRateIntegrals(self.modelData,...
                                  uw_wake,...
                                  dw_turbine,...
                                  uw_turbine,...
                                  U_inf,...
                                  deltax,...
                                  turbLocIndex);
        end
    end
end