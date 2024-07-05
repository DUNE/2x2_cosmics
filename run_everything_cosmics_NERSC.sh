#!/usr/bin/env bash
INPUTDIR="/global/cfs/cdirs/dune/users/ehinkle/nd_prototypes_ana/2x2_cosmics"
OUTDIR="/pscratch/sd/e/ehinkle/nd_ana/cosmics_sim/single_module"
DET=$1 # 0 for single Bern module, 1 for 2x2
NSHOW=$2 # number of showers generated

if [ "${NSHOW}" = "" ]; then
    NSHOW=2000000
    echo "NSHOW not specified, generating $NSHOW showers"
fi

# set detector and geometry
if [ "${DET}" = "0" ]; then
    DET=0
    GEOMETRY=Module0
elif [ "${DET}" = "1" ]; then
    DET=1
    GEOMETRY=Merged2x2MINERvA_v3_withRock
else
    DET=1
    GEOMETRY=Merged2x2MINERvA_v3_withRock
    echo "DET not specified, using defaults."
fi
echo "DET set to ${DET}, GEOMETRY = ${GEOMETRY}"

# make folders for data in OUTDIR if they don't exist
mkdir -p ${OUTDIR}/corsika
mkdir -p ${OUTDIR}/edep
mkdir -p ${OUTDIR}/h5
mkdir -p ${OUTDIR}/rootracker

DATE=$(date +%s)
SEED=$((${RANDOM}+${DATE}))
RNDSEED=$SEED
RNDSEED2=$SEED
echo "Random seeds are $RNDSEED, $RNDSEED2"

TIME_START=`date +%s`
echo "Setting to CORSIKA-friendly container."
shifter --image=fermilab/fnal-wn-sl7:latest --module=cvmfs -- /bin/bash << EOF1
echo 'Setting up software'
source /cvmfs/mu2e.opensciencegrid.org/setupmu2e-art.sh
source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh
setup corsika
chmod +x run_CORSIKA.sh
./run_CORSIKA.sh $NSHOW $DET $RNDSEED $RNDSEED2 $OUTDIR
EOF1
TIME_CORSIKA=`date +%s`
TIME_A=$((${TIME_CORSIKA}-${TIME_START}))

echo "Setting to 2x2 sim container for corsikaConverter."
shifter --image=mjkramer/sim2x2:ndlar011 --module=cvmfs -- /bin/bash << EOF2
set +o posix
source /opt/environment
chmod +x run_corsikaConverter.sh
./run_corsikaConverter.sh $RNDSEED $OUTDIR
EOF2
TIME_CONVERTER=`date +%s`
TIME_B=$((${TIME_CONVERTER}-${TIME_CORSIKA}))

echo "Setting to 2x2 sim container for running edep-sim."
shifter --image=mjkramer/sim2x2:ndlar011 --module=cvmfs -- /bin/bash << EOF3
set +o posix
source /opt/environment
chmod +x run_edep-sim.sh
./run_edep-sim.sh $GEOMETRY $RNDSEED $OUTDIR
EOF3
TIME_EDEP=`date +%s`
TIME_C=$((${TIME_EDEP}-${TIME_CONVERTER}))

TIME_STOP=`date +%s`
TIME_TOTAL=$((${TIME_STOP}-${TIME_START}))
echo "Time to run CORSIKA = ${TIME_A} seconds"
echo "Time to run corsikaConverter = ${TIME_B} seconds"
echo "Time to run edep-sim and h5 converter = ${TIME_C} seconds"
echo "Total time elapsed = ${TIME_TOTAL} seconds"
