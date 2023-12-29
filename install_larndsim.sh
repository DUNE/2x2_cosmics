#!/usr/bin/env bash
### script for installing larnd-sim on NERSC. Move this to your larndsim dir.

set -o errexit

module load cudatoolkit/12.2
module load python/3.11

venvName=larnd.venv

python -m venv "$venvName"
source "$venvName"/bin/activate
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt

# Might need to remove larnd-sim from this requirements file. DONE.
# pip install -r requirements.txt
# exit

# If installation via requirements.txt doesn't work, the below should rebuild
# the venv. Ideally, install everything *except* larnd-sim using the
# requirements.txt, then just use the block at the bottom to install larnd-sim.

# pip install -U pip wheel setuptools
# pip install cupy-cuda11x

pip install cupy-cuda12x


