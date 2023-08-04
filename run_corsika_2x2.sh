#/usr/bin/env bash
# Run CORSIKA for 2x2
#
# Example usage:
# 
#     jobsub_submit --group dune --role=Analysis -N 10 --OS=SL7 \
#                   --expected-lifetime=12h --memory=2000MB file://run_corsika.sh FIRST NSHOW TEST
#
# where FIRST is the first run number you want (work in increments of 1000),
# NSHOW is the number of showers (where 2000000 -> ~1000 events), and TEST
# enables test mode for interactive tests (sets $PROCESS to 0).
#
# Based on the run_everything.sh in DUNE/ND_CAFMaker, by C. Marshall.
#
# A. Mastbaum <mastbaum@physics.rutgers.edu>, April 2021

set -e
OUTDIR="/pnfs/dune/persistent/users/sfogarty/cosmics/2x2/"
USERNAME=$USER

FIRST=$1
NSHOW=$2
TEST=$3

if [ "${NSHOW}" = "" ]; then
NSHOW=2000000
echo "NSHOW not specified, using $NSHOW"
fi

if [ "${FIRST}" = "" ]; then
echo "First run number not specified, using 0"
FIRST=0
fi

if [ "${TEST}" = "test" ]; then
echo "Test mode"
PROCESS=0
mkdir -p test
cd test
fi

TIME_START=`date +%s`
CP="ifdh cp"
RUNNO=$((${PROCESS}+${FIRST}))

# Two seeded RNG seeds
SEED=$((1000000*${PROCESS}+${RUNNO}))
RANDOM=$SEED
RNDSEED=$RANDOM
RNDSEED2=$RANDOM
echo "Random seeds are $SEED -> $RNDSEED $RNDSEED2"

gen_corsika_config() {
cat << EOF > corsika.cfg
RUNNR   1                              run number
EVTNR   1                              number of first shower event
NSHOW   ${NSHOW}                        number of showers to generate
PRMPAR  14                             particle type of prim. particle  (14=p)
ESLOPE  -2.7                           slope of primary energy spectrum
ERANGE  1.3 100000                    energy range of primary (GeV)
THETAP  0.  84.9                        range of zenith angle (degree)
PHIP    -180.  180.                    range of azimuth angle (degree)
SEED    ${RNDSEED}   0  0                 seed for 1. random number sequence
SEED    ${RNDSEED2}   0  0                 seed for 2. random number sequence
QGSJET  T   0                              QGSJET for high energy & debug level
QGSSIG  T                                    QGSJET cross-sections enable
OBSLEV  119E2                          observation level for MINOS hall (in cm)
CURVOUT F
MAGNET  19.310  49.433                 Earth's mag. field at detector- Bx & Bz
HADFLG  0  0  0  0  0  2               flags hadr.interact.&fragmentation
ECUTS   0.05 0.05 0.05 0.05            energy cuts for particles
MUADDI  F                              additional info for muons
MUMULT  T                              muon multiple scattering angle
ELMFLG  F   T                          em. interaction flags (NKG,EGS)
STEPFC  1.0                            mult. scattering step length fact.
RADNKG  200.E2                         outer radius for NKG lat.dens.distr.
ARRANG  0                              rotation of array to north
ATMOD   1                                    U.S. standard atmosphere (1-Linsley; 22-Keilhauer)
LONGI   F  20.  F  F                   longit.distr. & step size & fit & out
ECTMAP  1.E2                           cut on gamma factor for printout
MAXPRT  0                            max. number of printed events
DIRECT  ${PWD}/                             output directory
DATDIR  /cvmfs/mu2e.opensciencegrid.org/artexternals/corsika/v77400/Linux64bit+3.10-2.17/run                      CORSIKA directory
DATBAS  F                              write .dbase file
USER    ${USERNAME}                         user
DEBUG   F  6  F  1000000               debug flag and log.unit for out
EXIT                                   terminates input
EOF
}

# ifdhc doen't have a mkdir -p equivalent, which is fine 
# as long as you always remember to include this convenient function in your scripts
ifdh_mkdir_p() {
    local dir=$1
    local force=$2
    if [ `ifdh ls $dir 0 $force | wc -l` -gt 0 ] 
    then
        : # we're done
    else
        ifdh_mkdir_p `dirname $dir` $force
        ifdh mkdir $dir $force
    fi
}

RDIR=$((${RUNNO} / 1000))
if [ ${RUNNO} -lt 10000 ]; then
RDIR=0$((${RUNNO} / 1000))
fi

# Don't try over and over again to copy a file when it isn't going to work
export IFDH_CP_UNLINK_ON_ERROR=1
export IFDH_CP_MAXRETRIES=1
export IFDH_DEBUG=0

##################################################

# Setup UPS and required products
echo "Setting up software"
set +e
source /cvmfs/mu2e.opensciencegrid.org/setupmu2e-art.sh
source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh
setup ifdhc
setup edepsim v3_0_1 -q e19:prof
setup corsika  # Thanks mu2e and Roberto!
set -e

# edep-sim needs to know where a certain GEANT .cmake file is...
G4_cmake_file=`find ${GEANT4_FQ_DIR}/lib64 -name 'Geant4Config.cmake'`
export Geant4_DIR=`dirname $G4_cmake_file`

# edep-sim needs to have the GEANT bin directory in the path
export PATH=$PATH:$GEANT4_FQ_DIR/bin

##################################################

# Get the binaries & other files that are needed
#${CP} ${INPUTDIR}/corsikaConverter corsikaConverter
chmod +x corsikaConverter

#${CP} ${INPUTDIR}/Merged2x2MINERvA_v2_withRock.gdml Merged2x2MINERvA_v2_withRock.gdml

##################################################

# Run CORSIKA
echo "Running corsika"

TIME_CORSIKA=`date +%s`

gen_corsika_config

corsika77400Linux_QGSJET_fluka < corsika.cfg

CORSIKA_FILE="corsika.${RNDSEED}.dat"

##################################################

# Convert the CORSIKA output to RooTracker

export LD_LIBRARY_PATH=${PWD}/edep-sim/edep-gcc-6.4.0-x86_64-pc-linux-gnu/lib:${LD_LIBRARY_PATH}
export PATH=${PWD}/edep-sim/edep-gcc-6.4.0-x86_64-pc-linux-gnu/bin:${PATH}

echo "Running corsika2RooTracker"

TIME_ROOTRACKER=`date +%s`

./corsikaConverter DAT000001

ROOTRACKER_FILE="rootracker.${RNDSEED}.root"
mv DAT000001.root ${OUTDIR}/${ROOTRACKER_FILE}
rm DAT000001
