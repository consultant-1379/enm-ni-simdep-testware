#!/usr/bin/env bash
#####################################################################
# File Name    : ci.sh
# Version      : 1.00
# Author       : Fatih ONUR
# Description  : Gets CI Portal contents for Docker, Netsim and Netsim Patches
# Date Created : 2016.12.21
#####################################################################
set -o errexit # exit when a command fails.
set -o nounset # exit when this script tries to use undeclared variables
set -o pipefail # to catch pipe errors

# Args
NSS_DROP="${1:-"17.2"}"
NODE_TYPE="${2:-""}"

function mkdirRec(){
  local remoteDir=$1
  perl -lne '@folders=split /\//;
    foreach $f (@folders[1..$#folders])
    {print "mkdir $f\ncd $f"}' <<< "$remoteDir"
}

# Functions
function upload(){
  local remoteDir="$1"
  local file="$2"
  local passive=`perl -e 'if(-f "/.dockerenv"){print "passive";}else{print "";}'`
  ftp -n ftp.athtem.eei.ericsson.se << EOF
$passive
user simadmin simadmin
bin
$(mkdirRec  "$remoteDir")
lcd /netsim/netsimdir
put $file
bye
EOF
}
function getFtpDir(){
  srv=$1
  hsrv=`echo "${srv}" | perl -lne 'if(/(\d+).(\d+)/){print $1}'`
  echo "/sims/O${hsrv}/ENM/${srv}/DOCKER/GO"
}

# Main
echo "RUNNING: $0 $*"

echo "INFO: $0 started on `date`"

mml="$0.mml" && echo "#`date`" > $mml
sims=$(cd /netsim/netsimdir/ && echo [[:upper:]]*[!.zip] | xargs -n 1 | \
  perl -lne 'print if!/^Re|^Se|up/' | (egrep -i "$NODE_TYPE" || true))
echo "sims: $sims"

i=1; sum=`echo $sims | xargs -n 1 | sed '/^$/d' | wc -l`
for sim in $sims
do
  echo "INFO: ($i/$sum) Saving and compressing sim:$sim"
  echo -e ".open $sim\n.saveandcompress force nopmdata" >> $mml
  i=$((i + 1))
done
su netsim -c "cat $mml | /netsim/inst/netsim_pipe"
rm $mml

ftpDir=`getFtpDir $NSS_DROP`
i=1
for sim in $sims
do
  echo "INFO: ($i/$sum) Uploading sim:$sim"
  sim="${sim}.zip"
  upload $ftpDir $sim
  i=$((i + 1))
done

echo "INFO: $0 finished for $sum sim on `date`"
