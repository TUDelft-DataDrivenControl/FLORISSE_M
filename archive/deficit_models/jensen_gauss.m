inputData.adjustInitialWakeDiamToYaw = false; % Adjust the intial swept surface overlap

inputData.Ke            = 0.05; % wake expansion parameters
inputData.KeCorrCT      = 0.0; % CT-correction factor
inputData.baselineCT    = 4.0*(1.0/3.0)*(1.0-(1.0/3.0)); % Baseline CT for ke-correction