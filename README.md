### Scripts for CORSIKA simulation in the 2x2 Demonstrator and Bern module tests

This repository contains bash scripts for running CORSIKA/Fluka and edep-sim for generating cosmic ray events in the ND-LAr prototypes. The scripts will work out of the box for the single module Bern tests (and maybe a SingleCube), but may require a few modifications to work with the 2x2 Demonstrator.

The scripts are composed of the following steps:
1. Run CORSIKA to produce cosmic ray showers
2. Run the corsikaConverter program to convert the CORSIKA output to the edep-sim-friendly rootracker format
3. Run edep-sim using the rootracker file produced by the previous step

You can find the script for making corsikaConverter here: https://github.com/soleti/corsika2RooTracker/tree/main . The corsikaConverter found here will only work for a Bern single module, since it has some hard-coded dimensions. To work with the 2x2 or another detector, you will have to modify the dimensions in the file. Even though corsikaConverter requires some modifications for 2x2, the CORSIKA simulation part of `run_everything_cosmics_NERSC.sh` is already setup for 2x2.
Subsequent steps (e.g. larnd-sim, ndlar_flow) are not performed here (currently).

There are a few options for running the simulation. The first is running completely at NERSC. This method relies on shifter and containers available on NERSC, so it may not be easily run elsewhere (e.g. SLAC SDF, dunegpvm). `run_everything_cosmics_NERSC.sh` is a script that acts as a wrapper that runs each stage above, this is because we need to switch containers between steps 2 and 3. This script was adapted from on a script run on a dunegpvm for the Bern module runs (`run_everything_cosmics_at_FNAL.sh`). 

The script can be run on the command line like this:
```bash
chmod +x run_everything_cosmics_NERSC.sh
./run_everything_cosmics_NERSC.sh DET NSHOW
```

DET is 0 for a Bern module and 1 for 2x2. NSHOW is the number of showers to generate, defaults to 2000000.

Make sure to set `OUTDIR` to your own directories. `INPUTDIR` must contain the various inputs, including `run_CORSIKA.sh`, `run_edep-sim.sh`, and `corsikaConverter` from this repository. It should also contain the GDML geometry to use in edep-sim, the root to h5 converter script (e.g. `dumpTree.py`), and `requirements.txt` for the root to h5 converter. `OUTDIR` is where the data is copied to, so all the files produced by various grid jobs will be directed to this directory to be stored. 

An alternative option for running the simulation is if you're producing MC for the Bern module tests. In this case you can use `run_everything_cosmics_at_FNAL_Module0.sh`, which is the same as the original script that was used to make the first cosmic samples for Module-0. This can run completely on a dunegpvm. We need to run the 2x2 simulation over on NERSC because the 2x2 requires a newer edep-sim version (used in the 2x2_sim) that supports the newest geometry. To run the 2x2 simulation on a dunegpvm (`run_everything_cosmics_at_FNAL_2x2.sh`), you will just need to install the compatible edep-sim version (if you want to take on this task, feel free to do so! :) ). 

To run this script, you can do the following:
```bash
chmod +x run_everything_cosmics_at_FNAL_Module0.sh
./run_everything_cosmics_at_FNAL_Module0.sh FIRST NSHOW TEST
```

2x2_sim: https://github.com/DUNE/2x2_sim
