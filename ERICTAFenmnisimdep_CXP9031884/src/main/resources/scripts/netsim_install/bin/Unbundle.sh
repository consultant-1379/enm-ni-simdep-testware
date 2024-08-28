#!/bin/sh
# $Id: Unbundle.sh,v 1.11 2012/09/17 14:53:39 ethanl Exp $
# Installation of zipped product (1_19089-FAB....))
# It is assumed that the product contains a script ./Install
# The parameters to this script are transfered to the ./Install script
# If no parameters are given ./Install will be called like this
# > ./Install quick
#


function message()
{

    local MESSAGE="$1"
    local TYPE=$2
    COLOR=$white
    if [[ "$TYPE" == "ERROR" ]]
    then
        COLOR=$red
        MESSAGE="$1 in module Unbundle.sh "
    fi
    if [[ "$TYPE" == "LINE" ]]
    then
        COLOR=$magenta
    fi
    if [[ "$TYPE" == "WARNING" ]]
    then
        COLOR=$yellow
    fi
    if [[ "$TYPE" == "SUMMARY" ]]
    then
        COLOR=$green
    fi
    if [[ "$TYPE" == "SCRIPT" ]]
    then
        COLOR=$cyan
    fi
    if [[ `echo "$MESSAGE" | egrep "^INFO:|^ERROR:|^WARNING:"` ]]
    then
        local FORMATTED_DATE="`date | awk '{print $2 "_" $3}'`"
        local FORMATTED_TIME="`date | awk '{print $4}'`"
        MESSAGE="[$FORMATTED_DATE $FORMATTED_TIME] $MESSAGE"
    fi
    echo -en $COLOR
    echo -en "$MESSAGE \n" 2>&1 | tee -a $logFile
    echo -en $white
}

OTHERFILES=`ls | egrep -v ".zip$|.tar.Z$|Unbundle.sh|testmodedir"`
if [ "$OTHERFILES" != "" ];
then
    message "ERROR: ======================= ERROR!!! ====================================" ERROR
    message "ERROR: Unbundle.sh can only be called when installing on an empty directory." ERROR
    message "ERROR: ======================= ERROR!!! ====================================" ERROR
    exit 1
fi
LOADMODULES=`ls *_19089* 2> /dev/null | wc -l`
if [ $LOADMODULES -ne 1 ] ; then
    message "ERROR: ======================= ERROR!!! =============================" ERROR
    message "ERROR: Only one load module (1_19089-...zip) allowed" ERROR
    message "ERROR: now you have $LOADMODULES load modules" ERROR
    message "ERROR: ======================= ERROR!!! =============================" ERROR
    exit 1
fi

# install the 3rd party packages
install_packages() {
    OS_VERSION=`awk '/VERSION/ {print $3}' /etc/SuSE-release 2>/dev/null`
    case $OS_VERSION in
        10) cd 3pp_config/packages/suse10_x64
            rpm -U *.rpm
            ;;
        11) cd 3pp_config/packages/suse11_x64
            rpm -U *.rpm
            ;;
        *)  cd 3pp_config/packages/solaris
            for gz in *.gz
            do
                gzip -d $gz
                pkg=${gz/.gz/}
                # TODO: only install if the package is not already installed, so
                # use something like this
                # pkgname=`head -2 $pkg | tail -1 | cut -f1 -d" "`
                # pkginfo -q $pkgname || pkgadd -d $pkg
                # TODO: use an admin file so pkgadd won't prompt the user.
                # Beware that in the NETSim labs we don't need these packages!
                pkgadd -d $pkg
            done
            ;;
    esac
    cd -
}


SYSCTL=/etc/sysctl.conf

configure_kernel_parameter() {
    param="$1"
    value="$2"

    if grep "$param" $SYSCTL >/dev/null ; then
        sed -i "s/^$param[^a-zA-Z0-9].*$/$param = $value/" $SYSCTL
    else
        echo "$param = $value" >>$SYSCTL
    fi
}

# Enable core file generation, set reverse path filtering to 2, so
# asymmetric routing will work
configure_kernel_parameters() {
    OS_TYPE=`uname -s`
    case $OS_TYPE in
        Linux)
            configure_kernel_parameter kernel.core_pattern "core.%e.%p.%t"
            configure_kernel_parameter kernel.core_uses_pid 1
            configure_kernel_parameter net.ipv4.conf.all.rp_filter 2
            sysctl -e -p $SYSCTL
            break;;
        SunOS)
            coreadm -i core.%f.%p.%t
            break;;
        *)
            echo "Unsupported operating system!"
            exit 1
            break;;
    esac
}

if [ "$1" = "" ] ; then
   QUICK=quick
