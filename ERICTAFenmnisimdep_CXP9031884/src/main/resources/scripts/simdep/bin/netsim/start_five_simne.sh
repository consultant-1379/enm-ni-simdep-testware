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
export sim=$1


#if [ -r $NETSIMDIR/simulations ] ; then
#    SIMULATIONS=`cat $NETSIMDIR/simulations`
#else
#    SIMULATIONS=`ls -1 $NETSIMDIR/*/simulation.netsimdb | sed -e "s/.simulation.netsimdb//g" -e "s/^[^*]*[*\/]//g" |grep -v -E '^default$'`
#fi

#echo "$SIMULATIONS" | while read sim acts
#do
    if [[ $sim =~ "SGSN" ]]
    then
        echo "$sim matches SGSN\n"
        $HOME/inst/netsim_pipe<<EOF
.open $sim
.select network
.setuser netsim netsim
.set save
EOF
    fi
    count=1
    NES=`echo ".show simnes" | $HOME/inst/netsim_pipe -sim ${sim} | cut -d ' ' -f 1 | tail -n+3 | sed '$d'`
    echo "$NES" | while read simne
    do
        if [ "$count" -gt 5 ]
        then
            break
        else
            $HOME/inst/netsim_pipe<<EOF
.open $sim
.select $simne
.start
EOF
                count=$(($count+1))
        fi
    done
    for act in $acts
    do
        echo ".setactivity $act"
        echo ".startactivity"
    done
#done
