#!/bin/sh
cp /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/jq-1.0.1.tar .; tar -xvf jq-1.0.1.tar ; chmod +x ./jq
ClusterID=$1
curl --retry 5 -fsS "https://ci-portal.seli.wh.rnd.internal.ericsson.com/generateTAFHostPropertiesJSON/?clusterId=$ClusterID&tunnel=true&pretty=true&Netsims=true" -o deploymentdetails.json
cat deploymentdetails.json | ./jq '.[] | select(.["hostname"]=="'ms1'")' | grep ip | awk -F'ip": "' '{print $2}' | tr -d '",' > a.txt
msip=$(cat a.txt)
echo $msip
echo "https://nsslogging.lmera.ericsson.se/app/kibana#/discover?_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-24h,mode:quick,to:now))&_a=(columns:!(requestOrResponse,protocol,nodeName,command),index:'$ClusterID',interval:auto,query:(language:lucene,query:''),sort:!(nssLogTime,desc))" > nsslog.txt

/usr/bin/expect <<EOF
spawn scp -o StrictHostKeyChecking=no nsslog.txt root@$msip:/var/ericsson/ddc_data/config/
expect {
    -re assword: {send "12shroot\r";exp_continue}
}
    sleep 5
EOF
rm a.txt
