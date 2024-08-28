#!/bin/sh
##############################################################################
#     File Name    : setSecurit.sh
#
#     Author       : Nainesha Chilakala
#
#     Description : The script sets security on simulations
#
#     Date Created : 14 June 2022
#
#     Syntax : ./setSecurity.sh
#
########################################################################
#Checking the user
########################################################################

user=`whoami`
if [[ $user != "root" ]]
then
    echo "ERROR: Only root user can execute this script"
    exit 1
fi

SIMSLIST=`echo ".show simulations" | su netsim -c /netsim/inst/netsim_shell | grep -vE 'OK|NE|>>' | grep -vE "default|.zip"`
NRM=`cat /netsim/simdepContents/NRMDetails | head -1 | awk -F '=' '{print $2}'`
Network=`cat /netsim/simdepContents/NRMDetails | grep "RolloutNetwork" | awk -F '=' '{print $2}'`

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
	   chmod -R 777 /var/simnet/softwareUpdate/${simName}/
       fi
       workingDir="/var/simnet/softwareUpdate/${simName}"
       echo "$simName" > ${workingDir}/dat/listSimulation.txt
       echo "INFO: Running invokeSeurity.pl script for $simName"
       /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/invokeSecurity.pl VM `hostname` root shroot $workingDir on on $switchToRv
       echo "INFO: Applied latest TLS versions in $simName"
done
