fileName=$1
simName=$2
mmlFileName=/var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/${simName}_assignip.mml
echo "$simName"
if [[ -s ${fileName} ]]
then
cat ${fileName} | grep "ioIpAddress"|cut -d "\"" -f2 > GSM_nodeip.txt
cat ${fileName} | grep "hostname" |cut -d "\"" -f2 > GSM_nodeName.txt
else
echo "$fileName does not exist"
fi
old_ips=( $( cat GSM_nodeip.txt ) )

#IFS=$'\n' read -d '' -r -a lines < /netsim/netsimdir/exported_items/GSM_nodeip.txt
Ips=`cat ${fileName} | grep "ioIpAddress"|cut -d "\"" -f2`
lines=(${Ips// / })
echo "${lines[@]}"
node=`cat ${fileName} | grep "hostname" |cut -d "\"" -f2`
#echo "$old_ips[@]"
i=0
count=`cat ${fileName} | grep "ioIpAddress"|cut -d "\"" -f2 | wc -l`
if [[ $count == 3 ]]
then
cat >> ${mmlFileName} << ABC
.open $simName
.select $node
.modifyne set_subaddr ${lines[0]} subaddr subaddr_nodea|subaddr_nodeb
.set taggedaddr subaddr  ${lines[0]} 1
.set taggedaddr subaddr_nodea ${lines[1]}  1
.set taggedaddr subaddr_nodeb ${lines[2]} 1
.set save
.start
ABC
else
if [[ $count == 6 ]]
then
cat >> ${mmlFileName} << ABC
.open $simName
.select $node
.modifyne set_subaddr ${lines[0]} subaddr subaddr_nodea|subaddr_nodeb
.set taggedaddr subaddr  ${lines[0]} 1
.set taggedaddr subaddr_nodea ${lines[1]}  1
.set taggedaddr subaddr_nodeb ${lines[2]} 1
.set taggedaddr subaddr_ap2 ${lines[3]} 1
.set taggedaddr subaddr_ap2nodea ${lines[4]} 1
.set taggedaddr subaddr_ap2nodeb ${lines[5]} 1
.set save
.start
ABC
fi
fi 
chmod 777 ${mmlFileName}
#mv ${simName}_assign.mml /netsim/${simName}_assign.mml
