#!/bin/bash
#created by   : Kiran Yakkala
# Created in  : 2015.03.04
##
### VERSION HISTORY
# Ver         : Follow up from gerrit
# Purpose     : To Fetch and install given NETSim Version
# Dependency  : None
# Description : Fetches and installs given NETSim Version
# Date        : 04 Mar 2015
# Who         : Kiran Yakkala


######################################
# Gives usage information
# Arguments:
#   None
# Returns:
#   None
#####################################
function usage_msg()
{
    message "Usage: $0 -m MOUNTPOINT -f yes/no -d yes/no -r release -p yes/no
        -m: absolute path to mount
        -f: yes/no will install netsim forcefully (default yes)
        -d: yes/no It will delete existing Netsim versions (default yes)
        -p: yes/no will installs all verified patches (default yes)
        -l: yes/no installs license (default no)
        -n: portal/nexus/verfied (default verified)
            portal-> Downloads patches from portal
            nexus-> Downloads patches from nexus.
            verfied-> Downloads from netsim patch link
        -s: simulation Version.
            Valid only if nexus mode is yes.
        -e: yes/no (default value is no)
            yes -> downloads netsim and patches from ci portal.
            no ->Downloads netsim from netsim page and patches from either nexus (or) netsim page depending on (-n) value
        -i: online/offline (default online)
            online -> gets netsim and other files from nexus during rollout
            offline -> gets netsim and other files from a specific path in server which were copied to server before rollout
        -r: specifies release of netsim you want to install like R28A, R27J etc... " ERROR
    exit 201
}

#######################################
# Validates whether all the mandatory arguments are passed or not
# Arguments:
#   None
# Returns:
#   None
#######################################
function check_args()
{
    if [[ -z "$MOUNTPOINT" ]]
    then
        # Absolute path this script is in. /home/user/bin
        MOUNTPOINT=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
        message "INFO: MOUNTPOINT set to default that is $MOUNTPOINT " INFO
    elif [[ ! -d $MOUNTPOINT ]]
    then
        message "ERROR: Given mount point $MOUNTPOINT not exists " ERROR
        exit 203
    fi
    if [[ -z "$VERSION" ]]
    then
        message "ERROR: You must say what release to install like (R27J,R28A etc) " ERROR
        usage_msg
    fi
    if [[ -z "$FORCE" ]]
    then
        FORCE="yes"
        message "INFO: default value for f is set to $FORCE  " INFO
    elif [[ "$FORCE" != "yes" && "$FORCE" != "no" ]]
    then
        message "ERROR: Valid values for force(-f) are yes or no " ERROR
        exit 203
    fi
    if [[ -z "$DELETE" ]]
    then
        DELETE="no"
        message "INFO: Default value for d is set to $DELETE " INFO
    elif [[ "$DELETE" != "yes" && "$DELETE" != "no" ]]
    then
        message "ERROR: Valid values for delete(-d) is yes or no " ERROR
        exit 203
    fi
    if [[ -z "$PATCH" ]]
    then
        PATCH="yes"
        message "INFO: Default value for d is set to $PATCH " INFO
    elif [[ "$PATCH" != "yes" && "$PATCH" != "no" ]]
    then
        message "ERROR: Valid values for patch(-p) is yes or no " ERROR
        exit 203
    fi
    if [[ -z "$LICENSE" ]]
    then
        LICENSE="no"
        message "INFO: Default value for l is set to $LICENSE " INFO
    elif [[ "$LICENSE" != "yes" && "$LICENSE" != "no" ]]
    then
        message "ERROR: Valid values for License(-l) is yes or no " ERROR
        exit 203
    fi
    if [[ -z "$PATCHMODE" ]]
    then
        PATCHMODE="verified"
        message "INFO: Default value for patch mode is set to $PATCHMODE " INFO
    elif [[ "$PATCHMODE" != "portal" && "$PATCHMODE" != "nexus" && "$PATCHMODE" != "verified" ]]
    then
        message "ERROR: Valid values Patch mode (-n) is portal or nexus or verified  " ERROR
        exit 203
    fi
    if [[ "$PATCHMODE" == "nexus" ]]
    then
        if [[ -z "$SIMVERSION" ]]
        then
            message "ERROR: SimVersion is not defined. Exiting !!!" ERROR
            exit 203
         fi
    fi
    if [[ -z "$CIPORTAL" ]]
    then
        CIPORTAL="no"
        message "INFO: Default value for ci portal is set to $CIPORTAL " INFO
    elif [[ "$CIPORTAL" != "yes" && "$CIPORTAL" != "no" ]]
    then
        message "ERROR: Valid values ciportal(-e) is yes or no  " ERROR
        exit 203
    fi
    if [[ "$CIPORTAL" == "yes" ]]
    then
        PATCHMODE="portal"
    fi
    if [[ -z "$INSTALLTYPE" ]]
    then
        INSTALLTYPE="online"
        message "INFO: Default value for INSTALLTYPE is set to $INSTALLTYPE " INFO
    fi
}

