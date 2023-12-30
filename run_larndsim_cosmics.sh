#!/usr/bin/env bash
### shell script for running larnd-sim on a NERSC login node on a CORSIKA-made edep-sim h5 file. larnd-sim uses a log of GPU memory (30-40GB) so make sure there are no other processes running with nvidia-smi.
#
module load python

DATADIR="/pscratch/sd/s/sfogarty/cosmics/single_module"
LARNDSIM_DIR="/global/homes/s/sfogarty/larnd-sim_develop/larnd-sim"
# name and make the folder for larndsim files
DET=module0
QTHRESHOLD=6 #ke-
LARNDSIM_FOLDERNAME=cosmics_${DET}_${QTHRESHOLD}ke-threshold

# List of EDEP filenames to process
EDEP_FILENAMES=("edep.1699431047.h5" "edep.1699578263.h5" "edep.1699642964.h5")

OUTDIR=$DATADIR/larndsim/${LARNDSIM_FOLDERNAME}
mkdir -p $OUTDIR

for EDEP_FILENAME in "${EDEP_FILENAMES[@]}"; do
    config=module0
    cd $LARNDSIM_DIR
    ./install_larndsim.sh
    pip install .
    cd cli

    INPUT_FILEPATH=${DATADIR}/h5/${EDEP_FILENAME}

    seed=${EDEP_FILENAME#edep.}  # Remove "edep." from the beginning
    seed=${seed%.h5}      # Remove ".h5" from the end
    OUTPUT_FILEPATH=$OUTDIR/larndsim_${seed}.h5

    python3 simulate_pixels.py \
        $INPUT_FILEPATH \
        $OUTPUT_FILEPATH \
        --config $config \
        --rand_seed $seed
done

