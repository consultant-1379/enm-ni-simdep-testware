#!/bin/sh
##############################################################################
#     File Name    : loadConfig.sh
#
#     Author       : Nainesha Chilakala
#
#     Description : The script sets loadconfigurations and starts simulation
#
#     Date Created : 29 January 2019
#
#     Syntax : ./loadConfig.sh deploymentType
#
#     Parameters : <deploymentType> type of deployment
#
#     Example :  ./loadConfig.sh mediumDeployment
#
##############################################################################
##############################################################################
#Script Usage#
########################################################################
usage (){

    echo "Usage  : ./loadConfig.sh deploymentType "

    echo "Example: ./loadConfig.sh mediumDeployment "

}
########################################################################
#Checking the user
########################################################################

user=`whoami`
if [[ $user != "root" ]]
then
    echo "ERROR: Only root user can execute this script"
    exit 1
fi

#######################################################################
#To check commandline arguments#
########################################################################
if [ $# -ne 1 ]
then
    usage
    exit 1
fi
########################################################################

deployment=$1
TLSCheckFile="/netsim/simdepContents/SimsTLSCheck.txt"
certsCheckFile="/netsim/simdepContents/SimsCertsCheck.txt"

if [[ -f "$TLSCheckFile" && -s "$TLSCheckFile" ]]
then
  echo "INFO: Latest TLS/SL2 configuration was present on nodes"
  TLS_set=0
else
  echo "INFO: Latest TLS/SL2 configurations was not there on nodes"
  TLS_set=1
fi

if [[ $TLS_set == 1 ]]
then
    echo "INFO: New certs are not installed on server"
    certs_set=1
elif [[ ! ( -f "$certsCheckFile" && -s "$certsCheckFile" ) ]]
then
    echo "INFO: New certs are not installed on server"
    certs_set=1
else
    echo "INFO: New certs are installed on server"
    certs_set=0
fi

if [[ -f MML.mml ]]
then
   rm -rf MML.mml
fi

touch MML.mml

if [[ $? -ne 0 ]]
then
   echo "ERROR: Unbale to create MML.mml file"
   echo "INFO: Retry for creating MML.mml file"
   touch MML.mml
fi

chmod 777 MML.mml

Permission=`ls -lrtha | grep 'MML.mml' | awk '{print $1}'`
if [[ ${Permission} == "-rwxrwxrwx" ]]
then
    echo "INFO: MML.mml file has $Permission permissions"
else
    echo "ERROR: MML.mml file don't have 777 permissions..It has $permission permissions"
    echo "INFO: Changing MML.mml file permissions"
    chmod 777 MML.mml
fi

su netsim -c "/var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/SW_createPort.pl 159.107.220.96"

rm -rf MML.mml

if [[ $? -ne 0 ]]
then
    echo "ERROR: Unable to remove MML file"
    echo "INFO: Retry for removing the MML file"
    rm -rf MML.mml
fi

SIMSLIST=`echo ".show simulations" | su netsim -c /netsim/inst/netsim_shell | grep -vE 'OK|NE|>>' | grep -vE "default|.zip"`
NRM=`cat /netsim/simdepContents/NRMDetails | head -1 | awk -F '=' '{print $2}'`
Network=`cat /netsim/simdepContents/NRMDetails | grep "RolloutNetwork" | awk -F '=' '{print $2}'`
pathSpecifier="yes"

if [[ $NRM == "NSS" ]]
then
  switchToRv=no
else
  switchToRv=yes
fi

if [[ -d /var/simnet/softwareUpdate ]]
then
   rm -rf /var/simnet/softwareUpdate
fi

mkdir /var/simnet/softwareUpdate

if [[ $? -ne 0 ]]
then
    mkdir /var/simnet/softwareUpdate
fi


chmod 777 /var/simnet/softwareUpdate

if [[ $? -ne 0 ]]
then
    chmod 777 /var/simnet/softwareUpdate
fi

for simName in ${SIMSLIST[@]}
do
   echo "INFO: Fetching info for $simName"
   #su netsim -c "python /var/simnet/enm-ni-simdep/scripts/simdep/bin/readData.py $simName"
   mkdir /var/simnet/softwareUpdate/$simName
   if [[ $? -ne 0 ]]
   then
       mkdir /var/simnet/softwareUpdate/$simName
   fi

   mkdir /var/simnet/softwareUpdate/$simName/dat
    
   if [[ $? -ne 0 ]]
   then
       mkdir /var/simnet/softwareUpdate/$simName/dat
   fi   

   touch MML.mml 
   if [[ $? -ne 0 ]]
   then
       touch MML.mml
   fi

   touch /var/simnet/softwareUpdate/$simName/dat/dumpNeName.txt
   if [[ $? -ne 0 ]]
   then
        touch /var/simnet/softwareUpdate/$simName/dat/dumpNeName.txt
   fi

   touch /var/simnet/softwareUpdate/$simName/dat/dumpNeType.txt
   if [[ $? -ne 0 ]]
   then
       touch /var/simnet/softwareUpdate/$simName/dat/dumpNeType.txt
   fi

   touch /var/simnet/softwareUpdate/$simName/dat/listNeName.txt
   if [[ $? -ne 0 ]]
   then
       touch /var/simnet/softwareUpdate/$simName/dat/listNeName.txt
   fi

   touch /var/simnet/softwareUpdate/$simName/dat/listNeType.txt
   if [[ $? -ne 0 ]]
   then
      touch /var/simnet/softwareUpdate/$simName/dat/listNeType.txt
   fi

   chmod 777 MML.mml 
   if [[ $? -ne 0 ]]
   then
       chmod 777 MML.mml
   fi
   
   Permission=`ls -lrtha | grep 'MML.mml' | awk '{print $1}'`
   if [[ ${Permission} == "-rwxrwxrwx" ]]
   then
       echo "INFO: MML.mml file has $Permission permissions"
   else
       echo "ERROR: MML.mml file don't have 777 permissions..It has $permission permissions"
       echo "INFO: Changing MML.mml file permissions"
       chmod 777 MML.mml
   fi
 
   chmod 777 /var/simnet/softwareUpdate/$simName/dat/dumpNeName.txt
   if [[ $? -ne 0 ]]
   then
       chmod 777  /var/simnet/softwareUpdate/$simName/dat/dumpNeName.txt
   fi

   chmod 777 /var/simnet/softwareUpdate/$simName/dat/dumpNeType.txt
   if [[ $? -ne 0 ]]
   then
       chmod 777 /var/simnet/softwareUpdate/$simName/dat/dumpNeType.txt
   fi

   chmod 777 /var/simnet/softwareUpdate/$simName/dat/listNeName.txt
   if [[ $? -ne 0 ]]
   then
       chmod 777 /var/simnet/softwareUpdate/$simName/dat/listNeName.txt
   fi

   chmod 777 /var/simnet/softwareUpdate/$simName/dat/listNeType.txt
   if [[ $? -ne 0 ]]
   then
      chmod 777 /var/simnet/softwareUpdate/$simName/dat/listNeType.txt
   fi

   su netsim -c "/var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/readData.pl $simName.zip > /tmp/${simName}_data.log"

   rm -rf MML.mml
   if [[ $? -ne 0 ]]
   then
       rm -rf MML.mml
   fi

   if [[ ! -f /var/simnet/softwareUpdate/$simName/dat/dumpNeType.txt ]]
   then
       echo "Netype file was not present for $simName"
       exit 1
   fi
   neType=`cat /var/simnet/softwareUpdate/$simName/dat/dumpNeType.txt | sort | uniq | grep -v ".s" | tr '\n' ':' | sed 's/^://g'`

   if [[ -z $neType ]]
   then
        rm -rf MML.mml /var/simnet/softwareUpdate/$simName/dat/dumpNeName.txt /var/simnet/softwareUpdate/$simName/dat/dumpNeType.txt
	touch MML.mml 
	if [[ $? -ne 0 ]]
        then
       	     touch MML.mml
        fi

        touch /var/simnet/softwareUpdate/$simName/dat/dumpNeName.txt
        if [[ $? -ne 0 ]]
        then
              touch /var/simnet/softwareUpdate/$simName/dat/dumpNeName.txt
        fi

	touch /var/simnet/softwareUpdate/$simName/dat/dumpNeType.txt
	if [[ $? -ne 0 ]]
	then
	       touch /var/simnet/softwareUpdate/$simName/dat/dumpNeType.txt
	fi

        touch /var/simnet/softwareUpdate/$simName/dat/listNeName.txt
        if [[ $? -ne 0 ]]
        then
              touch /var/simnet/softwareUpdate/$simName/dat/listNeName.txt
        fi

        touch /var/simnet/softwareUpdate/$simName/dat/listNeType.txt
        if [[ $? -ne 0 ]]
        then
               touch /var/simnet/softwareUpdate/$simName/dat/listNeType.txt
        fi

	chmod 777 MML.mml 
	if [[ $? -ne 0 ]]
	then
 		chmod 777 MML.mml
   	fi
   
	chmod 777 /var/simnet/softwareUpdate/$simName/dat/dumpNeName.txt
	if [[ $? -ne 0 ]]
	then
       		chmod 777  /var/simnet/softwareUpdate/$simName/dat/dumpNeName.txt
	fi

	chmod 777 /var/simnet/softwareUpdate/$simName/dat/dumpNeType.txt
	if [[ $? -ne 0 ]]
	then
      		 chmod 777 /var/simnet/softwareUpdate/$simName/dat/dumpNeType.txt
	fi

        chmod 777 /var/simnet/softwareUpdate/$simName/dat/listNeName.txt
        if [[ $? -ne 0 ]]
        then
              chmod 777 /var/simnet/softwareUpdate/$simName/dat/listNeName.txt
        fi

        chmod 777 /var/simnet/softwareUpdate/$simName/dat/listNeType.txt
        if [[ $? -ne 0 ]]
        then
               chmod 777 /var/simnet/softwareUpdate/$simName/dat/listNeType.txt
        fi

        su netsim -c "/var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/readData.pl $simName.zip > /tmp/${simName}_data.log"
	rm -rf MML.mml
	if [[ $? -ne 0 ]]
	then
	       rm -rf MML.mml
	fi
   	neType=`cat /var/simnet/softwareUpdate/${simName}/dat/dumpNeType.txt | sort | uniq | grep -v ".s" | tr '\n' ':' | sed 's/^://g'`
   fi
   echo " INFO: starting $simName neType=$neType"

   if [[ $TLS_set == 1 || $certs_set == 1 ]]
   then
      echo "INFO: Changing TLS configuration for $simName"
      mkdir /var/simnet/softwareUpdate/${simName}/bin
      if [[ $? -ne 0 ]]
      then
           echo "ERROR: Creating bin folder failed retrying "
           mkdir /var/simnet/softwareUpdate/${simName}/bin
      fi

      cp -r /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/* /var/simnet/softwareUpdate/${simName}/bin/
      if [[ $? -ne 0 ]]
      then
           echo "ERROR: Copy of simdep scripts failed retrying "
	   cp -r /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/* /var/simnet/softwareUpdate/${simName}/bin/
      fi
      
      mkdir /var/simnet/softwareUpdate/${simName}/logs
      if [[ $? -ne 0 ]]
      then
           echo "ERROR: Creating logs folder failed retrying "
           mkdir /var/simnet/softwareUpdate/${simName}/logs
      fi

      cp -r /var/simnet/enm-ni-simdep/scripts/simdep/certs /var/simnet/softwareUpdate/${simName}/
      if [[ $? -ne 0 ]]
      then
           echo "ERROR: Copying certs failed retrying "
           cp -r /var/simnet/enm-ni-simdep/scripts/simdep/certs /var/simnet/softwareUpdate/${simName}/
      fi

      cp -r /var/simnet/enm-ni-simdep/scripts/simdep/conf /var/simnet/softwareUpdate/${simName}/
      if [[ $? -ne 0 ]]
      then
           echo "ERROR: Copying conf folder failed retrying "
           cp -r /var/simnet/enm-ni-simdep/scripts/simdep/conf /var/simnet/softwareUpdate/${simName}/
      fi

      chmod -R 777 /var/simnet/softwareUpdate/${simName}/
      if [[ $? -ne 0 ]]
      then
           echo "ERROR: Unable to change permissions of /var/simnet/softwareUpdate/${simName}/"
	   chmod 777 /var/simnet/softwareUpdate/${simName}/
       fi
       workingDir="/var/simnet/softwareUpdate/${simName}"
       echo "$simName" > ${workingDir}/dat/listSimulation.txt
       echo "INFO: Running invokeSeurity.pl script for $simName"
       /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/invokeSecurity.pl VM `hostname` root shroot $workingDir on on $switchToRv
       echo "INFO: Applied latest TLS versions in $simName"
       echo "INFO: Applied latest TLS versions in $simName" >> $TLSCheckFile
       echo "INFO: Applied new certs on $simName nodes"
       echo "INFO: Apllied new certs on $simName nodes" >> $certsCheckFile
   fi

   touch /var/${simName}_start.mml
   if [[ $? -ne 0 ]]
   then
       touch /var/${simName}_start.mml
   fi

   touch /var/Tacacs_${simName}.mml
   if [[ $? -ne 0 ]]
   then
        touch /var/Tacacs_${simName}.mml
   fi

   chmod 777 /var/${simName}_start.mml 
   if [[ $? -ne 0 ]]
   then
       chmod 777 /var/${simName}_start.mml
   fi

   chmod 777 /var/Tacacs_${simName}.mml 
   if [[ $? -ne 0 ]]
   then
        chmod 777 /var/Tacacs_${simName}.mml
   fi
   
   if [[  ${simName} == *"SGSN"* ]]
   then 
     if [[ ! -d /pms_tmpfs/${simName} ]]
     then
        echo -e "Running set_tmpfs.sh for SGSN"
        su netsim -c "/var/simnet/enm-ni-simdep/scripts/simdep/utils/netsim/set_tmpfs.sh $simName"
      fi
   fi   
   su netsim -c "/var/simnet/enm-ni-simdep/scripts/simdep/utils/netsim/startNes.pl -simName $simName -all -neTypesFull \"$neType\" -deploymentType $deployment -rv $switchToRv"
   
   if [[ $switchToRv == "yes" ]]
   then
       echo "creating arne for $simName"
       su netsim -c "python /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/arne_generation.py $simName $pathSpecifier"
   fi
done

rm -rf /var/*.mml
rm -rf MML.mml
################################################saveing loadbalance ################################
echo "INFO: Saving load balance"

   touch save_MML.mml
   if [[ $? -ne 0 ]]
   then
      touch save_MML.mml
   fi

   chmod 777 save_MML.mml
   if [[ $? -ne 0 ]]
   then
      chmod 777 save_MML.mml
   fi
   
   Permission=`ls -lrtha | grep 'save_MML.mml' | awk '{print $1}'`
   if [[ ${Permission} == "-rwxrwxrwx" ]]
   then
       echo "INFO: MML.mml file has $Permission permissions"
   else
       echo "ERROR: MML.mml file don't have 777 permissions..It has $permission permissions"
       echo "INFO: Changing MML.mml file permissions"
       chmod 777 MML.mml
   fi
   
   output=`su netsim -c "sh /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/saveLoadBalance.sh"`
   echo "$output"
   echo "$output" > /var/simnet/saveLoadBalance_output.log
   
rm -rf save_MML.mml

#######################Restarting nodes if stopped nodes are present##################################

stoppedNodeCount=`su netsim -c "echo '.show allsimnes' | /netsim/inst/netsim_shell | grep -c not"`

if [[ ${stoppedNodeCount} != 0 ]]
then
    echo "ERROR: Few nodes are not started Restarting those nodes"
    echo "INFO: Excuting start_stoppedNodes.sh to start the nodes in stop state"
    touch stoppedNodes.tmp ipv4Pid.tmp ipv6Pid.tmp;chmod 777 stoppedNodes.tmp ipv4Pid.tmp ipv6Pid.tmp
    su netsim -c "sh /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/start_stoppedNodes.sh"
    rm -f stoppedNodes.tmp ipv4Pid.tmp ipv6Pid.tmp /netsim/*_stoppedNodes.tmp
fi

###########################################Copying start_all_simne_parallel.sh script #################

if [[ $Network == "rvModuleLRAN_Small_NRM4.1" ]] || [[ $Network == "rvModuleWRAN_Small_NRM4.1" ]] || [[ $Network == "rvModuleCore_Small_NRM4.1" ]] || [[ $Network == "rvModuleTransport_Small_NRM4.1" ]] || [[ $Network == *"rvModuleNRM5_5K_"* ]] || [[ $Network == "rvModuleTransport_300Nodes_NRM6" ]]
then
    echo "Coping start_all_simne_parallel.sh file to inst/bin path for $Network"
    cp /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/start_all_simne_parallel.sh /netsim/inst/bin
    rm -rf /netsim/inst/bin/start_all_simne.sh
    mv /netsim/inst/bin/start_all_simne_parallel.sh /netsim/inst/bin/start_all_simne.sh
fi

rm -rf /tmp/*_data.log

