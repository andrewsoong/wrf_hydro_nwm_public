#!/bin/bash

## This script takes one optional argument:
## a file which sets the environment variables
## to use in the compile (clearning any inherited
## from the calling envionrment first). The template
## fo this file is src/setEnvar.sh. Please
## copy that file to src, make copies
## for your favorite compile configurations, and
## pass the appropriate file name to this script
## as desired.
env_file=$1

if [[ ! -z $env_file ]]; then

    ## unset these in the env so we are not mixing
    ## and matching env vars and the sourced file.
    unset WRF_HYDRO
    unset HYDRO_D
    unset RESERVOIR_D
    unset SPATIAL_SOIL
    unset WRF_HYDRO_RAPID
    unset NCEP_WCOSS
    unset NWM_META
    unset WRF_HYDRO_NUDGING

    echo "configure: Sourcing $env_file for the compile options."
    source $env_file

else
    echo "configure: Using the compile options in the calling environment."
fi

if [[ "$WRF_HYDRO" -ne 1 ]]; then
    echo
    echo "The WRF_HYDRO compile option is required to be 1 for compile_offline_NoahMP.sh"
    exit 1
fi

rm -f  LandModel LandModel_cpl
cp arc/Makefile.NoahMP Makefile
cd Land_models/NoahMP
cp hydro/Makefile.hydro Makefile
if [[ -e "MPP" ]]; then  rm -rf  MPP; fi
ln -sf ../../MPP .
cd ../..

ln -sf Land_models/NoahMP LandModel
cat macros LandModel/hydro/user_build_options.bak  > LandModel/user_build_options
ln -sf CPL/NoahMP_cpl LandModel_cpl
make clean; rm -f Run/wrf_hydro_NoahMP ; rm -f Run/*TBL ; rm -f Run/*namelist*

#for debugging and testing
#make debug; make install; make test
make && make install

if [[ $? -eq 0 ]]; then
    echo
    echo '*****************************************************************'
    echo "Make was successful"
else
    echo
    echo '*****************************************************************'
    echo "Make NOT successful"
    exit 1
fi

cd Run
mv  wrf_hydro wrf_hydro_NoahMP; ln -sf wrf_hydro_NoahMP wrf_hydro

if [ "$NWM_META" != "1" ]; then
    # If it is not an nwm version, copy the stock namelists and tables.
    cp ../template/NoahMP/namelist.hrldas .
    cp ../template/HYDRO/hydro.namelist .
    cp ../Land_models/NoahMP/run/*TBL .
    cp ../template/HYDRO/HYDRO.TBL .
    cp ../template/HYDRO/CHANPARM.TBL .
else
    # If it's an nwm version (nwm release branch), grab the nwm versions from elsewhere.
    echo 'NWM version: not populating with generic templates'
fi


echo
echo '*****************************************************************'
echo "The environment variables used in the compile:"
grepStr="(WRF_HYDRO)|(HYDRO_D)|(SPATIAL_SOIL)|(WRF_HYDRO_RAPID)|(HYDRO_REALTIME)|(NCEP_WCOSS)|(WRF_HYDRO_NUDGING)|(NETCDF)"
printenv | egrep -w "${grepStr}" | sort

exit 0
