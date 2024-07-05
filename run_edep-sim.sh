#!/usr/bin/env bash
# Run edep-sim on CORSIKA files

USERNAME=$USER
GEOMETRY=$1
RNDSEED=$2
OUTDIR=$3

ROOTRACKER_FILE="/pscratch/sd/e/ehinkle/nd_ana/cosmics_sim/single_module/rootracker/rootracker.${RNDSEED}.root"
NPER=$(echo "std::cout << gRooTracker->GetEntries() << std::endl;" | root -l -b ${ROOTRACKER_FILE} 2>/dev/null | tail -1)
echo "NPER is originally ${NPER}"
NPER=$((NPER / 2))
echo "NPER is now ${NPER}"

EDEP_FILE=edep.${RNDSEED}.root

export CPATH=$EDEPSIM/include/EDepSim:$CPATH
export ARCUBE_ACTIVE_VOLUME=volTPCActive

edep-sim \
    -C \
    -g ${GEOMETRY}.gdml \
    -o ${EDEP_FILE} \
    -e ${NPER} \
    macro_${RNDSEED}.mac

H5_FILE=${EDEP_FILE%.root}.h5

python3 convert_edepsim_roottoh5.py ${EDEP_FILE} ${H5_FILE} --keep-all-dets

mv ${EDEP_FILE} ${OUTDIR}/edep/${EDEP_FILE}
mv ${H5_FILE} ${OUTDIR}/h5/${H5_FILE}
#rm ${ROOTRACKER_FILE}
