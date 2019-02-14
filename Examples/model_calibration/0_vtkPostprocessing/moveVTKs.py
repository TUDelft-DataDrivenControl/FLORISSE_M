# -*- coding: utf-8 -*-
"""
Created on Thu Feb 07 11:54:54 2019

@author: bmdoekemeijer
"""
import time
import os
import subprocess as sp

# Simple example code...
outputDir = '/marconi/home/userexternal/bdoekeme/averagedVTKs'
mainDir = '/marconi_scratch/userexternal/bdoekeme/sediniCases/neutral_runs/runs'
for yaw1 in [220,230,240,250,260,270]:
    for yaw2 in [210,230,240,250,260,270]:
        folderName = mainDir + os.sep + 'sdn_yaw' + str(yaw1) + '_yaw' + str(yaw2)
        postprocDir = folderName + os.sep + 'postProcessing'
        
        for tmpFilenameIn in os.listdir(postprocDir):
            if tmpFilenameIn.endswith('.vtk'):
                print('Moving file: sdn_yaw' + str(yaw1) + '_yaw' + str(yaw2)+os.sep+tmpFilenameIn)
                tmpFilenameOut = outputDir + os.sep + 'yaw' + str(yaw1) + 'yaw' + str(yaw2) + tmpFilenameIn
                tmpFilenameInFull = postprocDir + os.sep + tmpFilenameIn
                sp.call('mv ' + tmpFilenameInFull + ' ' + tmpFilenameOut,shell=True)