while getopts "m:r:f:d:p:l:n:s:e:i:" arg
do
    case $arg in
        m) MOUNTPOINT="$OPTARG"
        ;;
        r) VERSION="$OPTARG"
        ;;
        f) FORCE="$OPTARG"
        ;;
        d) DELETE="$OPTARG"
        ;;
        p) PATCH="$OPTARG"
        ;;
        l) LICENSE="$OPTARG"
        ;;
        n) PATCHMODE="$OPTARG"
        ;;
        s) SIMVERSION="$OPTARG"
        ;;
        e) CIPORTAL="$OPTARG"
        ;;
        i) INSTALLTYPE="$OPTARG"
        ;;
        \?) usage_msg
        ;;
    esac
done
function message ()
{

    local MESSAGE="$1"
    local TYPE=$2
    COLOR=$white
    if [[ "$TYPE" == "ERROR" ]]
    then
        COLOR=$red
        MESSAGE="$1 in module install_netsim.sh "
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

function cleanup ()
{
    SCRIPT_EXIT_CODE=$?
    EXIT_REASON="$1"
    trap - INT TERM EXIT

    if [[ $SCRIPT_EXIT_CODE -ne 0 ]]
    then
        message "ERROR: The script exited with exit code $SCRIPT_EXIT_CODE" ERROR
    fi
    if [[ "$EXIT_REASON" != "EXIT" ]]
    then
        message "ERROR: The script didn't exit by itself, it exited with signal $EXIT_REASON" ERROR
    fi
    if [[ ! -z $Flag ]]
    then
        END=`date +%s%N`
        T=`echo "scale=8; ($END - $START) / 1000000000" | bc`
        h=`echo "(($T /3600) % 3600)" | bc`
        m=`echo "(($T / 60) % 60)" | bc`
        s=`echo "($T % 60)" | bc`
        message "INFO: Output log stored to $logFile" INFO
        message "INFO: The output log file is also copied to $COPY_LOGFILE_PATH \n" INFO
        printf "Total Execution Time : %02d hours %02d minutes %.8f seconds \n" $h $m $s  |tee -a $logFile
        copy_logfile
    fi
    # Remove traps again
    trap - TERM INT EXIT
    # Exit
    exit $SCRIPT_EXIT_CODE
}

#######################################
# Veryfies whether argument passed is initialized or not
# Arguments:
#   Variable
# Returns:
#   None
#######################################
function requires_variable ()
{
    local VARTEST=`eval echo \\$$1`
    if [[ -z $VARTEST ]]
    then
        message "ERROR: The variable $1 wasn't set, please check why not " ERROR
        exit 202
    fi
}
##########################################################################################################
# Fetches netsim release link from either ci portal or from netsim portal.
# Arguments: $CIPORTAL, $PORTAL_NETSIM_LIST_PATH, $MOUNTPOINT, $VERSION
# Returns: $NETSIM_RELEASE_LINK
###########################################################################################################
function get_netsim_release_link ()
{
    TEMP_NETSIM_RELEASE_LINK=""
    NETSIM_RELEASE_LINK=""
    CIPORTAL=$1
    PORTAL_NETSIM_LIST_PATH=$2
    MOUNTPOINT=$3
    VERSION=$4

    if [[ "$CIPORTAL" = "yes" ]]
    then
        if [[ -s $PORTAL_NETSIM_LIST_PATH ]]
        then
            TEMP_NETSIM_RELEASE_LINK=`cat $PORTAL_NETSIM_LIST_PATH`
        else
            exit 207
        fi
    else
        TEMP_NETSIM_RELEASE_LINK=`$MOUNTPOINT/getNetsimVersion.pl -t=l -v=1 2>&1`
    fi
    NETSIM_RELEASE_LINK=`echo "$TEMP_NETSIM_RELEASE_LINK" | grep $VERSION`
    if [[ $NETSIM_RELEASE_LINK != *http* ]]
    then
        exit 207
    fi
    echo "$NETSIM_RELEASE_LINK"
}
#######################################
# Fetches Netsim from netsim page or copies from local path
# Arguments:
#   none
# Returns:
#   None
#######################################
function get_zip_netsim()
{
    rm -rf $VAR$NETSIM_DIRECTORY 2>&1 | tee -a $logFile
    if [[ ${PIPESTATUS[0]} -ne 0 ]];
    then
        message "ERROR: Removing the directory $VAR$NETSIM_DIRECTORY failed " ERROR
        exit 206
    fi
    mkdir $VAR$NETSIM_DIRECTORY 2>&1 | tee -a $logFile
    if [[ ${PIPESTATUS[0]} -ne 0 ]]
    then
        message "ERROR: mkdir $VAR$NETSIM_DIRECTORY failed " ERROR
        exit 206
    fi
    cd $VAR$NETSIM_DIRECTORY
    if [[ ${INSTALLTYPE} = "online" ]]
    then
  
       message "INFO: Downloading the zip file from $1 to $VAR$NETSIM_DIRECTORY " INFO
       su - netsim -c "wget -O 1_19089-FAB760956Ux.$VERSION.zip ${1}" 2>&1 | tee -a $logFile
       if [[ ${PIPESTATUS[0]} -ne 0 ]]
       then
           su - netsim -c "wget --no-proxy -O 1_19089-FAB760956Ux.$VERSION.zip ${1}" 2>&1 | tee -a $logFile
           if [[ ${PIPESTATUS[0]} -ne 0 ]]
           then
             message "ERROR: Something went wrong downloading this zip file, check output above " ERROR
             exit 205
           else
              message "INFO: Copying the zip file from /netsim/1_19089-FAB760956Ux.$VERSION.zip to $VAR$NETSIM_DIRECTORY " INFO
              cp /netsim/1_19089-FAB760956Ux.$VERSION.zip $VAR$NETSIM_DIRECTORY 2>&1 | tee -a $logFile
              message "INFO: Removing the zip file from /netsim/1_19089-FAB760956Ux.$VERSION.zip " INFO
              rm -rf /netsim/1_19089-FAB760956Ux.$VERSION.zip | tee -a $logFile
              message "INFO: Copying the zip file from  $VAR$NETSIM_DIRECTORY/1_19089-FAB760956Ux.$VERSION.zip to /netsim/$VERSION/ " INFO
              cp $VAR$NETSIM_DIRECTORY/1_19089-FAB760956Ux.$VERSION.zip /netsim/$VERSION/ 2>&1 | tee -a $logFile
              if [[ ${PIPESTATUS[0]} -ne 0 ]]
              then
                 message "ERROR:Copying the zip file from  $VAR$NETSIM_DIRECTORY to /netsim/$VERSION/ failed " ERROR
                 exit 206
              fi
            fi
        else
            message "INFO: Copying the zip file from /netsim/1_19089-FAB760956Ux.$VERSION.zip to $VAR$NETSIM_DIRECTORY " INFO
            cp /netsim/1_19089-FAB760956Ux.$VERSION.zip $VAR$NETSIM_DIRECTORY 2>&1 | tee -a $logFile
            message "INFO: Removing the zip file from /netsim/1_19089-FAB760956Ux.$VERSION.zip " INFO
            rm -rf /netsim/1_19089-FAB760956Ux.$VERSION.zip | tee -a $logFile
            message "INFO: Copying the zip file from  $VAR$NETSIM_DIRECTORY/1_19089-FAB760956Ux.$VERSION.zip to /netsim/$VERSION/ " INFO
            cp $VAR$NETSIM_DIRECTORY/1_19089-FAB760956Ux.$VERSION.zip /netsim/$VERSION/ 2>&1 | tee -a $logFile
            if [[ ${PIPESTATUS[0]} -ne 0 ]]
            then
                message "ERROR:Copying the zip file from  $VAR$NETSIM_DIRECTORY to /netsim/$VERSION/ failed " ERROR
                exit 206
            fi
         fi
    else
         message "INFO: Copying the zip file from /netsim/1_19089-FAB760956Ux.$VERSION.zip to $VAR$NETSIM_DIRECTORY " INFO
         cp /netsim/1_19089-FAB760956Ux.$VERSION.zip $VAR$NETSIM_DIRECTORY 2>&1 | tee -a $logFile
         message "INFO: Removing the zip file from /netsim/1_19089-FAB760956Ux.$VERSION.zip " INFO
         rm -rf /netsim/1_19089-FAB760956Ux.$VERSION.zip | tee -a $logFile
         message "INFO: Copying the zip file from  $VAR$NETSIM_DIRECTORY/1_19089-FAB760956Ux.$VERSION.zip to /netsim/$VERSION/ " INFO
         cp $VAR$NETSIM_DIRECTORY/1_19089-FAB760956Ux.$VERSION.zip /netsim/$VERSION/ 2>&1 | tee -a $logFile
         if [[ ${PIPESTATUS[0]} -ne 0 ]]
         then
            message "ERROR:Copying the zip file from  $VAR$NETSIM_DIRECTORY to /netsim/$VERSION/ failed " ERROR
            exit 206
         fi
     fi
}
function get_netsim ()
{
    get_zip_netsim $1
    file_size_mb=`du -k "$VAR$NETSIM_DIRECTORY/1_19089-FAB760956Ux.$VERSION.zip" | cut -f1`
    if [[ "$file_size_mb" -le 450000 ]]
    then
        message "INFO:Found Zip at $VAR$NETSIM_DIRECTORY/1_19089-FAB760956Ux.$VERSION.zip, but file size is less than 450MB. Possibly the downloaded or copied zip is corrupted" INFO
        get_zip_netsim $1
    else
        message "INFO: Copying the zip file from  $VAR$NETSIM_DIRECTORY to /netsim/$VERSION/ " INFO
        cp $VAR$NETSIM_DIRECTORY/1_19089-FAB760956Ux.$VERSION.zip /netsim/$VERSION/ 2>&1 | tee -a $logFile
        if [[ ${PIPESTATUS[0]} -ne 0 ]];
        then
            message "ERROR: Copying the zip file from  $VAR$NETSIM_DIRECTORY to /netsim/$VERSION/ failed " ERROR
            exit 206
        fi
    fi
    rm -rf $VAR$NETSIM_DIRECTORY 2>&1 | tee -a $logFile
    if [[ ${PIPESTATUS[0]} -ne 0 ]];
    then
        message "ERROR: Removing the directory $VAR$NETSIM_DIRECTORY failed after copying zip to /netsim/$VERSION/" ERROR
        exit 206
    fi
}

#######################################
# Fethes Netsim from netsim license  or copies from local path
# Arguments:
#   none
# Returns:
#   None
#######################################
function get_license ()
{
    IFS=/
    ary=($1)
    netsim_product=`echo ${ary[4]} | cut -c7-10`
    unset IFS
    NETSIM_LICENSE=`$MOUNTPOINT/getNetsimLicense.pl -t=l -v=$netsim_product 2>&1`
    NETSIM_LICENSE_LINK=`echo "$NETSIM_LICENSE" | grep $netsim_product`
    if [[ $NETSIM_LICENSE_LINK != http* ]]
    then
        echo "$NETSIM_LICENSE" | tee -a $logFile
        message "ERROR: Fetching Netsim License Failed" ERROR
        exit 207
    fi
    message "INFO: Downloading the license zip file from  $NETSIM_LICENSE_LINK /netsim/$VERSION/ " INFO
    cd /netsim/$VERSION/
    su - netsim -c "cd /netsim/$VERSION/;wget ${NETSIM_LICENSE_LINK} 2>&1" | tee -a $logFile
    if [[ ${PIPESTATUS[0]} -ne 0 ]]
    then
        su - netsim -c "cd /netsim/$VERSION/;wget --no-proxy ${NETSIM_LICENSE_LINK} 2>&1" | tee -a $logFile
        if [[ ${PIPESTATUS[0]} -ne 0 ]]
        then
            message "ERROR: Something went wrong getting Netsim license, check output above " ERROR
            exit 205
        fi
    fi
}

##########################################################################################################
# Fetches patches from PORTAL if PATCHMODE is portal.
# Arguments: $PORTAL_PATCH_LIST_PATH, $VERSION
# Returns:
#   None
###########################################################################################################
function get_patches_from_portal ()
{
  PORTAL_PATCH_LIST_PATH=$1
  VERSION=$2
  if [[ $INSTALLTYPE = "online" ]]
  then
    message "Downloading Patches from portal to /netsim/$VERSION\n"
    while read patch; do
        IFS='/' read -ra ADDR <<< "$patch"
        PATCHSTATUS=`su - netsim -c "cd /netsim/$VERSION/;wget -O ${ADDR[11]}.zip $patch" 2>&1`
        message "$PATCHSTATUS" INFO
        if [[ $PATCHSTATUS == *"failed"* ]]
        then
            message "INFO: Downloading patches without proxy " INFO
            NEWPATCHSTATUS=`su - netsim -c "cd /netsim/$VERSION/; wget --no-proxy -O ${ADDR[11]}.zip $patch" 2>&1`
            message "$NEWPATCHSTATUS" INFO
            if [[ $NEWPATCHSTATUS == *"failed"* ]]
            then
                message "ERROR: Failed to download the patches, check output above " ERROR
                exit 205
            fi
        fi
    done <$PORTAL_PATCH_LIST_PATH
  else
    cp /netsim/Extra/P0*.zip /netsim/$VERSION/
    ls /netsim/$VERSION/
  fi
}
##########################################################################################################
# Fetches patches from nexus if PATCHMODE is nexus
# Arguments: $VERSION, $SIMVERSION
# Returns:
#   None
###########################################################################################################
function get_patches_from_nexus ()
{
    VERSION=$1
    SIMVERSION=$2
    message "INFO: Downloading the following verified patches from nexus to /netsim/$VERSION/ " INFO
    PATCHSTATUS=`su - netsim -c "cd /netsim/$VERSION/; wget --no-proxy -nd -r -l 1 -A zip https://arm901-eiffel004.athtem.eei.ericsson.se:8443/nexus/content/repositories/simnet/com/ericsson/simnet/netsim/patches/$SIMVERSION/" 2>&1`
    message "$PATCHSTATUS" INFO
    if [[ $PATCHSTATUS == *"failed"* ]]
    then
        message "INFO: Downloading patches with proxy " INFO
        NEWPATCHSTATUS=`su - netsim -c "cd /netsim/$VERSION/;wget -nd -r -l 1 -A zip https://arm901-eiffel004.athtem.eei.ericsson.se:8443/nexus/content/repositories/simnet/com/ericsson/simnet/netsim/patches/$SIMVERSION/" 2>&1`
        message "$NEWPATCHSTATUS" INFO
        if [[ $NEWPATCHSTATUS == *"failed"* ]]
        then
            message "ERROR: Failed to download the patches, check output above " ERROR
            exit 205
        fi
    fi
}
##########################################################################################################
# Fetches verified patches from netsim portal if PATCHMODE is verified
# Arguments: $VERSION, $MOUNTPOINT, $logFile
# Returns:
#   None
###########################################################################################################
function get_patches_from_netsim_portal ()
{
    VERSION=$1
    MOUNTPOINT=$2
    logFile=$3
    message "INFO: Downloading the following verified patches to /netsim/$VERSION/ " INFO
    NETSIM_PATCHES=`$MOUNTPOINT/getNetsimVerifiedPatchList.pl -v $VERSION 2>&1`
    if [[ $NETSIM_PATCHES == *"ERROR"* ]]
    then
        echo "$NETSIM_PATCHES" |tee -a $logFile
        message "ERROR: Failed to get Patch details from NETSim webpage" ERROR
        exit 207
    fi
    echo "$NETSIM_PATCHES" | grep zip | while read patchlink
    do
        su - netsim -c "cd /netsim/$VERSION/;wget ${patchlink}" 2>&1 | tee -a $logFile
        # Exit  some patches are not downloaded
        if [[ ${PIPESTATUS[0]} -ne 0 ]]
        then
            su - netsim -c "cd /netsim/$VERSION/;wget --no-proxy ${patchlink}" 2>&1 | tee -a $logFile
            if [[ ${PIPESTATUS[0]} -ne 0 ]]
            then
                message "ERROR: Failed to download the patch ${patchlink}, check output above " ERROR
                exit 205
            fi
        fi
    done
    if [[ $? -ne 0 ]]
    then
        exit 205
    fi
}
##################################################################################
#copies the log file to another location
# Arguments:
#   none
# Returns:
#   None
###################################################################################
function copy_logfile ()
{
    mkdir -p $COPY_LOGFILE_PATH 2>&1 |tee -a $logFile
    if [[ ${PIPESTATUS[0]} -ne 0 ]]
    then
        message "ERROR: mkdir failed to create $COPY_LOGFILE_PATH " ERROR
        exit 206
    fi
    cp $logFile $COPY_LOGFILE_PATH 2>&1 | tee -a $logFile
    if [[ ${PIPESTATUS[0]} -ne 0 ]]
    then
        message "ERROR: Failed to copy the log file to $COPY_LOGFILE_PATH " ERROR
        exit 206
    fi
}

# Main functionality
START=`date +%s%N`
trap "cleanup INT" INT
trap "cleanup EXIT" EXIT
trap "cleanup TERM" TERM
trap "cleanup INT" KILL
trap "cleanup HUP" HUP
if [[ -z "$logFile" ]];
then
    export logFile="$(pwd)/../log/`date +%Y_%m_%d_%H_%M_%S`_install_netsim.log"
    Flag=1
fi

# Varibales for content files
PORTAL_PATCH_LIST_PATH=/netsim/simdepContents/patchList.txt
PORTAL_NETSIM_LIST_PATH=/netsim/simdepContents/netsimList.txt
SIMDEP_CONTENTS=/netsim/simdepContents
patchFile=`ls $SIMDEP_CONTENTS|grep NetsimPatches_CXP9032769.*.content`

# Copy content files only if ciportal is set to yes
if [[ "$CIPORTAL" == "yes" ]]
then
  if [[ -f "$SIMDEP_CONTENTS/$patchFile" && -s "$SIMDEP_CONTENTS/$patchFile" ]]
  then
        cp $SIMDEP_CONTENTS/$patchFile $PORTAL_PATCH_LIST_PATH  |tee -a $logFile
        if [[ ${PIPESTATUS[0]} -ne 0 ]]
        then
            message "ERROR: Copying $SIMDEP_CONTENTS/$patchFile to $PORTAL_PATCH_LIST_PATH failed" ERROR
            exit 206
        fi
  else
        message "INFO: Netsim Patches content is not present in $SIMDEP_CONTENTS directory. So Proceeding to next step" INFO
  fi
    cp $SIMDEP_CONTENTS/Netsim_CXP9032765.*.content $PORTAL_NETSIM_LIST_PATH  |tee -a $logFile
    if [[ ${PIPESTATUS[0]} -ne 0 ]]
    then
        message "ERROR: Copying /netsim/simdepContents/Netsim_CXP9032765.*.content to $PORTAL_NETSIM_LIST_PATH failed" ERROR
        exit 206
    fi
fi

COPY_LOGFILE_PATH=/tmp/simnet/enm-ni-simdep/logs
if [[ ! -z $Flag ]]
then
    uid=$(id -u)
    if [[ $uid -ne 0 ]]
    then
        message "ERROR: =================== ERROR!!! =======================" ERROR
        message "ERROR: Only root user can execute the install_netsim.sh!  -" ERROR
        message "ERROR: =================== ERROR!!! =======================" ERROR
        exit 208
    fi
fi
check_args
NETSIM_DIRECTORY=/netsim/$VERSION
VAR=/var
if [[ -d $NETSIM_DIRECTORY ]] && [[ "$FORCE" != "yes" ]]
then
    CURRENT_VERSION=`ls -ltrh /netsim/inst | awk -F/ '{print $5}'`
    message "INFO: Netsim version $VERSION already installed " INFO
    rm /netsim/inst > /dev/null 2>&1 | tee -a $logFile
    if [[ ${PIPESTATUS[0]} -ne 0 ]]
    then
        message "ERROR: Removing /netsim/inst failed " ERROR
        exit 206
    fi
    su - netsim -c "ln -s $NETSIM_DIRECTORY /netsim/inst" 2>&1 | tee -a $logFile
    if [[ ${PIPESTATUS[0]} -ne 0 ]]
    then
        message "ERROR: Netsim version switching failed " ERROR
        exit 205
    fi
    message "INFO: Netsim version switched from $CURRENT_VERSION to $VERSION" INFO
    $MOUNTPOINT/start_netsim.sh -m $MOUNTPOINT
else
    NETSIM_RELEASE_LINK=$(get_netsim_release_link "$CIPORTAL" "$PORTAL_NETSIM_LIST_PATH" "$MOUNTPOINT" "$VERSION")
    message "INFO: Netsim_Release_Link is $NETSIM_RELEASE_LINK " INFO
    STOP_NETSIM=/netsim/inst/stop_netsim
    if [ -f "$STOP_NETSIM" ]
    then
       $MOUNTPOINT/stop_netsim.sh -m $MOUNTPOINT
       if [[ $? -ne 0 ]]
       then
          message "ERROR: Error in stop_netsim.sh" ERROR
          exit 207
       fi
       if [[ "$DELETE" == "yes" ]]
       then
           ls -1dr /netsim/R??? | grep -v $VERSION | while read otherversion
           do
           message "INFO: Removing old version $otherversion " INFO
           rm -rf $otherversion 2>&1 |tee -a $logFile
           if [[ ${PIPESTATUS[0]} -ne 0 ]]
           then
              message "ERROR: Removing $otherversion failed " ERROR
              exit 206
           fi
           done
       fi
    else
        message "INFO: $STOP_NETSIM file does not exist. So, Verifying if previous netsim installation is done properly" INFO
        (/netsim/inst/netsim_shell -stop_on_error) |  tee -a $LOGFILE
        if [[ ${PIPESTATUS[0]} -ne 0 ]]
        then
            message "ERROR: Netsim is not properly installed!!!" ERROR
            message "INFO: Removing /netsim/$VERSION directory as previous installation is not done properly" INFO
            rm -rf /netsim/$VERSION 2>&1 |tee -a $logFile
            if [[ ${PIPESTATUS[0]} -ne 0 ]]
            then
                sleep 60
                message "INFO: Removing /netsim/$VERSION failed. Retrying one more time." INFO
                rm -rf /netsim/$VERSION 2>&1 |tee -a $logFile
                if [[ ${PIPESTATUS[0]} -ne 0 ]]
                then
                   message "ERROR: Removing /netsim/$VERSION failed in the second try " ERROR
                   exit 206
                fi
            fi
        fi
    fi
    if [[ -d $NETSIM_DIRECTORY ]]
    then
        message "INFO: Forcibly reinstalling into $NETSIM_DIRECTORY " INFO
        rm -rf $NETSIM_DIRECTORY 2>&1 |tee -a $logFile
        if [[ ${PIPESTATUS[0]} -ne 0 ]]
        then
            message "ERROR: Removing $NETSIM_DIRECTORY failed " ERROR
            exit 206
        fi
    fi
    mkdir -p $NETSIM_DIRECTORY > /dev/null 2>&1 |tee -a $logFile
    if [[ ${PIPESTATUS[0]} -ne 0 ]]
    then
        message "ERROR: mkdir $NETSIM_DIRECTORY failed " ERROR
        exit 206
    fi
    chown netsim:netsim $NETSIM_DIRECTORY
    if [[ "$LICENSE" == "yes" ]]
    then
        get_license $NETSIM_RELEASE_LINK
    fi
    get_netsim $NETSIM_RELEASE_LINK
    cd $NETSIM_DIRECTORY
    cp $MOUNTPOINT/Unbundle.sh $NETSIM_DIRECTORY 2>&1 |tee -a $logFile
    if [[ ${PIPESTATUS[0]} -ne 0 ]]
    then
        message "ERROR: Copying Unbundle.sh from $MOUNTPOINT to $NETSIM_DIRECTORY failed" ERROR
        exit 206
    fi
   # Download patches
    if [[ "$PATCH" == "yes" ]]
    then
        if [[ "$CIPORTAL" == "yes" ]]
        then
            if [[ "$PATCHMODE" == "portal" ]]
            then
                if [[ -s $PORTAL_PATCH_LIST_PATH ]]
                then
                    get_patches_from_portal $PORTAL_PATCH_LIST_PATH $VERSION
                else
                    message "INFO: Output file /netsim/simdepContents/patchList.txt does not exist. Skipping Patch Installation!!" INFO
                fi
            else
                message "ERROR: Please pass the right parameter for PATCHMODE" ERROR
                exit 207
            fi
        elif [[ "$CIPORTAL" == "no" ]]
        then
            if [[ "$PATCHMODE" == "nexus" ]]
            then
                get_patches_from_nexus $VERSION $SIMVERSION
            elif [[ "$PATCHMODE" == "verified" ]]
            then
                get_patches_from_netsim_portal $VERSION $MOUNTPOINT $logFile
            else
                message "ERROR : Please pass the right parameter value for PATCHMODE" ERROR
                exit 207
            fi
        fi
    fi
    # Install netsim
    message "INFO: Installing netsim $VERSION now" INFO
    su - netsim -c "cd $NETSIM_DIRECTORY;sh ./Unbundle.sh quick AUTO" 2>&1 | tee -a $logFile
    #wait for the install to finish, parts of it still runs in the background
    while [[ `pgrep "Install"` ]]
    do
        sleep 1
    done
    sleep 2
    if [[ $? -ne 0 ]]
    then
        message "ERROR: NETSim installation not completed successfully, Please check output above " ERROR
        exit 207
    fi

    message "INFO: Creating NETSim init Script " INFO
    /netsim/inst/bin/create_init.sh -a 2>&1 |tee -a $logFile
    if [[ ${PIPESTATUS[0]} -ne 0 ]]
    then
        message "ERROR: Error in create_init.sh" ERROR
        exit 207
    fi
    if [[ "$LICENSE" == "yes" ]]
    then
        message "INFO: Netsim Installed with License " INFO
        exit 0
    fi
fi
