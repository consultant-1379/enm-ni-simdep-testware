#!/bin/sh

set -o pipefail

if [[ ! -f /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/adaptivescript.sh ]]
then
    echo "ERROR: Error adaptivescript.sh not present"
    exit 1
fi

user=`whoami`
if [[ $user != "root" ]]
then
    echo "ERROR: Only Root user can excute this script"
    exit 1
fi

if [ $# != 4 ]
then
    echo "ERROR : Number of  Parameters Passed are incorrect. please check"
    exit 1
fi
nssDrop=$1
csvlink=$2
nssVersion=$3
Adaptive=$4
cd /netsim/
########--------------------------------------------------#########
#get jq binary. we will use this to parse the json files.
curl --retry 5 -fsS -O "https://arm901-eiffel004.athtem.eei.ericsson.se:8443/nexus/content/repositories/nss-releases/com/ericsson/nss/scripts/jq/1.0.1/jq-1.0.1.tar" || { echo "Why so serious. Call the NSS-MT Team to turn that frown upside down. They will investigate why jq.tar did not download from Nexus successfully" && exit 1; }
tar -xvf jq-1.0.1.tar
chmod +x ./jq
########--------------------------------------------------#########END
curl --retry 5 -fsS "$csvlink" -o nssModuleDetails.csv
csvfile="`cat nssModuleDetails.csv`"
curl --request GET "https://ci-portal.seli.wh.rnd.internal.ericsson.com/getProductSetVersionContents/?drop=${nssDrop}&productSet=NSS&version=${nssVersion}&pretty=true" > NSSProductSetC0ntent.json
whatNetworkDoYouWantToRollOut="`cat /netsim/simdepContents/NRMDetails | cut -d '=' -f2 | head -2 | tail -1`"
echo "$whatNetworkDoYouWantToRollOut"
mediaArtifactName="`grep -w ${whatNetworkDoYouWantToRollOut}  nssModuleDetails.csv  | cut -d, -f2`"
echo "$mediaArtifactName"
curl --retry 5 -fsS "https://arm901-eiffel004.athtem.eei.ericsson.se:8443/nexus/content/repositories/simnet/com/ericsson/simnet/adaptiverollout/new/oldipsfetch.sh" -o oldipsfetch.sh
products="${mediaArtifactName}"
release=$nssDrop
echo "# creating content file for $mediaArtifactName"
#get the version of the Simdep Product
export MEDIAARTFACTNAME=${mediaArtifactName}
mediaArtifactVersion=$(./jq -r --arg MEDIAARTFACTNAME1 "$MEDIAARTFACTNAME" '.[].contents[] | select(.artifactName == $MEDIAARTFACTNAME1) | .version' NSSProductSetC0ntent.json)
echo "mediaArtifact $mediaArtifactName"
echo "mediaArtifactVersion $mediaArtifactVersion"
echo "final name ${mediaArtifactName}.${mediaArtifactVersion}.content"
rm -rf /netsim/simdepContents/Simnet*content
#get the content of the Product iso
wget -q -O - --no-check-certificate --post-data="{\"isoName\":\"$mediaArtifactName\",\"isoVersion\":\"$mediaArtifactVersion\",\"pretty\":true,\"showTestware\":false}" https://ci-portal.seli.wh.rnd.internal.ericsson.com/getPackagesInISO/ > ${mediaArtifactName}_IsoC0ntent.json
#store the Nexus urls for the artifacts in a file
./jq -r '.PackagesInISO | map(.url)' ${mediaArtifactName}_IsoC0ntent.json > /netsim/simdepContents/Simnet_${mediaArtifactName}.${mediaArtifactVersion}.content
cd /netsim/simdepContents/
#delete 1st and last lines of the json
sed -i '1d' Simnet_${mediaArtifactName}.${mediaArtifactVersion}.content
sed -i '$d' Simnet_${mediaArtifactName}.${mediaArtifactVersion}.content
#remove whitespaces and comma from each line
sed -i 's/^[ \t]*//;s/[ \t]*$//' Simnet_${mediaArtifactName}.${mediaArtifactVersion}.content
sed -i 's/,$//' Simnet_${mediaArtifactName}.${mediaArtifactVersion}.content
#To get content from proxy server
sed -i 's/https:\/\/arm1s11-eiffel004.eiffel.gic.ericsson.se:8443\/nexus\/content\/repositories\/nss/https:\/\/arm901-eiffel004.athtem.eei.ericsson.se:8443\/nexus\/content\/repositories\/nss-releases/g' Simnet_${mediaArtifactName}.${mediaArtifactVersion}.content

echo "${mediaArtifactName} Artifact URL(s) is/are: $(cat Simnet_${mediaArtifactName}.${mediaArtifactVersion}.content)"
echo "mediaArtifactUrl is: ${mediaArtifactName}Url"
sed -e 's/^/url = /' Simnet_${mediaArtifactName}.${mediaArtifactVersion}.content > ${mediaArtifactName}.Urls
echo "${mediaArtifactName}Url=$(cat Simnet_${mediaArtifactName}.${mediaArtifactVersion}.content)" >> envVariables1
cd /netsim/
simnameslist="`cat /netsim/simdepContents/Simnet.Urls | tr -s '/' | tr '/' ' ' | awk '{print $13}' | tee simnameslist.log`"
rm -rf  rolloutsims.log
simLTE="NO_NW_AVAILABLE"
simCORE="NO_NW_AVAILABLE"
simWRAN="NO_NW_AVAILABLE"
for sim in $simnameslist
do
    simversioninvm="`cat /netsim/simdepContents/Simnet.Urls | grep $sim |tr -s '/' | tr '/' ' ' | awk '{print $14}' | tee /netsim/${sim}_version.log`"
    newversionincontent="`cat /netsim/simdepContents/Simnet_${mediaArtifactName}.${mediaArtifactVersion}.content | grep $sim | tr -s '/' | tr '/' ' ' | awk '{print $12}' | head -1 | tee /netsim/${sim}_newversion.log`"
    if [[ "`cat /netsim/${sim}_newversion.log`"  != "`cat /netsim/${sim}_version.log`" ]]
    then  
	    
        addsimstolist="`cat /netsim/simdepContents/Simnet.Urls | grep $sim |tr -s '/' | tr '/' ' ' | awk '{print $13}' | tee -a rolloutsims.log`"
	if [[ $sim == *"GSM"* ]]
	then
		sh /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/gsm_FinalAssign_ip.sh $sim
	else
        sh oldipsfetch.sh $sim
	fi
    fi
done
su netsim -c '/var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/adaptivescript.sh $1 $4'
