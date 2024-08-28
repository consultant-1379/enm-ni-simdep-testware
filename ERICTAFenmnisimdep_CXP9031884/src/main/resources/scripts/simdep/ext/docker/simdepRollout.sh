#!/bin/sh
FILE=`ls /netsim/simdepContents | grep Simnet_docker_*.*.content`
simLTE="NO_NW_AVAILABLE"
simCORE="NO_NW_AVAILABLE"
simWRAN="NO_NW_AVAILABLE"
if [[ -z $1 ]]
then
while read line
do
     simName=$(echo $line | awk -F '/' '{print $12}')
     if [[ $simName == *"LTE"* ]]
     then
       if [[ $simLTE == "NO_NW_AVAILABLE" ]]
       then
           simLTE=$simName
       else
           simLTE="$simLTE:$simName"
       fi
     else
       if [[ $simCORE == "NO_NW_AVAILABLE" ]]
       then
           simCORE=$simName
       else
           simCORE="$simCORE:$simName"
       fi
     fi
done < /netsim/simdepContents/$FILE
else
    IFS=',' read -r -a simsList <<< $1
    IFS=' ' read -r -a simsList <<< $simsList
    for key in "${!simsList[@]}"
    do
        simName="${simsList[$key]}"
        if [[ $simName == *"LTE"* ]]
        then
            if [[ $simLTE == "NO_NW_AVAILABLE" ]]
            then
                simLTE=$simName
            else
                simLTE="$simLTE:$simName"
            fi
        else
            if [[ $simCORE == "NO_NW_AVAILABLE" ]]
            then
                simCORE=$simName
            else
                simCORE="$simCORE:$simName"
            fi
        fi
    done
fi

su netsim -c '/netsim/inst/restart_netsim';cd /var/simnet/enm-ni-simdep/scripts/simdep/bin/;python rollout.py -overwrite -release ${SRV} -serverType VM -deploymentType mediumDeployment -simLTE $simLTE -simWRAN NO_NW_AVAILABLE -simCORE $simCORE "-LTE /sims/O17/ENM/18.10/mediumDeployment/LTE/15KLTE -CORE /sims/O17/ENM/18.10/mediumDeployment/CORE -WRAN /sims/O17/ENM/18.10/mediumDeployment/WRAN/15KWRAN" -securityTLS on -securitySL2 on -masterServer 0.0.0.0 -ciPortal yes -docker no -switchToRv no
