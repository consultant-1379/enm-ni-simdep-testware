#!/usr/bin/env bash
#####################################################################
# File Name    : cleanNetsim.sh
# Version      : 1.00
# Author       : Fatih ONUR
# Description  : Gets CI Portal contents for Docker, Netsim and Netsim Patches
# Date Created : 2016.12.21
#####################################################################
set -o errexit # exit when a command fails.
set -o nounset # exit when this script tries to use undeclared variables
set -o pipefail # to catch pipe errors


# Main
echo "RUNNING: $0 $*"

echo "INFO: Clean netsim started on `date`"

echo "INFO: Deleting all zip files"
rm -rfv /netsim/netsimdir/*.zip

mml="$0.mml" && echo "#`date`" > $mml
sims=$(cd /netsim/netsimdir/ && echo [[:upper:]]*[!.zip] | xargs -n 1 | \
  perl -lne 'print if!/^Re|^Se|up/' )

echo "sims: $sims"
for sim in $sims
do
  echo "INFO: Deleting sim:$sim"
  echo -e ".deletesimulation $sim force" >> $mml
done
su netsim -c "cat $mml | /netsim/inst/netsim_pipe"
rm $mml

echo "INFO: Clean netsim finished on `date`"
