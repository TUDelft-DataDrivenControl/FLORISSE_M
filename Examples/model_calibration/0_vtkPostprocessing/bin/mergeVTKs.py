# -*- coding: utf-8 -*-
"""
Created on Thu Feb 07 11:54:54 2019

@author: bmdoekemeijer
"""
import numpy as np
import time
import os

# Reading VTK file function
def readCellData(vtkFile):
    startTime = time.time() # Timer
    # Determine cellData (u,v,w)
    print("Loading file: ", vtkFile)
    with open(vtkFile) as fdata:
        importedData = list()
        foundCondition = False
        for line in fdata:
            if foundCondition:
                line = line.split("\n",1)[0] # Remove '\n'
                lineData = np.fromstring(line,dtype=float,sep=' ') # Extract numerical values
                importedData.append(lineData) # Write to variable
            elif line.strip() == 'FIELD attributes 1':
                foundCondition = True 
    importedData.pop(0) # Remove first entry
    print("The call readCellData took: ", time.time()-startTime, " seconds.")
    
    return importedData

# Reading VTK file function
def writeCellData(vtkTemplateFile,vtkDestinationFile,avgData):
    startTime = time.time() # Timer
    fdata = open(vtkTemplateFile)
    templateText = fdata.read()
    splitString = 'FIELD attributes 1\n'
    textSplit = templateText.split(splitString,1)
    textSplit2 = textSplit[1].split('\n',1)
    headerText = textSplit[0] + splitString + textSplit2[0] + '\n'
    
    cellDataText = ""
    for avgDataLine in avgData:
        cellDataText += ' '.join(map(str, avgDataLine)) + '\n'
        
    fout = open(vtkDestinationFile,'w')
    fout.write(headerText + cellDataText)
    fout.close()
    print("The call writeCellData took: ", time.time()-startTime, " seconds.")
    
    return

def averageCellDataSliceDataInst(sliceDataInstDir,averaging_lb,averaging_ub):
    folderNames=os.listdir(sliceDataInstDir) # All folders in directory
    fileNames=os.listdir(sliceDataInstDir+os.sep+folderNames[0]) # All files
    
    for iif in range(0,len(fileNames)):
        iFile = fileNames[iif] # Do per file type
        firstFile = True
        for iFolder in folderNames:
            folderTime = np.fromstring(iFolder,dtype=float,sep=' ')
            if (folderTime >= averaging_lb) & (folderTime <= averaging_ub):
                
                vtkFile = sliceDataInstDir+os.sep+iFolder+os.sep+iFile
                readVtkData = readCellData(vtkFile)
                
                if firstFile:
                    summedData = readVtkData
                    nEntries = 1
                    firstFile = False
                else:
                    startTime = time.time() # Timer
                    for i in range(len(summedData)):
                        summedData[i] += readVtkData[i]
                    print("The summedData call took: ", time.time()-startTime, " seconds.")
                    nEntries += 1
        
        # After going through all folders, average and save
        avgData = list()
        for i in range(len(summedData)):
            avgData.append(summedData[i]/nEntries)
        
        writeCellData(vtkFile,sliceDataInstDir+os.sep+'..'+os.sep+'avg'+iFile,avgData)
        
    return