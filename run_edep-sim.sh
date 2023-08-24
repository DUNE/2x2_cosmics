#!/usr/bin/env bash
# Run edep-sim on CORSIKA files

USERNAME=$USER
GEOMETRY=$1
RNDSEED=$2
INPUTDIR=$3
OUTDIR=$4

ROOTRACKER_FILE="rootracker.${RNDSEED}.root"
NPER=$(echo "std::cout << gRooTracker->GetEntries() << std::endl;" | root -l -b ${ROOTRACKER_FILE} 2>/dev/null | tail -1)

TIME_START=`date +%s`

TIME_EDEPSIM=`date +%s`
EDEP_FILE=edep.${RNDSEED}.root
edep-sim \
    -C \
    -g ${GEOMETRY}.gdml \
    -o ${EDEP_FILE} \
    -u \
    -e ${NPER} \
    macro.mac

TIME_HDF5=`date +%s`
H5_FILE=${EDEP_FILE%.root}.h5
python3 convert_edepsim_roottoh5.py ${EDEP_FILE} ${H5_FILE}

ifdh_mkdir_p ${OUTDIR}/corsika/${RDIR}
ifdh_mkdir_p ${OUTDIR}/rootracker/${RDIR}
ifdh_mkdir_p ${OUTDIR}/edep/${RDIR}
ifdh_mkdir_p ${OUTDIR}/h5/${RDIR}

