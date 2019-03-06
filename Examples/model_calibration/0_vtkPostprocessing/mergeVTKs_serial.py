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
mainDir = '/marconi_scratch/userexternal/bdoekeme/sediniCases/neutral_runs/runs'
averaging_lb = 10400; # Lower limit
averaging_ub = np.Inf; # Upper limit
    
caseFolders = os.listdir('/marconi_scratch/userexternal/bdoekeme/sediniCases/neutral_runs/runs')
for caseFolder in caseFolders:
    sliceDataInstDir = mainDir + os.sep + caseFolder + os.sep + 'postProcessing' + os.sep + 'sliceDataInstantaneous'
    averageCellDataSliceDataInst(sliceDataInstDir,averaging_lb,averaging_ub)
