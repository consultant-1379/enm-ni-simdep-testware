#!/bin/sh
PWD=`dirname "$0"`
CWD=`pwd`
echo "$PWD"
if [ -f $PWD/../conf/conf.txt ]
then
   source $PWD/../conf/conf.txt
else
   echo "ERROR:conf.txt doesn't exist"
   exit 1
fi

if [ -f $PWD/jq-1.0.1.tar ]
then 
cp $PWD/jq-1.0.1.tar .
echo " jq is already present "
tar -xvf jq-1.0.1.tar 
chmod +x ./jq
    if [[ $? -ne 0 ]]
        then
            echo "ERROR: Extractin jq failed from simdep"
            exit 201
    else
            echo "jq Extracted Successfully"
     fi

else
cp $PWD/jq-1.0.1.tar .
 if [[ $? -ne 0 ]]
        then
            echo "ERROR: Copying jq failed from simdep"
            exit 201
        fi
        tar -xvf jq-1.0.1.tar ; chmod +x ./jq
fi


simName=$1;
path=$2;
echo "$path"
echo "Applying TLS for $simName"
map_generator=`/netsim/inst/netsim_pipe<<EOF
.generateNetworkMap
EOF`

echo "$map_generator"
Nodedetails=`./jq  --raw-output '.networkMap[] | select(.["Simulation"]=="'$simName'") | (."name") ' /netsim/netsimdir/networkMap.json`
while read -r Nodename;
do
  NodeIp=`./jq  --raw-output '.networkMap[] | select(.["Simulation"]=="'$simName'") | select (.["name"]=="'$Nodename'") ' /netsim/netsimdir/networkMap.json | grep "ip" | awk -F '"' '{print $4}'`
  echo -e "\nINFO: Nodename is $Nodename and NodeIp is $NodeIp"
  certsPath='/tmp/TLS/'$simName/$Nodename/
  rm -rf $certsPath
  if [[ ${simName} == *"VNF-LCM"*  ||  ${simName} == *"EVNFM"* ]]
  then
  mkdir -p /netsim/netsimdir/${simName}/VNF/$Nodename/
  fi
  mkdir -p $certsPath
  cd ${certsPath}../
  output=`$path/generateCerts.sh "$NodeIp" "$certsPath"`
  echo -e "\n\nINFO: generatecerts output is \n$output\n"
  cd $CWD
  echo `$path/modifyTLS.pl "$simName" "$Nodename" "$certsPath"`
done<<< "$Nodedetails"

#rm -rf jq-1.0.1.tar jq
