#!/bin/sh
if [ $# -ne 1 ]
then
    echo "ERROR: Invalid arguments"
    echo "Usage: ./set_tacacs.sh simName"
    echo "Example: ./set_tacacs.sh CORE-FT-SCEF-18.4x10-30"
    exit
fi
simName=$1

########################################Adding Tacacs support for MiniLink and juniper nodes#####################################
if [[ $simName != *"EPG-JUNIPER"* ]] && ( [[ $simName == *"ML"* ]] || [[ $simName == *"Switch6391"* ]] || [[ $simName == *"FrontHaul-6392"* ]] || [[ $simName == *"JUNIPER"* ]] )
then
starting_nodes=`echo  -e '.open '$simName'\n.select network\n.start -parallel\n' | /netsim/inst/netsim_shell`
echo $starting_nodes
output=`echo -e '.open '$simName'\n.select network\ntacacs_server:operation="view";\n' | /netsim/inst/netsim_shell | grep -vE 'OK|>>'`

if [[ $output == *"No Tacacs Users set on node"* ]]
then
    cat >> Tacacs_$simName.mml << MML
.open $simName
.select network
tacacs_server:operation="add",user="centralized_system_administrator",pwd="TestPassw0rd",user="centralized_administrator",pwd="TestPassw0rd",user="centralized_operator",pwd="TestPassw0rd";
tacacs_server:operation="view";
.stop -parallel
MML
else
    cat >> Tacacs_$simName.mml << MML
.open $simName
.select network
tacacs_server:operation="view";
.stop -parallel
MML
fi
fi
############################Adding Radius Support for FrontHaul 6020 nodes##########################

if [[ $simName == *"FrontHaul-6020"* ]]
then
starting_nodes=`echo -e '.open '$simName'\n.select network\n.start -parallel\n' | /netsim/inst/netsim_shell`
echo $starting_nodes
output=`echo -e '.open '$simName'\n.select network\nradius_server_user:operation="view";\n' | /netsim/inst/netsim_shell | grep -vE 'OK|>>'`
    if [[ $output == *"No Radius Users set on node"* ]]
    then
        cat >> Tacacs_$simName.mml << MML
.open $simName
.select network
radius_server_user:operation="add",user="RadAdmin",pwd="RadAdmin@12345",user="Admin123",pwd="Admin@12345";
radius_server_user:operation="view";
.stop -parallel
MML
else
    cat >>Tacacs_$simName.mml << MML
.open $simName
.select network
radius_server_user:operation="view";
.stop -parallel
MML
fi
fi

###########################Adding netsim user for sgsn and scef nodes#####################################
if [[ $simName == *"SCEF"* ]] || [[ $simName == *"SGSN"* ]] || [[ $simName == *"5G112"* ]] || [[ $simName == *"5G113"* ]] || [[ $simName == *"5G114"* ]] || [[ $simName == *"5G115"* ]] || [[ $simName == *"5G116"* ]] || [[ $simName == *"5G117"* ]] || [[ $simName == *"5G118"* ]] || [[ $simName == *"CORE119"* ]] || [[ $simName == *"CORE120"* ]] || [[ $simName == *"CORE125"* ]] || [[ $simName == *"5G127"* ]] || [[ $simName == *"CORE128"* ]] || [[ $simName == *"5G129"* ]] || [[ $simName == *"5G130"* ]] || [[ $simName == *"5G131"* ]] || [[ $simName == *"5G132"* ]] || [[ $simName == *"CORE127"* ]] || [[ $simName == *"CORE129"* ]] || [[ $simName == *"5G133"* ]] || [[ $simName == *"5G134"* ]] || [[ $simName == *"CORE135"* ]] || [[ $simName == *"CORE126"* ]] | [[ $simName == *"Yang"* ]]
then
echo "Setting netsim user for sgsn,scef and yang nodes"
cat >> Tacacs_$simName.mml << MML
.open $simName
.select network
.stop -parallel
.setuser netsim netsim
.set save
MML
elif [[ $simName == *"BSC"* ]] || [[ $simName == *"MSC"* ]]
then
  if [[ $simName != *"vBSC"* ]] 
  then
echo "Setting localCOMUser for BSC nodes"
nodeName=`echo -e '.open '$simName'\n.show simnes\n'|~/inst/netsim_shell | grep -i 'LTE BSC' | cut -d ' ' -f1 | tr '\n' ' '`
cat >> Tacacs_$simName.mml << MML
.open $simName
.select $nodeName
.stop -parallel
.setuser LocalCOMUser LocalCOMUser
.set save
MML
fi
fi
###########################Generating backup files for MSC BSC nodes##########################################
simCount=`ls /netsim/netsimdir | grep -E 'BSC|MSC|GSM' | wc -l`
if [[ $simCount -gt 0 ]] && ( [[ $simName == *"BSC"* ]] || [[ $simName == *"MSC"* ]] || [[ $simName == *"GSM"* ]] )
then
echo "Generating backup files for MSC BSC nodes"
check=`echo -e '.showapgbackup -netype MSC-S-SPX \n' | /netsim/inst/netsim_shell | grep -v '>>'`
   if [[ $check == *"Backup not"* ]]
   then
cat >> Tacacs_$simName.mml << MML
.generateapgbackup -netype BSC buinfo 1M ldd1 1M ps 1M rs 1M sdd 1M
.generateapgbackup -netype MSC-BC-IS buinfo 1M ldd1 1M ps 1M rs 1M
.generateapgbackup -netype MSC-S-SPX buinfo 1M ldd1 1M ps 1M rs 1M sdd 1M
MML
   else
cat >> Tacacs_$simName.mml << MML
.showapgbackup -netype BSC
.showapgbackup -netype MSC-BC-IS
.showapgbackup -netype MSC-S-SPX
MML
   fi
fi
/netsim/inst/netsim_shell < Tacacs_$simName.mml
