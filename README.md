# Readme
## Description
A version of NBODY6++GPU that detects collisions without the usage of stellar evolution and tracks collisions.

## Installation
1. Run `./configure`. If you would like to use the HDF5 data format for storing data, run `./configure --enable-hdf5`. Make sure you have the HDF5 library installed.
2. Type `make -j 8`.

## Running simulations
1. You need to use MCluster data files to start the simulations. To do so, generate the starcluster using MCluster and then copy the datafiles into a directory. 
2. Copy the `nbody6++.*.starsmasher` file generated from NBODY6 into the folder containing the MCluster initial conditions datafile.
3. Type `qsub gonzales.pbs` to start the run.
