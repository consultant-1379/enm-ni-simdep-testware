#!/usr/bin/env bash
#####################################################################
# File Name    : ci.sh
# Version      : 1.00
# Author       : Fatih ONUR
# Description  : Gets CI Portal contents for Docker, Netsim, Netsim Patches and Simdep
# Date Created : 2016.12.21
#####################################################################
set -o errexit # exit when a command fails.
set -o nounset # exit when this script tries to use undeclared variables
set -o pipefail # to catch pipe errors

# Args
NSS_DROP="${1:-"17.2"}"
NSS_PSV="${2:-"18.03.2"}"
NODE_TYPES="${3:-"LTE01|LTE02|LTE03|LTE*|CISCO.*9000|CISCO.*900|TCU02|SIU02|JUNIPER|SGSN.*16A.*CP01|MGW.*UPGIND|CORE.*ESAPC|\
Front|Spit|CORE20|CORE22|CORE23|CORE24|CORE42|CORE68|ML6351|ML6391|GSM.*16B"}"


# Setup for prerequisites
# Getting jq binary. It will  be used to parse the json files.
if [[ ! -f jq-1.0.1.tar ]]; then
  curl -O "https://arm1s11-eiffel004.eiffel.gic.ericsson.se:8443/nexus/content/repositories/nss/com/ericsson/nss/scripts/jq/1.0.1/jq-1.0.1.tar" && tar -xvf jq-1.0.1.tar && chmod +x ./jq
fi

if [[ ! -f requiredSims.txt ]]; then
   curl -O "https://arm901-eiffel004.athtem.eei.ericsson.se:8443/nexus/content/repositories/simnet/com/ericsson/simnet/docker/requiredSims.txt"
fi
# Functions
function getProductContents() {
  local nssDrop="${1:-"20.04"}"
  local mediaArtifactName="${2:-"Simnet_docker_CXP9032764"}"
  local nssVersion="${3:-"20.04.7"}"

  echo "nssDrop=${nssDrop}"
  echo "mediaArtifactName:${mediaArtifactName}"
  echo "nssVersion=${nssVersion}"

  #local lastKGB=`curl -s https://cifwk-oss.lmera.ericsson.se/getLastGoodProductSetVersion/?drop=${nssDrop}\&productSet=NSS`
  #echo "lastKGB=${lastKGB}"
  #local nssVersion="${lastKGB}"

  local nssProductSetVersion="${nssDrop}::${nssVersion}"
  echo "nssProductSetVersion=${nssProductSetVersion}"
  [[ -f "nssPS-${nssProductSetVersion}" ]] || touch "nssPS-${nssProductSetVersion}"

  curl -s --request GET "https://ci-portal.seli.wh.rnd.internal.ericsson.com//getProductSetVersionContents/?drop=${nssDrop}&productSet=NSS&version=${nssVersion}&pretty=true" > nssProductSetContent.json

  # Get the version of the Simnet Product
  local mediaArtifactVersion=$(./jq -r --arg MEDIAARTFACTNAME1 "$mediaArtifactName" '.[].contents[] | select(.artifactName == $MEDIAARTFACTNAME1) | .version' nssProductSetContent.json)
  echo "mediaArtifactVersion:${mediaArtifactVersion}"

  # Get the content of the Simnet Product iso
  wget -q -O - --no-check-certificate --post-data="{\"isoName\":\"$mediaArtifactName\",\"isoVersion\":\"$mediaArtifactVersion\",\"pretty\":true,\"showTestware\":false}" https://ci-portal.seli.wh.rnd.internal.ericsson.com/getPackagesInISO/ > productIsoContent.json

  local mediaArtifactNameFull="${mediaArtifactName}.${mediaArtifactVersion}.content"
  if [[ ${mediaArtifactName} == *"Simnet"* ]]; then
  	# Store the NExus urls for the artifacts in a file
 	 ./jq -r '.PackagesInISO | map(.url)' productIsoContent.json > ciSimsList.content

  	# Delete 1st,last lines,white spaces and commas of the json +
  	sed -ri '1d;$d;s/\s+//;s/,//' ciSimsList.content
  	for i in `cat requiredSims.txt`
  	do
        	cat ciSimsList.content | grep $i
	done > ${mediaArtifactNameFull}
  
  else
     	# Store the NExus urls for the artifacts in a file
  	./jq -r '.PackagesInISO | map(.url)' productIsoContent.json > ${mediaArtifactNameFull}

  	# Delete 1st,last lines,white spaces and commas of the json +
  	sed -ri '1d;$d;s/\s+//;s/,//' ${mediaArtifactNameFull}
 fi 


  # Temporary workaround until Axis fix the links on the Portal
  if [[ ${mediaArtifactName} != *"Simdep"* ]]; then
    sed -i 's/https:\/\/arm101-eiffel004.lmera.ericsson.se/https:\/\/arm901-eiffel004.athtem.eei.ericsson.se/g' ${mediaArtifactNameFull}
  fi
  echo "${mediaArtifactNameFull}"
}

