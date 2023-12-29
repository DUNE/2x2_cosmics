#!/usr/bin/env bash
### shell script for running larnd-sim on NERSC on a CORSIKA-made edep-sim h5 file

DATADIR="/pscratch/sd/s/sfogarty/cosmics/single_module"
LARNDSIM_DIR="/global/homes/s/sfogarty/larnd-sim"

EDEP_FILENAME="edep.1699406099.h5"
INPUT_FILEPATH=${DATADIR}/h5/${EDEP_FILENAME}

# name and make the folder for larndsim files
DET=module0
QTHRESHOLD=6 #ke-
LARNDSIM_FOLDERNAME=cosmics_${DET}_${QTHRESHOLD}ke-threshold
OUTDIR=$DATADIR/larndsim/$LARNDSIM_FOLDERNAME
mkdir -p $OUTDIR

seed=${EDEP_FILENAME#edep.}  # Remove "edep." from the beginning
seed=${seed%.h5}      # Remove ".h5" from the end
OUTPUT_FILEPATH=$OUTDIR/larndsim_${seed}.h5

config=module0
cd $LARNDSIM_DIR
pip install .
cd cli
python3 simulate_pixels.py \
    $INPUT_FILEPATH \
    $OUTPUT_FILEPATH \
    --config $config \
    --rand_seed $seed
    

    







