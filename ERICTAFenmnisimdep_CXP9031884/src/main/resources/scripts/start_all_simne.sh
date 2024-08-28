#!/bin/sh
## $Id: start_all_simne.sh,v 1.5 2006/08/30 11:50:25 qbejoha Exp $
## This script should be piped to netsim_pipe.
## It will start all simulations listed in a file or, if no file exists,  
## all simulations in the simulations directory EXCEPT the default
## simulation.
##
## The simulation file should be placed in $NETSIMDIR and should have
## one simulation name on each line, optionally followed by a set of
## activites seperated by spaces to be started.
##
## Example $NETSIMDIR/simulations file that will start the simulation
## mySimulation and start activites activity1 and activity2:
##
## mySimulation activity1 activity2

if [ "$NETSIMDIR" = "" ] ; then
    NETSIMDIR=$HOME/netsimdir
fi
export NETSIMDIR

if [ -r $NETSIMDIR/simulations ] ; then
    SIMULATIONS=`cat $NETSIMDIR/simulations`
else
    SIMULATIONS=`ls -1 $NETSIMDIR/*/simulation.netsimdb | sed -e "s/.simulation.netsimdb//g" -e "s/^[^*]*[*\/]//g" |grep -v -E '^default$'`
fi

echo "$SIMULATIONS" | while read sim acts
  do
  echo ".open $sim"
  echo ".selectnocallback network"
  echo ".start"
  for act in $acts
    do
    echo ".setactivity $act"
    echo ".startactivity"
  done      
done    
