#!/usr/bin/env bash
# Run CORSIKA

USERNAME=$USER

RDIR=$1
NSHOW=$2
DET=$3
RNDSEED=$4
RNDSEED2=$5
INPUTDIR=$6
OUTDIR=$7

if [ "${DET}" == "0" ]; then
# Bern (single module tests)
DETNAME=BERN
OBSLEV=550E2
Bx=21.793
Bz=42.701
elif [ "${DET}" == "1" ]; then 
# MINOS Hall (2x2)
DETNAME=MINOS_HALL
OBSLEV=119E2
Bx=19.310
Bz=49.433
else
DETNAME=MINOS_HALL
OBSLEV=119E2
Bx=19.310
Bz=49.433
fi

echo "Using observation level of ${OBSLEV} cm and magnetic field values of Bx = ${Bx} and Bz = ${Bz} microteslas, corresponding to ${DETNAME}."

TIME_START=`date +%s`

# edep-sim needs to know where a certain GEANT .cmake file is...
G4_cmake_file=`find ${GEANT4_FQ_DIR}/lib64 -name 'Geant4Config.cmake'`
export Geant4_DIR=`dirname $G4_cmake_file`

# edep-sim needs to have the GEANT bin directory in the path
export PATH=$PATH:$GEANT4_FQ_DIR/bin

##################################################

# Run CORSIKA
echo "Running corsika"

TIME_CORSIKA=`date +%s`

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
OBSLEV  ${OBSLEV}                         observation level in cm
CURVOUT F
MAGNET  ${Bx} ${Bz}                 Earth's mag. field at detector- Bx & Bz
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
gen_corsika_config

corsika77400Linux_QGSJET_fluka < corsika.cfg

CORSIKA_FILE="corsika.${RNDSEED}.dat"
mkdir -p ${OUTDIR}/corsika/${RDIR}
cp DAT000001 ${OUTDIR}/corsika/${RDIR}/${CORSIKA_FILE}

#### run corsika to rootracker converter
# Get the binaries & other files that are needed
cp ${INPUTDIR}/corsikaConverter corsikaConverter
chmod +x corsikaConverter

export LD_LIBRARY_PATH=${PWD}/edep-sim/edep-gcc-6.4.0-x86_64-pc-linux-gnu/lib:${LD_LIBRARY_PATH}
export PATH=${PWD}/edep-sim/edep-gcc-6.4.0-x86_64-pc-linux-gnu/bin:${PATH}

echo "Running corsika2RooTracker"

./corsikaConverter DAT000001

ROOTRACKER_FILE="rootracker.${RNDSEED}.root"
mv DAT000001.root ${ROOTRACKER_FILE}

cat << EOF > macro.mac
/generator/kinematics/set rooTracker
/generator/kinematics/rooTracker/input ${ROOTRACKER_FILE}
/generator/position/set free
/generator/time/set fixed
/generator/count/fixed/number 1
/generator/count/set fixed
/generator/add
EOF

mkdir -p ${OUTDIR}/rootracker/${RDIR}
mkdir -p ${OUTDIR}/corsika/${RDIR}
mkdir -p ${OUTDIR}/corsika/${RDIR}
mkdir -p ${OUTDIR}/rootracker/${RDIR}
mkdir -p ${OUTDIR}/edep/${RDIR}
mkdir -p ${OUTDIR}/h5/${RDIR}

cp ${ROOTRACKER_FILE} ${OUTDIR}/rootracker/${RDIR}/${ROOTRACKER_FILE}


