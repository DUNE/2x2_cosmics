#!/usr/bin/env bash
# Run edep-sim on CORSIKA files

USERNAME=$USER
GEOMETRY=$1
RNDSEED=$2
OUTDIR=$3

ROOTRACKER_FILE="rootracker.${RNDSEED}.root"
NPER=$(echo "std::cout << gRooTracker->GetEntries() << std::endl;" | root -l -b ${ROOTRACKER_FILE} 2>/dev/null | tail -1)

EDEP_FILE=edep.${RNDSEED}.root
edep-sim \
    -C \
    -g ${GEOMETRY}.gdml \
    -o ${EDEP_FILE} \
    -u \
    -e ${NPER} \
    macro.mac

H5_FILE=${EDEP_FILE%.root}.h5
python3 dumpTree.py ${EDEP_FILE} ${H5_FILE}

mv ${EDEP_FILE} ${OUTDIR}/edep/${EDEP_FILE}
mv ${H5_FILE} ${OUTDIR}/h5/${H5_FILE}
rm ${ROOTRACKER_FILE}
