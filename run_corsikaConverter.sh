#!/usr/bin/env bash
# Run corsikaConverter

USERNAME=$USER

RNDSEED=$1
RUNNUMBER="${RNDSEED: -5}"
OUTDIR=$2

#### run corsika to rootracker converter
#rm -rf corsikaConverter
#cd corsika2RooTracker
#make
#mv corsikaConverter ..
#cd ..

chmod +x corsikaConverter

export CPATH=$EDEPSIM/include/EDepSim:$CPATH
export ARCUBE_ACTIVE_VOLUME=volTPCActive

echo "Running corsika2RooTracker"
./corsikaConverter DAT0${RUNNUMBER}

ROOTRACKER_FILE="rootracker.${RNDSEED}.root"
mv DAT0${RUNNUMBER}.root ${ROOTRACKER_FILE}

cat << EOF > macro_${RNDSEED}.mac
# This ensures that each hit segment in the LAr is only associated with one
# trajectory. It must be run BEFORE /edep/update.
# https://github.com/DUNE/2x2_sim/issues/20
/edep/hitSeparation volTPCActive -1 mm

/edep/update
/generator/kinematics/set rooTracker
/generator/kinematics/rooTracker/input ${OUTDIR}/rootracker/${ROOTRACKER_FILE}
/generator/position/set free
/generator/time/set fixed
/generator/count/fixed/number 1
/generator/count/set fixed
/generator/add
EOF

cp ${ROOTRACKER_FILE} ${OUTDIR}/rootracker/${ROOTRACKER_FILE}
rm DAT0${RUNNUMBER}