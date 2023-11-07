# create container for running hdf5 converter script
rm -rf convert.venv
python3 -m venv convert.venv
source convert.venv/bin/activate
pip3 install -r requirements.txt