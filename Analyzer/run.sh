#/bin/bash
#
# This is the main script to run cmsRun jobs, both for data and MC
# First configuration part comes (set 'INPUTLIST', 'OUTPUTDIR', 
# 'reco', 'gen', 'mc', 'NP', 'outrootsuffix'), then call to cmsRun, 
# which process analyzer_cfg.py file (find there further description 
# if needed). To run this script, execute the command:
# ./run.sh. You need to run this script once per each data and MC sample 
# (see below INPUTLIST variable).
#
# You may run this script in the terminal and close the terminal, 
# the jobs will keep working (nohup). If you need to kill all running 
# jobs, execute the command 'killall -9 cmsRun'. To monitor running 
# jobs you could use './running.sh <dir>' and './processed.sh <dir>', 
# where <dir> is the output directory.
#
#
# optionally run using parameters provided from command line
if [ 1 -eq 2 ]; then
  if [ -z $1 ]; then
    echo "Usage ./run.sh <sample>"
    exit 1
  fi
  runSample=$1 # 1 data mu, 2 data el, 3 MC
  if [ ${runSample} -eq 1 ]; then
    # 91006026 events
    INPUTLIST='data/CMS_Run2011A_SingleMu_AOD_12Oct2013-v1-all_file_index.txt'
    OUTPUTDIR='ntuples-data/SingleMu'
    jobName='wc-mu-'
    reco=1
    gen=0
    mc=0
    NP=200
  elif [ ${runSample} -eq 2 ]; then
    # 41709195 events
    INPUTLIST='data/CMS_Run2011A_SingleElectron_AOD_12Oct2013-v1-all_file_index.txt'
    OUTPUTDIR='ntuples-data/SingleElectron'
    jobName='wc-el-'
    reco=1
    gen=0
    mc=0
    NP=100
  elif [ ${runSample} -eq 3 ]; then
    # 78347691 events
    #INPUTLIST='mc/CMS_MonteCarlo2011_Summer11LegDR_W1Jet_TuneZ2_7TeV-madgraph-tauola_AODSIM_PU_S13_START53_LV6-v1-all_file_index.txt'
    #OUTPUTDIR='ntuples-mc/W1Jet_TuneZ2_7TeV-madgraph-tauola'
    # 78347691
    INPUTLIST='mc/CMS_MonteCarlo2011_Summer11LegDR_WJetsToLNu_TuneZ2_7TeV-madgraph-tauola_AODSIM_PU_S13_START53_LV6-v1_all_file_index.txt'
    OUTPUTDIR='ntuples-mc/WJetsToLNu_TuneZ2_7TeV-madgraph-tauola'
    jobName='wc-mc-'
    reco=1
    gen=1
    mc=1
    NP=500
  fi
fi
#INPUTLIST='data/test.txt'
########################################################################
########################## Input lists #################################
########################################################################
#
# Uncomment one 'INPUTLIST' and the corresponding 'OUTPUTDIR'
# (by default data SingleMu sample is uncommented). 
# For Monte Carlo (MC) set mc = 1 below, for signal MC also set gen = 1
#
INPUTLIST='data/CMS_Run2011A_SingleMu_AOD_12Oct2013-v1-all_file_index.txt'
#INPUTLIST='data/CMS_Run2011A_SingleElectron_AOD_12Oct2013-v1-all_file_index.txt'
#
# MC ('W + c' signal and 'W + jets other' background) - most time consuming!
#INPUTLIST='mc/CMS_MonteCarlo2011_Summer11LegDR_WJetsToLNu_TuneZ2_7TeV-madgraph-tauola_AODSIM_PU_S13_START53_LV6-v1-all_file_index.txt'
#
########################################################################

########################################################################
########################## Output directory ############################
########################################################################
#
# Uncomment one 'OUTPUTDIR' based on the the corresponding 'INPUTLIST'
# (this is just a name: it could be any, but makes sence to use consistent one)
# (by default the directory for data SingleMu sample is uncommented). 
# The produced output ROOT files in this directory have to be 
# processed by PostAnalyzer after all (see PostAnalyzer/README.txt).
#
# Data
OUTPUTDIR='ntuples-data/SingleMu'
#OUTPUTDIR='ntuples-data/SingleElectron'
#
# MC ('W + c' signal and 'W + jets other' background)
#OUTPUTDIR='ntuples-mc/WJetsToLNu_TuneZ2_7TeV-madgraph-tauola'
#
########################################################################

########################################################################
########################## Flags #######################################
########################################################################
#
# Process reconstruction level (normally always should be done, 
# unless you want some pure generator level MC study)
reco=1 
# Process generator level (should be done for signal MC to store 
# "true" information for detector efficiency corrections,
# not needed for background MC)
gen=0
# For MC set to 1
mc=0
########################################################################

########################################################################
#################### Parallel jobs settings ############################
########################################################################
#
# Very important part! Proper setting here might make your analysis ~ 10 times faster.
# It will definitely require some exercises to find optimal number jobs for your machine. 
# The default setting NP = 1 is the most simple and will always work, 
# although performance-wise it is most likely least optimal.
# The basic feature is that the data server responce is latent 
# (typically data are read in portions of a few MB each 1..100 seconds), 
# this can be overcome by running many parallel jobs.
# Things to consider when finding the optimal number of jobs:
#  1) each parallel job eats about 250MB..1GB memory (depending on data or MC sample, how long is running etc.)
#  2) on Intel Core i5-5300U (2.3GHz) one processor core becomes ~100% busy with ~5 jobs
#  3) depends heavily on the network access (with slow network you will not win much with many parallel jobs)
#  4) timing results can be quite stochastic
# Splitting of input files between parallel jobs is done automatically
# (there will be NP root and log files in the output directory).
#
NP=1
outrootsuffix='' # optional suffix for output root file names (can be a subdirectory, for instance)
#
########################################################################

########################################################################
#################### Call cmsRun analyzer_cfg.py #######################
########################################################################
#
# This part just makes some checks, prepares arguments and passes them 
# to analyzer_cfg.py (settings chosen above): normally you do not need 
# to change anything here
#
if [ ! -f $INPUTLIST ]
then
  echo "Error: no input file $INPUTLIST"
  exit 1
fi
if [ -d $OUTPUTDIR ]
then
  echo "Error: output directory $OUTPUTDIR exists"
  exit 1
else
  mkdir -p $OUTPUTDIR
  p=0
  for inputFile in `cat $INPUTLIST`
  do
    p=$[$p+1]
    echo $inputFile >> "$OUTPUTDIR/inputList"${outrootsuffix}"_$p.txt"
    if [ $p == $NP ]; then p=0; fi
  done
fi
# call cmsRun analyzer_cfg.py for each parallel job
for p in `seq 1 $NP`
do
  command="time cmsRun analyzer_cfg.py ${OUTPUTDIR}/inputList${outrootsuffix}_${p}.txt ${OUTPUTDIR}/wcharmSel${outrootsuffix}_${p}.root ${reco} ${gen} ${mc}"
  nohup ${command} >& ${OUTPUTDIR}/log${outrootsuffix}_${p}.txt&
#
# optionally submit jobs to cluster (if running not on VM): modify for your environment
#
#  submit -N cmsRun-${p} -q default.q -l h_vmem=1.9G "${command} >& ${OUTPUTDIR}/log${outrootsuffix}_${p}.txt"
#  submit -N ${jobName}${p} -q short.q -l h_vmem=3.99G "${command} >& ${OUTPUTDIR}/log${outrootsuffix}_${p}.txt"
done
########################################################################

exit 0