# Main
echo "RUNNING: $0 $*"

echo "INFO: $0 started on `date`"

nssDrop="${NSS_DROP}"
nssPsv="${NSS_PSV}"
mediaArtifactName="Simnet_15K_CXP9032823"
mediaArtifactName="Simnet_5K_CXP9032794"
mediaArtifactName="Simnet_docker_CXP9032764"
contentFileDocker=`getProductContents "${nssDrop}" "${mediaArtifactName}" "${nssPsv}" | tail -1`
echo "contentFileDocker=${contentFileDocker}"
sed -i 's/https:\/\/arm1s11-eiffel004.eiffel.gic.ericsson.se:8443\/nexus\/content\/repositories\/nss/https:\/\/arm901-eiffel004.athtem.eei.ericsson.se:8443\/nexus\/content\/repositories\/nss-releases/g' ${contentFileDocker}
mediaArtifactName="Netsim_CXP9032765"
contentFileNetsim=`getProductContents "${nssDrop}" "${mediaArtifactName}" "${nssPsv}" | tail -1`
echo "contentFileNetsim=${contentFileNetsim}"
echo "NETSIM_VERSION=$(egrep -o "R\w{3}" ${contentFileNetsim} | head -1)"

mediaArtifactName="NetsimPatches_CXP9032769"
contentFileNetsimPatches=`getProductContents "${nssDrop}" "${mediaArtifactName}" "${nssPsv}"| tail -1`
echo "contentFileNetsimPatches=${contentFileNetsimPatches}"

mediaArtifactName="Simdep_CXP9032766"
contentFileSimdep=`getProductContents "${nssDrop}" "${mediaArtifactName}" "${nssPsv}"| tail -1`
echo "contentFileSimdep=${contentFileSimdep}"
echo "SIMDEP_LINK=$(cat ${contentFileSimdep} | sed -e 's/\"//g' )"

pwd=`pwd`
echo "NODE_TYPES=$NODE_TYPES"


LTE=""
CORE=""
cd $pwd
while read line;
do
  simName=`echo $line | cut -d "/" -f 12`.zip
  simLink=`echo $line |sed -e 's/\"//g'`
  echo "simName:$simName"
  #echo "simLink:$simLink"
  #cd /netsim/netsimdir && curl -o $simName $simLink
  if [[ "$simName" == *"LTE"* ]]; then
    LTE=`echo $LTE | perl -lne 'if(length($_)<1){print "$_"}else{print "$_:"}'`
    LTE=${LTE}`echo $simName | grep -i lte`
  else
    CORE=`echo $CORE | perl -lne 'if(length($_)<1){print "$_"}else{print "$_:"}'`
    CORE=${CORE}`echo $simName`
  fi
done<${contentFileDocker}

echo "LTE=$LTE"
echo "CORE=$CORE"
echo "INFO: $0 ended on `date`"
