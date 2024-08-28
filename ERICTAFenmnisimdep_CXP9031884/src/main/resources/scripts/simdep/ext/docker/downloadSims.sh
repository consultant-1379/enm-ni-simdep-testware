#!/bin/bash
#####################################################################
# File Name    : downloadSims.sh
# Version      : 1.00
# Author       : Fatih ONUR
# Description  : Download sims from the specified storage
# Date Created : 2016.12.21
#####################################################################
set -o errexit # exit when a command fails.
set -o nounset # exit when this script tries to use undeclared variables
set -o pipefail # to catch pipe errors

# Args
NSS_DROP=${1:-"17.2"}
NSS_PSV=${2:-"18.03.2"}

# Main
echo "RUNNING: $0 $*"

echo "INFO: $0 started on `date`"

SRV="${NSS_DROP}"
PSV="${NSS_PSV}"

# Functions
function download() {
  simnetContentFile=$(ls /netsim/simdepContents|grep .content | grep Simnet)
  if [[ -z ${simnetContentFile} ]]; then
    echo "INFO: simnet content file does NOT exist."
    echo "ERROR: No sims downloaded"
    exit 1;
  fi
  simnetContentFilePath="/netsim/simdepContents/$simnetContentFile"
  while read line
  do
    simPath=$(echo $line | sed 's/"//g' )
    simName=$(echo $simPath | awk -F '/' '{print $12}')
    simulation="/netsim/netsimdir/$simName.zip"
    status=$(curl -w %{http_code} $simPath -o $simulation)
    if [[ $status != "200" ]]; then
      echo "ERROR: Sim $simName failed to download"
      exit 1;
    else
      echo "INFO: Sim $simName downloaded succesfully"
    fi
  done < $simnetContentFilePath
}

echo "INFO: Downloading sims for:$SRV from $PSV"
download
mml="$0.mml" && echo "#`date`" > $mml
sims=`ls /netsim/netsimdir/ | (grep -i zip || true)`

i=1; sum=`echo $sims | xargs -n 1 | sed '/^$/d' | wc -l`
for sim in $sims
do
  echo "INFO: ($i/$sum) Opening sim:$sim"
  if [[ $sim =~ "RNC" ]]
  then 
  echo -e ".uncompressandopen $sim force\n.select network\n.emptyfilestore" | tee -a $mml
  else
  echo -e ".uncompressandopen $sim force\n.select network\n" | tee -a $mml
  fi
  simZip=$sim
  sim=`printf '%s\n' "${sim//'.zip'/}"`

  NODE_TYPES="lte|mgw|spitfire|tcu|rnc|esapc|epg|mtas|cscf|sbg|vmrf|vbgf|ipworks|hss-fe"
  echo "INFO: ($i/$sum) Checking for tmpfs sim:$sim"
#  if [[ `echo $sim | (egrep -ci "${NODE_TYPES}" || true)` -gt 0 ]]; then
    echo "INFO: ($i/$sum) Unsetting tmpfs for sim:$sim"
    echo -e ".open $sim\n.select network\n.set fs tmpfs off\n.set save" | tee -a $mml
#  else
#    echo "INFO: ($i/$sum) No tmpfs update needed for sim:$sim"
#  fi

  #echo "INFO: Updating ip for sim:$sim"
  #ip="0.0.$i.1"
  #echo -e ".select network\n.modifyne set_subaddr $ip subaddr no_value\n.set taggedaddr subaddr $ip 1\n.set save" | tee -a $mml
  #echo -e ".select network\n.start -parallel\n.stop -parallel\n.save" | tee -a $mml

  #echo "INFO: Re-Opening sim:$sim"
  #echo -e ".uncompressandopen $simZip force" | tee -a $mml

  echo "INFO: ($i/$sum) Saving sim:$sim"
  echo -e ".save" | tee -a $mml

  i=$((i + 1))
done
#cat $mml
su netsim -c "cat $mml | /netsim/inst/netsim_pipe"
rm $mml
rm -rfv /netsim/netsimdir/*.zip

echo "INFO: $0 finished for $sum sim on `date`"
