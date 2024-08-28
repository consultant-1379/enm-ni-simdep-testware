#!/bin/sh


nssDrop=$1
Adaptive=$2
release=$nssDrop
user=`whoami`
if [[ $user != "netsim" ]]
then
    echo "ERROR: Only netsim user can excute this script"
    exit 1
fi
echo 'running as netsim user'

cd /netsim/
addsimstolist="`cat /netsim/rolloutsims.log`"
simnameslist="`cat /netsim/simdepContents/Simnet.Urls | tr -s '/' | tr '/' ' ' | awk '{print $13}' | tee /netsim/simnameslist.log`"
cat /netsim/rolloutsims.log | sed "s/$/ `date`/" | tee -a /netsim/simUpdateVersionHistory.txt
simLTE="NO_NW_AVAILABLE"
simCORE="NO_NW_AVAILABLE"
simWRAN="NO_NW_AVAILABLE"
echo "$nssDrop" > /netsim/newnssdrop.log
if [[ -z $addsimstolist ]]
then 
    echo "all the simulations are latest simulations. so no need to do adaptive rollout"
else
    for simName in $addsimstolist
    do
       if [[ $simName == *"LTE"* ]]
       then
           if [[ $simLTE == "NO_NW_AVAILABLE" ]]
           then
               simLTE=$simName
           else
               simLTE="$simLTE:$simName"
           fi
       elif [[ $simName == *"RNC"* || $simName == *"RBS"* ]]
       then
           if [[ $simWRAN == "NO_NW_AVAILABLE" ]]
           then
               simWRAN=$simName
           else
               simWRAN="$simWRAN:$simName"
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
    sims="$simLTE:$simWRAN:$simCORE"
    echo '$sims'
    echo shroot | sudo -S -u root bash -c "cd /var/simnet/enm-ni-simdep/scripts/simdep/bin/;python /var/simnet/enm-ni-simdep/scripts/simdep/bin/rollout.py -release $nssDrop -serverType VM -deploymentType mediumDeployment -simLTE $simLTE -simWRAN $simWRAN -simCORE $simCORE '-LTE /sims/O17/ENM/18.10/mediumDeployment/LTE/5KLTE -CORE /sims/O17/ENM/18.10/mediumDeployment/CORE -WRAN /sims/O17/ENM/18.10/mediumDeployment/WRAN/5KWRAN' -securityTLS on -securitySL2 on -masterServer 131.160.130.192 -ciPortal yes -docker no -switchToRv yes -IPV6Per yes -installType online -rolloutType normal"
    
    
    for SIMNAME in ${addsimstolist[@]}
    do
    echo -e "*************** $SIMNAME *******************\n"
    if [[ $SIMNAME == *"GSM"* ]]
    then
	    cat /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/${SIMNAME}_assignip.mml | /netsim/inst/netsim_shell
	    rm -rf /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/${SIMNAME}_assignip.mml
	    echo -e ".open $SIMNAME \n .select network \n .start  \n .generateNetworkMap" | /netsim/inst/netsim_shell
    else
    
    
    
    NODELIST=$(echo -e '.open '$SIMNAME'\n.show simnes' | /netsim/inst/netsim_shell | grep -vE 'OK|NE|>>' | awk '{print $1}')
    NODES=(${NODELIST// / })

    count=0
    for NODE in ${NODES[@]}
    do
    count=$((count+1))
    ip=`cat /netsim/${SIMNAME}_nodeip.txt | head -$count | tail -1 `
    echo -e ".open $SIMNAME \n .select $NODE \n .stop \n .modifyne set_subaddr $ip subaddr no_value \n .set taggedaddr subaddr $ip 1 \n .set save \n .start" | /netsim/inst/netsim_shell
    done
    fi
    cd /var/simnet/enm-ni-simdep/scripts/simdep/bin/
    python netsim/arne_generation.py $SIMNAME no
    done
fi   

#Updating Simnet.Urls with latest url
for simName in  ${addsimstolist[@]}
do
simUrl="`grep -w $simName /netsim/simdepContents/Simnet_*.content`"
cat /netsim/simdepContents/Simnet.Urls | grep -v "$simName" > /netsim/simdepContents/tmp_Simnet.Urls
mv -f /netsim/simdepContents/tmp_Simnet.Urls /netsim/simdepContents/Simnet.Urls;
echo $simUrl > /netsim/simdepContents/tmp1_Simnet.Urls

sed -e 's/^/url = /' /netsim/simdepContents/tmp1_Simnet.Urls >> /netsim/simdepContents/Simnet.Urls;
done
    
