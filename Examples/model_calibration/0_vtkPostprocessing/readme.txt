This folder contains functions to time-average instantaneous VTK slices from SOWFA simulations. It is used as follows:

1a. Time-averaging VTK files serially:
Adapt mergeVTKs_serial.py to fit your specific case setup and folder structure. Use this function to 
time-average all the VTKs in the specified folders within the specified time range. This is relatively
slow and therefore it is recommended to use a parallelized approach instead. See '1b'.

1b. Time-averaging VTK files in parallel:
Adapt mergeVTKs_single.py to fit your specific case setup and folder structure. Specifically, create
text placeholders such as <yaw1> and <yaw2> which are substituted automatically later to cover all
your respective cases. 
Now, use the script 'hpc.submitMergeJobs.py' to make a copy of mergeVTKs_single.py for each case,
with the text placeholders (e.g., <yaw1>) substituted with the value specific to that case/folder.
Note that jobs can automatically be submitted to the HPC using the 'hpc.jobVTK.PRACE' job file.
You will have to adapt this job script to your HPC.

2. Renaming and moving VTKs:
Finally, rename and move the VTK files using the moveVTKs.py function. Do this serially.


B M Doekemeijer
February 14, 2019
Delft University of Technology