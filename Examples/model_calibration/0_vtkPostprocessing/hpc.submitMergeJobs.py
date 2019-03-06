#!/usr/bin/python

from subprocess import call
import os

sourceFolder = '/marconi/home/userexternal/bdoekeme/averagedVTKs'
sourceFile = 'mergeVTKs_single.py'
jobSourceFile = 'hpc.jobVTK.PRACE'

def replaceLineInFile(filePath,strToReplace,string):	
	# Replace <string> in file
	with open(filePath) as f:
		newText=f.read().replace(strToReplace, string)
	with open(filePath, "w") as f:
		f.write(newText)

# Setup cases and submit jobs
for yaw1 in [220,230,240,250,260,270]:
    for yaw2 in [210,220,230,240,250,260,270]:
        destinationFolder = '/marconi_scratch/userexternal/bdoekeme/sediniCases/neutral_runs/runs/sdn_yaw'+str(yaw1)+'_yaw'+str(yaw2)+'/postProcessing'
        call("cp " + sourceFolder + os.sep + sourceFile    + " " + destinationFolder + '/.', shell=True)
        call("cp " + sourceFolder + os.sep + jobSourceFile + " " + destinationFolder + '/.', shell=True)
        
        replaceLineInFile(destinationFolder+os.sep+sourceFile,'<yaw1>', str(yaw1)) # Yaw 1
        replaceLineInFile(destinationFolder+os.sep+sourceFile,'<yaw2>', str(yaw2)) # Yaw 2
        replaceLineInFile(destinationFolder+os.sep+jobSourceFile,'<templ_job_name>', 'VTK.py_yaw'+str(yaw1)+'yaw'+str(yaw2)) # Job
        call("cd " + destinationFolder + " && sbatch "+jobSourceFile, shell=True)