else
   QUICK=$1
fi

# The reason why I use echo instead of cat <<EOF to create the script
# is that there are variables there and they would be replaced by their
# value now, not when the script runs.
UNZIP_NETSIM_SH=unzip_netsim.$$.sh
echo ' #!/bin/bash
if [ "$1" = "isolated" ] ; then
   mkdir inst
   mv *.zip Unbundle.sh inst/
   cd inst/
fi

echo Extracting the FAB zip file:
echo 000000 > status.tmp # So the file can be rewritten if if device full
UNZIP="/usr/bin/unzip *_19089-*.zip"
echo $UNZIP
($UNZIP ; echo $? > status.tmp) | grep creating:
STATUS=`cat status.tmp`
if [ $STATUS -ne 0 ] ; then
    echo "======================= ERROR!!! ============================="
    echo ERROR: $UNZIP failed with status $STATUS
    cp Unbundle.sh tmp.tmp
    echo "======================= ERROR!!! ============================="
    exit $STATUS
fi
rm status.tmp
mkdir -p saveinstallation
#mv *_19089-*.zip saveinstallation
rm -f *_19089-*.zip
' >$UNZIP_NETSIM_SH

INSTALL_NETSIM_SH=install_netsim.$$.sh
echo '#!/bin/bash
if [ "$4" = "isolated" ] ; then
   cd inst/
fi
echo ./Install $@
./Install $@
#mv ./Unbundle.sh saveinstallation
rm -f ./Unbundle.sh
' >$INSTALL_NETSIM_SH

