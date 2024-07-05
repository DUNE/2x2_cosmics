#!/usr/bin/env bash
### shell script for running larnd-sim on a NERSC login node on a CORSIKA-made edep-sim h5 file. larnd-sim uses a log of GPU memory (30-40GB) so make sure there are no other processes running with nvidia-smi.
#

GEOMETRY=$1 # e.g. module0, module1, 2x2, 2x2_mod2mod_variation

module load python

DATADIR="/pscratch/sd/e/ehinkle/nd_ana/cosmics_sim/single_module"
LARNDSIM_DIR="/global/cfs/cdirs/dune/users/ehinkle/nd_prototypes_ana/2x2_sim/run-larnd-sim/"
# name and make the folder for larndsim files
DET=${GEOMETRY}
QTHRESHOLD=6 #ke-
LARNDSIM_FOLDERNAME=cosmics_${DET}_${QTHRESHOLD}ke-threshold

# List of EDEP filenames to process
EDEP_FILENAMES=("edep.1708738572.h5")

OUTDIR=$DATADIR/larndsim/${LARNDSIM_FOLDERNAME}
mkdir -p $OUTDIR

for EDEP_FILENAME in "${EDEP_FILENAMES[@]}"; do
    config=${GEOMETRY}
    cd $LARNDSIM_DIR
    ./install_larnd_sim.sh
    cd larnd-sim
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

