This folder contains functions to tune the FLORIS model parameters to LES data.
The following steps should be followed:

0. First, post-process your SOWFA data in order to obtain .vtk files of
the time-averaged flow field slices. If you only have sliceDataInstantaneous
files, you can use the functions from '0_vtkPostprocessing' to time-average
these. There is a 'readme.txt' in that folder.

1. Convert the time-averaged .vtk files to the suitable MATLAB format using
the function in '1_vtkToMATLAB'. The function should be self-explanatory. The
resulting MATLAB file will contain the time-averaged flow field slices, and
a set of sampling points that will be used to minimize the error between FLORIS
and the wind speed at these sampling points (in step 2).

2. You can now use the resulting .mat files from step 1 to fit model parameters
from SOWFA to the LES data. Please use the function in '2_modelCalibration' for
this purpose. The function should be self-explanatory, but make sure to double-
check everything as it requires quite some manual labor (setting up the layout,
specifying the right control settings for each case, the right ambient
conditions, etcetera). 
For large datasets, it is suggested to submit this function as a parallel MATLAB
job on a cluster. A template job file is attached for the TU Delft high performance
computing facility.

3. Finally, you can validate the optimized model parameters with the function in
'3_modelValidation'. Note that you should have a separate (set of) simulation(s)
that have not been used for model tuning. You should post-process this validation
dataset using the functions described in steps 0 and 1. Then, this validation
dataset can be used to compare the actual performance.


Note that example files for the InnWind 10MW turbine are attached (as download
URLs). This turbine has been tuned as part of the European CL-Windcon project.
This project has received funding from the European Union's Horizon 2020
research and innovation programme under grant agreement No 727477.


Bart Doekemeijer
February 14, 2019
Delft University of Technology