ADD_LOGS_SH=addLogs.$$.sh
echo '#!/bin/sh
file=`ls /netsim/simdepContents | grep .content`
echo "$file"
cd /netsim/inst/
if [[ "$file" =~ "Simnet_15K" || "$file" =~ "Simnet_1_8K" || "$file" =~ "nssModule_RFA250" ]] ; then
   echo `pwd`
   echo -e "Backuping the prmn and ebin files for RV networks in /netsim/RV_prmn_and_ebin_BackUpFiles folder"
   if [ -d /netsim/RV_prmn_and_ebin_BackUpFiles ]
   then
      chmod 777 /netsim/RV_prmn_and_ebin_BackUpFiles
      rm -rf /netsim/RV_prmn_and_ebin_BackUpFiles/*
      /bin/cp -rf netsimbase/inst/netsimprmn netsimbase/inst/prmnresponse netsimbase/simulator/ebin/ netsimwcdma/mmlsim_wcdma/common/cs2/nh/ebin/ SSH/ssh_server/ebin/ mmlsim_corba/iiop/ebin/ netconf/protocols/ebin/ netsimbase/network_protocols/ebin/ -t /netsim/RV_prmn_and_ebin_BackUpFiles
   else
      mkdir /netsim/RV_prmn_and_ebin_BackUpFiles
      /bin/cp -rf netsimbase/inst/netsimprmn netsimbase/inst/prmnresponse netsimbase/simulator/ebin/ netsimwcdma/mmlsim_wcdma/common/cs2/nh/ebin/ SSH/ssh_server/ebin/ mmlsim_corba/iiop/ebin/ netconf/protocols/ebin/ netsimbase/network_protocols/ebin/ -t /netsim/RV_prmn_and_ebin_BackUpFiles
   fi
   echo -e "########Copying Files##########" 
   cd /netsim/inst/
   /bin/cp -rf pstu/ebin/netsimprmn netsimbase/inst/netsimprmn
   /bin/cp -rf pstu/ebin/prmnresponse netsimbase/inst/prmnresponse
   /bin/cp -rf pstu/ebin/erlcommand.beam netsimbase/simulator/ebin/
   /bin/cp -rf pstu/ebin/cs_notification_sender.beam netsimwcdma/mmlsim_wcdma/common/cs2/nh/ebin/
   /bin/cp -rf pstu/ebin/ne_sshd.beam SSH/ssh_server/ebin/
   /bin/cp -rf pstu/ebin/netsimiiop.beam mmlsim_corba/iiop/ebin/
   /bin/cp -rf pstu/ebin/ns_ssh_netconfd.beam netconf/protocols/ebin/
   /bin/cp -rf pstu/ebin/ns_tls_conn.beam netsimbase/network_protocols/ebin/

   chmod a+x netsimbase/inst/prmnresponse netsimbase/inst/netsimprmn netsimbase/simulator/ebin/erlcommand.beam
else
   echo `pwd`
   echo -e "Backuping the prmn and ebin files in /netsim/inst/pstu/ebin folder"
   if [ -d /netsim/pstu_ebin_BackUp ]
   then
      chmod 777 /netsim/pstu_ebin_BackUp
      rm -rf /netsim/pstu_ebin_BackUp/*
      /bin/cp -rf pstu/ebin/netsimprmn pstu/ebin/prmnresponse pstu/ebin/erlcommand.beam pstu/ebin/cs_notification_sender.beam pstu/ebin/ne_sshd.beam pstu/ebin/netsimiiop.beam pstu/ebin/ns_ssh_netconfd.beam pstu/ebin/ns_tls_conn.beam /netsim/pstu_ebin_BackUp/
   else
      mkdir /netsim/pstu_ebin_BackUp
      /bin/cp -rf pstu/ebin/netsimprmn pstu/ebin/prmnresponse pstu/ebin/erlcommand.beam pstu/ebin/cs_notification_sender.beam pstu/ebin/ne_sshd.beam pstu/ebin/netsimiiop.beam pstu/ebin/ns_ssh_netconfd.beam pstu/ebin/ns_tls_conn.beam /netsim/pstu_ebin_BackUp/
   fi
fi
 rm -rf pstu/ebin/netsimprmn
 rm -rf pstu/ebin/prmnresponse
 rm -rf pstu/ebin/erlcommand.beam
 rm -rf pstu/ebin/cs_notification_sender.beam
 rm -rf pstu/ebin/ne_sshd.beam
 rm -rf pstu/ebin/netsimiiop.beam
 rm -rf pstu/ebin/ns_ssh_netconfd.beam
 rm -rf pstu/ebin/ns_tls_conn.beam
' >$ADD_LOGS_SH

chmod a+x $UNZIP_NETSIM_SH
chmod a+x $INSTALL_NETSIM_SH
chmod a+x $ADD_LOGS_SH
trap "rm -f $INSTALL_NETSIM_SH $UNZIP_NETSIM_SH $ADD_LOGS_SH" EXIT TERM
if [ "$UID" = "0" ] ; then
    # we're root. If there's a netsim user, let's execute most of the install
    # as netsim (as it used to be) and install the 3rd party packages as
    # root. Also execute setup_fd_server.sh after the install.
    if su netsim -c id >/dev/null 2>/dev/null; then
        # there's a netsim user
        if [[ $? -ne 0 ]]
        then
            message "ERROR: Something went wrong in switching users" ERROR
            exit 205
        fi
        su netsim -c "./$UNZIP_NETSIM_SH $4" 2>&1 |tee -a $logFile
        SUTEST=${PIPESTATUS[0]}
        echo "exit code : ${SUTEST}"
        if [[ ${SUTEST} -ne 0 ]]
        then
            message "ERROR: Something went wrong with UNZIP_NETSIM_SH, check output above " ERROR
            exit 205
        fi
        install_packages
        configure_kernel_parameters
        cd $PWD; ./$ADD_LOGS_SH 2>&1 |tee -a $logFile
        # the simple su doesn't work here, because on Solaris the LOGNAME
        # variable is still "root" and that breaks stuff. I have no idea
        # why did it work on Linux though.
        su - netsim -c "cd $PWD; ./$INSTALL_NETSIM_SH $QUICK $2 $3 $4 $5" 2>&1 |tee -a $logFile
        if [[ ${PIPESTATUS[0]} -ne 0 ]]
        then
            message "ERROR: Something went wrong with INSTALL_NETSIM_SH, check output above " ERROR
            exit 205
        fi
        bin/setup_fd_server.sh 2>&1 |tee -a $logFile
        if [[ ${PIPESTATUS[0]} -ne 0 ]]
        then
            message "ERROR: Error in setup_fd_server.sh" ERROR
            exit 207
        fi
    else
        message "ERROR:======================= ERROR!!! =====================" ERROR
        message "ERROR: YOU CANNOT INSTALL AS ROOT IF THERE'S NO NETSIM USER!" ERROR
        message "ERROR:======================= ERROR!!! =====================" ERROR
        exit 1
    fi
else
    # we're not root, just a mere mortal
    ./$UNZIP_NETSIM_SH $4 2>&1 |tee -a $logFile
    if [[ ${PIPESTATUS[0]} -ne 0 ]]
    then
        message "ERROR: Error in Unzip_netsim.sh. Possibly the downloaded or copied zip is corrupted" ERROR
        exit 207
    fi
    cd $PWD; ./$ADD_LOGS_SH 2>&1 |tee -a $logFile
    ./$INSTALL_NETSIM_SH $QUICK $2 $3 $4 $5 2>&1 |tee -a $logFile
    if [[ ${PIPESTATUS[0]} -ne 0 ]]
    then
        message "ERROR: Error in Install_Netsim_sh" ERROR
        exit 207
    fi
fi


