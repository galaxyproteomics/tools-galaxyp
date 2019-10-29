# 
# Developed by Praveen Kumar
# Galaxy-P Team (Griffin's Lab)
# University of Minnesota
#
#
#


from pyteomics import mzml
import os
import sys
import shutil
import subprocess
import re
import pandas as pd
from operator import itemgetter
from itertools import groupby
import random
import argparse

def main():
    if len(sys.argv) >= 7:
        parser = argparse.ArgumentParser()
        parser.add_argument("msms", help="mzML File")
        parser.add_argument("psm", help="PSM Report File")
        parser.add_argument("out", help="Output filename")
        parser.add_argument("filestring", help="MSMS File string as identifier")
        parser.add_argument("remove_retain", help="Remove scans reported in the PSM report")
        parser.add_argument("random", help="Random MSMS scans used with to use with --retain (default=0)", default=0)
        args = parser.parse_args()
        # Start of Reading Scans from PSM file
        # Creating dictionary of PSM file: key = filename key = list of scan numbers
        
        # removeORretain = sys.argv[5].strip()
        # randomScans = int(sys.argv[6].strip())
        
        removeORretain = args.remove_retain
        randomScans = int(args.random)
        
        
        # ScanFile = sys.argv[2]
        ScanFile = args.psm
        spectrumTitleList = list(pd.read_csv(ScanFile, "\t")['Spectrum Title'])
        scanFileNumber = [[".".join(each.split(".")[:-3]), int(each.split(".")[-2:-1][0])] for each in spectrumTitleList]
        scanDict = {}
        for each in scanFileNumber:
            if each[0] in scanDict.keys():
                scanDict[each[0]].append(int(each[1]))
            else:
                scanDict[each[0]] = [int(each[1])]
        # End of Reading Scans from PSM file
        
        # inputPath = sys.argv[1]
        inputPath = args.msms
        ##outPath = "/".join(sys.argv[3].split("/")[:-1])
        # outPath = sys.argv[3]
        outPath = args.out
        ##outFile = sys.argv[3].split("/")[-1]
        allScanList = []
        # Read all scan numbers using indexedmzML/indexList/index/offset tags
        for k in mzml.read(inputPath).iterfind('indexedmzML/indexList/index/offset'):
            if re.search("scan=(\d+)", k['idRef']):
                a = re.search("scan=(\d+)", k['idRef'])
                allScanList.append(int(a.group(1)))
        allScanList = list(set(allScanList))
        # End of Reading mzML file
        # fraction_name = sys.argv[4]
        fraction_name = args.filestring
        if fraction_name in scanDict.keys():
            scansInList = scanDict[fraction_name]
        else:
            scansInList = []
        scansNotInList = list(set(allScanList) - set(scansInList))
        flag = 0
        if removeORretain == "remove":
            scan2retain = scansNotInList
            scan2retain = list(set(scan2retain))
            scan2retain.sort()
            scansRemoved = scansInList
            # scan2retain contains scans that is to be retained
        elif removeORretain == "retain" and randomScans < len(scansNotInList):
            # Randomly select spectra
            random_scans = random.sample(scansNotInList, randomScans)
            
            scan2retain = random_scans + scansInList
            scan2retain = list(set(scan2retain))
            scan2retain.sort()
            scansRemoved = list(set(allScanList) - set(scan2retain))
            # scan2retain contains scans that is to be retained
        else:
            flag = 1
            
        if flag == 1:
            scan2retain = scansInList
            scan2retain = list(set(scan2retain))
            scan2retain.sort()
            scansRemoved = list(set(allScanList) - set(scan2retain))
            
            # scan2retain contains scans that is to be retained
            print("ERROR: Number of Random Scans queried is more than available. The result has provided zero random scans.", file=sys.stdout)
            print("Number of available scans for random selection: " + str(len(scansNotInList)), file=sys.stdout)
            print("Try a number less than the available number. Thanks!!", file=sys.stdout)
            print("Number of Scans retained: " + str(len(scan2retain)), file=sys.stdout)
        else:
            # Print Stats
            print("Total number of Scan Numbers: " + str(len(list(set(allScanList)))), file=sys.stdout)
            print("Number of Scans retained: " + str(len(scan2retain)), file=sys.stdout)
            print("Number of Scans removed: " + str(len(scansRemoved)), file=sys.stdout)
            
        
        # Identifying groups of continuous numbers in the scan2retain and creating scanString
        scanString = ""
        for a, b in groupby(enumerate(scan2retain), lambda x:x[1]-x[0]):
            x = list(map(itemgetter(1), b))
            scanString = scanString + "["+str(x[0])+","+str(x[-1])+"] "
        # end identifying
        # start create filter file
        filter_file = open("filter.txt", "w")
        filter_file.write("filter=scanNumber %s\n" % scanString)
        filter_file.close()
        # end create filter file 
    
        # Prepare command for msconvert
        inputFile = fraction_name+".mzML"
        os.symlink(inputPath,inputFile)
        outFile = "filtered_"+fraction_name+".mzML"
        # msconvert_command = "msconvert " + inputFile + " --filter " + "\"scanNumber " + scanString + " \" " + " --outfile " + outFile + " --mzML --zlib"
        msconvert_command = "msconvert " + inputFile + " -c filter.txt " + " --outfile " + outFile + " --mzML --zlib"
        
        
        # Run msconvert
        try:
            subprocess.check_output(msconvert_command, stderr=subprocess.STDOUT, shell=True)
        except subprocess.CalledProcessError as e:
            sys.stderr.write( "msconvert resulted in error: %s: %s" % ( e.returncode, e.output ))
            sys.exit(e.returncode)
        # Copy output to 
        shutil.copyfile(outFile, outPath)
    else:
        print("Please contact the admin. Number of inputs are not sufficient to run the program.\n")

if __name__ == "__main__":
    main()
    
    
    
    
