#!/bin/bash
# Created by  : Harish Dunga
# Created on  : 2016.12.27
# File name   : setElementManager.sh

PWD=`dirname "$0"`

#if [ -f $PWD/../conf/conf.txt ]
#then
#   source $PWD/../conf/conf.txt
#else
#   echo "ERROR:conf.txt doesn't exist"
#   exit 1
#fi

if [ "$#" -ne 5  ]; then
    cat << EOF
Help:
    Adds Element manager files in LTE simulations with ERBS nodes

Usage:
   $0 <sim_name> <vmStartNe> <vmEndNe> <numOfVappNes> <server type>

    where:
       <sim_name>: specifies simulation name
       <vmStartNe>: The first allocated node in VM for EM support
       <vmEndNe>: The last allocated node in VM for EM support
       <numOfVappNes>: Number of nodes to be set with EM support on Vapp
       <server type>: specifies server type VM or VAPP
EOF
    exit 1
fi

# Params
SIM=$1
vmStartNe=$2
vmEndNe=$3
numOfVappNes=$4
SERVER_TYPE=$5

PWD=`pwd`
SCRIPT_NAME=$(basename "$0")
LOGFILE=$PWD/$SCRIPT_NAME.log
NETSIMDIR="/netsim/netsim_dbdir/simdir/netsim/netsimdir/"
SIMDIR="/netsim/netsimdir/$SIM"
#EM_FILE="https://arm901-eiffel004.athtem.eei.ericsson.se:8443/nexus/content/repositories/nss-releases/com/ericsson/nss/AMOS/cppem/1.0.2/cppem-1.0.2.tar"
EM_FILE="/netsim/inst/netsimwcdma/cppem.tar"
FILEPATH=$NETSIMDIR$SIM
simNes=`echo ".show simnes" | $HOME/inst/netsim_pipe -sim $SIM | cut -d ' ' -f 1 | tail -n+3 | sed '$d'`
nes=(${simNes//:/})
NUMOFSIMNES="${#nes[@]}"
rm -rf $PWD/$SCRIPT_NAME.log
cd $FILEPATH
if [ $? != 0 ]; then
    echo "ERROR: Cannot open the $SIM directory" | tee -a $LOGFILE
fi
if [ $NUMOFSIMNES -lt "5" ]; then
    NUMOFVAPPNES=$NUMOFSIMNES
else
    NUMOFVAPPNES=5
fi
selectedNes=" "
if [ "$SERVER_TYPE" == "1.8K" ] || [ "$SERVER_TYPE" == "VAPP" ]; then
    for (( i=0 ; i < $numOfVappNes ; i++ )) do
        selectedNes=$selectedNes"${nes[$i]} "
    done
elif [ "$SERVER_TYPE" == "VM" ]; then
    if [ "$NUMOFSIMNES" -ge "$vmStartNe" ] && [ "$NUMOFSIMNES" -ge "$vmEndNe" ]; then
        selectedNes=${nes[vmStartNe - 1]}" "${nes[vmEndNe - 1]}
    else
        echo "INFO: The sim $SIM does not have nodes for EM Support. No EM support will be applied" | tee -a $LOGFILE
        exit 0
    fi
else
    echo "ERROR: Please mention the proper Server Type " | tee -a $LOGFILE
    exit -1
fi
cd $SIMDIR/user_cmds/
#if [[ $INSTALL_TYPE != "offline" ]]
#then
#   curl -o cppem.tar $EM_FILE 2>&1
#   if [ $? != 0 ]; then
#     echo "ERROR: Failed to get EM File: $EM_FILE " | tee -a $LOGFILE
#     exit -1
#   fi
#else
#   cp /netsim/Extra/cppem.tar .
#fi

cp $EM_FILE .

if [[ $? -ne 0 ]]
then
     echo "ERROR: Copy of cppem.tar failed"
     cp $EM_FILE .
else
     echo "INFO: cppem.tar file copied Successfully"
fi

tar -xvf $SIMDIR/user_cmds/cppem.tar -C $SIMDIR/user_cmds/
if [ $? != 0 ]; then
    echo "ERROR: Failed to uncompress the tar file $SIMDIR/user_cmds/cppem.tar" | tee -a $LOGFILE
    exit -1
fi
rm -rf $SIMDIR/user_cmds/cppem.tar
if [ $? != 0 ]; then
    echo "ERROR: Failed to remove the tar file $simDir/user_cmds/cppem.tar" | tee -a $LOGFILE
    exit -1
fi
cd $PWD
cat >>em.mml<<AMOS
.open $SIM
.select $selectedNes
.set ulib $SIMDIR/user_cmds/cppem
.set save
AMOS
if [ $? != 0 ]; then
    echo "ERROR: Failed to create the amos mmlscript" | tee -a $LOGFILE
    exit -1
fi
/netsim/inst/netsim_shell < $PWD/em.mml
if [ $? != 0 ]; then
    echo "ERROR: Failed to execute the amos mmlscript" | tee -a $LOGFILE
    exit -1
fi
rm -rf $PWD/em.mml

