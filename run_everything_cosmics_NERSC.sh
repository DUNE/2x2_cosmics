#!/usr/bin/env bash
INPUTDIR="/global/u1/s/sfogarty/2x2_cosmics_2/2x2_cosmics"
OUTDIR="/global/cfs/cdirs/dune/users/sfogarty/cosmics/2x2"
GEOMETRY=Merged2x2MINERvA_v3_withRock
#GEOMETRY=Module0

FIRST=$1
NSHOW=$2
DET=$3
TEST=$4

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

RUNNO=$((${PROCESS}+${FIRST}))
SEED=$((1000000*${PROCESS}+${RUNNO}))
RANDOM=$SEED
RNDSEED=$RANDOM
RNDSEED2=$RANDOM
echo "Random seeds are $SEED -> $RNDSEED $RNDSEED2"

RDIR=$((${RUNNO} / 1000))
if [ ${RUNNO} -lt 10000 ]; then
RDIR=0$((${RUNNO} / 1000))
fi
TIME_START=`date +%s`
echo "Setting to CORSIKA-friendly container."
shifter --image=fermilab/fnal-wn-sl7:latest --module=cvmfs -- /bin/bash << EOF1
set -e
echo 'Setting up software'
set +e
source /cvmfs/mu2e.opensciencegrid.org/setupmu2e-art.sh
source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh
setup edepsim v3_0_1 -q e19:prof
setup corsika
set -e
cp ${INPUTDIR}/run_CORSIKA.sh run_CORSIKA.sh
chmod +x run_CORSIKA.sh
cp ${INPUTDIR}/run_edep-sim.sh run_edep-sim.sh
cp ${INPUTDIR}/convert_edepsim_roottoh5.py convert_edepsim_roottoh5.py
cp ${INPUTDIR}/requirements.txt requirements.txt
cp ${INPUTDIR}/${GEOMETRY}.gdml ${GEOMETRY}.gdml
echo 'Using geometry: ${GEOMETRY}.gdml'
rm -f DAT000001
./run_CORSIKA.sh $RDIR $NSHOW $DET $RNDSEED $RNDSEED2 $INPUTDIR $OUTDIR
EOF1
TIME_CORSIKA=`date +%s`
TIME_A=$((${TIME_CORSIKA}-${TIME_START}))

echo "Setting GENIE_edep-sim container."
shifter --image=mjkramer/sim2x2:genie_edep.3_04_00.20230620 --module=cvmfs -- /bin/bash << EOF2
set +o posix
source /environment
chmod +x run_edep-sim.sh
rm -rf convert.venv
python3 -m venv convert.venv
source convert.venv/bin/activate
pip3 install -r requirements.txt
./run_edep-sim.sh ${GEOMETRY} ${RNDSEED} $INPUTDIR $OUTDIR
EOF2
TIME_EDEP=`date +%s`
TIME_B=$((${TIME_EDEP}-${TIME_CORSIKA}))

TIME_STOP=`date +%s`
TIME_TOTAL=$((${TIME_STOP}-${TIME_START}))
echo "Time to run CORSIKA and corsikaConverter = ${TIME_A} seconds"
echo "Time to run edep-sim and h5 converter = ${TIME_B} seconds"
echo "Total time elapsed = ${TIME_TOTAL} seconds"