#!/usr/bin/env bash
#####################################################################
# File Name    : startSims.sh
# Version      : 1.00
# Author       : Fatih ONUR
# Description  : Start sims based on passed regular expression
# Date Created : 2016.12.21
#####################################################################
set -o errexit # exit when a command fails.
set -o nounset # exit when this script tries to use undeclared variables
set -o pipefail # to catch pipe errors

# Args
NODE_TYPE="${1:-""}"

# Variables
PWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f $PWD/startNes.pl ]]; then
  echo "ERROR: Missing file: startNes.pl"
  exit -1
fi

# Main
echo "RUNNING: $0 $*"

echo "INFO: Start nodes started on `date`"

mml="$0.mml" && echo "#`date`" > $mml
sims=$(cd /netsim/netsimdir/ && echo [[:upper:]]*[!.zip] | xargs -n 1 | \
  perl -lne 'print if!/^Re|^Se|up/' | (egrep -i "${NODE_TYPE}" || true))
echo "sims: $sims"

i=1; sum=`echo $sims | xargs -n 1 | sed '/^$/d' | wc -l`
for sim in $sims
do
  echo "INFO: ($i/$sum) Starting nodes for sim:$sim"
  (su netsim -c "cd $PWD && time ./startNes.pl -s $sim -c 1") &

  i=$((i + 1))
done
wait

echo "INFO: Start nodes finished for $sum sim on `date`"

