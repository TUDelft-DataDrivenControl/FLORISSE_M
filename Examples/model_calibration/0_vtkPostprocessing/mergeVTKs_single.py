# -*- coding: utf-8 -*-
"""
Created on Thu Feb 07 11:54:54 2019

@author: bmdoekemeijer
"""
import numpy as np
import time
import os
import sys
sys.path.insert(0, 'bin')
from mergeVTKs import averageCellDataSliceDataInst
    
# Read all files
averaging_lb = 10400; # Lower limit
averaging_ub = np.Inf; # Upper limit
folderName = 'sdn_yaw<yaw1>_yaw<yaw2>'
sliceDataInstDir = '/marconi_scratch/userexternal/bdoekeme/sediniCases/neutral_runs/runs/' + folderName + '/postProcessing/sliceDataInstantaneous'
averageCellDataSliceDataInst(sliceDataInstDir,averaging_lb,averaging_ub)