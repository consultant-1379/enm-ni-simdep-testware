#!/bin/bash


# cut the script to reduce the size
# original scrip can be found in  ssh://qfatonu@gerrit.ericsson.se:29418/OSS/com.ericsson.ci.cloud/autoscripts
#   under /bin folder

function netsim_rollout_part1 ()
{
        #for netsim_server in $(echo "$NETSIM_SERVERS")
        echo "$NETSIM_SERVERS" | sed '/^$/d' | while read netsim_server
        do
		wait_until_services_started $netsim_server
                install_vmware_tools $netsim_server no
                mount_scripts_directory $netsim_server
		install_netsim_config_force
                $SSH -qTn $netsim_server "$MOUNTPOINT/bin/start_netsim.sh -c '$CONFIG' -m $MOUNTPOINT"
                $SSH -qTn $netsim_server "su - netsim -c /netsim/inst/restart_gui > /dev/null 2>&1"
                $SSH -qTn $netsim_server "$MOUNTPOINT/bin/delete_all_sims.sh -c '$CONFIG' -m $MOUNTPOINT"
                # Create ports / default destinations, may change to have all ports
		create_ports $netsim_server

                local netsim_list=`eval echo \""\\$${netsim_server}_list"\"`

                # Loop through each sim and begin its rollout on the netsim server
                echo "$netsim_list" | grep ";" | while read simentry
                do
                        rollout_sim_part1 "$netsim_server" "$simentry"
                done
                if [[ $? -ne 0 ]]
                then
                        message "ERROR: Something went wrong during the netsim rollout on $netsim_server\n" ERROR
                        exit 1
                fi
        done
        if [[ $? -ne 0 ]]
        then
                message "ERROR: Something went wrong during the netsim rollouts\n" ERROR
                exit 1
        fi
}
function netsim_rollout_part2 ()
{
	create_p12_pems
	copy_p12_pems_to_netsim $netsim_server
	mount_scripts_directory $ADM1_HOSTNAME
        $SSH -qTn $ADM1_HOSTNAME "rm -rf /cloud_network_xmls/* > /dev/null 2>&1"
	$SSH -qTn $ADM1_HOSTNAME "mkdir /cloud_network_xmls/ > /dev/null 2>&1"
	#for netsim_server in $(echo "$NETSIM_SERVERS")
        echo "$NETSIM_SERVERS" | sed '/^$/d' | while read netsim_server
        do
		mount_scripts_directory $netsim_server
                $SSH -qTn $netsim_server "rm -rf /netsim/netsimdir/exported_items/* > /dev/null 2>&1"

                local netsim_list=`eval echo \""\\$${netsim_server}_list"\"`

                # Loop through each sim and begin its rollout on the netsim server
                echo "$netsim_list" | grep ";" | while read simentry
                do
                        rollout_sim_part2 "$netsim_server" "$simentry"
                done
                if [[ $? -ne 0 ]]
                then
                        message "ERROR: Something went wrong during the netsim rollout on $netsim_server\n" ERROR
                        exit 1
                fi
                upload_arne "$netsim_server"
        done
        if [[ $? -ne 0 ]]
        then
                message "ERROR: Something went wrong during the netsim rollouts\n" ERROR
                exit 1
        fi

	simdep_call
	if [[ $? -ne 0 ]]
        then
                message "ERROR: Something went wrong during the simdep rollouts\n" ERROR
                exit 1
        fi
}

function netsim_full_sim_rollout_test1 (){
	create_p12_pems
	copy_p12_pems_to_netsim $netsim_server
	mount_scripts_directory $ADM1_HOSTNAME
        $SSH -qTn $ADM1_HOSTNAME "rm -rf /cloud_network_xmls/* > /dev/null 2>&1"
	$SSH -qTn $ADM1_HOSTNAME "mkdir /cloud_network_xmls/ > /dev/null 2>&1"

        [[ -z $NETSIM_SERVERS ]] && { echo "NETSIM_SERVERS variable is not set"; NETSIM_SERVERS="netsim"; } 

        #for netsim_server in $(echo "$NETSIM_SERVERS")
        echo "$NETSIM_SERVERS" | sed '/^$/d' | while read netsim_server
        do
		mount_scripts_directory $netsim_server
                $SSH -qTn $netsim_server "rm -rf /netsim/netsimdir/exported_items/* > /dev/null 2>&1"

                #wait_until_services_started $netsim_server
                #install_vmware_tools $netsim_server no
                mount_scripts_directory $netsim_server
                #install_netsim_config_force
                #$SSH -qTn $netsim_server "$MOUNTPOINT/bin/start_netsim.sh -c '$CONFIG' -m $MOUNTPOINT"
                #$SSH -qTn $netsim_server "su - netsim -c /netsim/inst/restart_gui > /dev/null 2>&1"
                $SSH -qTn $netsim_server "$MOUNTPOINT/bin/delete_all_sims.sh -c '$CONFIG' -m $MOUNTPOINT"
                # Create ports / default destinations, may change to have all ports
                create_ports $netsim_server

                local netsim_list=`eval echo \""\\$${netsim_server}_list"\"`

                # Loop through each sim and begin its rollout on the netsim server
                echo "$netsim_list" | grep ";" | while read simentry
                do
                        rollout_sim_part1 "$netsim_server" "$simentry"
                done

                echo "$netsim_list" | grep ";" | while read simentry
                do
                        rollout_sim_part2 "$netsim_server" "$simentry"
                done


                if [[ $? -ne 0 ]]
                then
                        message "ERROR: Something went wrong during the netsim rollout on $netsim_server\n" ERROR
                        exit 1
                fi
        done
        if [[ $? -ne 0 ]]
        then
                message "ERROR: Something went wrong during the netsim rollouts\n" ERROR
                exit 1
        fi

	simdep_call
	if [[ $? -ne 0 ]]
        then
                message "ERROR: Something went wrong during the simdep rollouts\n" ERROR
                exit 1
        fi
}

function simdep_call (){
        functionName="simdep_call"
        message "INFO:-$functionName starting... \n" INFO
        [[ -z $NETSIM_SERVERS ]] && { echo "NETSIM_SERVERS variable is not set"; NETSIM_SERVERS="netsim"; }
        echo "$NETSIM_SERVERS" | sed '/^$/d' | while read netsim_server
        do
                message "INFO:-$functionName: Mounting cloud script folder on $netsim_server\n" INFO
                mount_scripts_directory $netsim_server
                message "INFO:-$functionName: start simdep package download on $netsim_server\n" INFO
                $SSH -qTn $netsim_server "$MOUNTPOINT/bin/simdep_download.sh"
                if [[ $? -ne 0 ]]
                then
                        message "ERROR:-$functionName: Something went wrong during the simdep package download\n" ERROR
                        exit 1
                fi
                message "INFO:-$functioName: end simdep package download on $netsim_server\n" INFO

                message "`date +%H:%M:%S`:<$0>: INFO-$functionName: start executing simdep_caller.sh\n"
                #$SSH -qTn $netsim_server "$MOUNTPOINT/bin/simdep_caller.sh -c '$CONFIG' -m $MOUNTPOINT"
                $SSH -qTn $netsim_server "$MOUNTPOINT/bin/simdep_caller.sh"
                if [[ $? -ne 0 ]]
                then
                        message "ERROR:-$functionName: Something went wrong during the simdep execution\n" ERROR
                        exit 1
                fi
                message "INFO:-$functionName: end simdep_caller.sh execution sucessfully completed\n" INFO
        done
        message "INFO:-$functionName ended... \n" INFO

}

function netsim_post_steps ()
{
	copy_extra_network_xmls
	arne_import
	check_nodes_synced
}
function copy_extra_network_xmls ()
{
	if [[ "$NETWORK_XML_DIR" != "" ]]
	then
		message "INFO: Copying xmls from $NETWORK_XML_DIR to /cloud_network_xmls/ on $ADM1_HOSTNAME\n" INFO
		mount_scripts_directory $ADM1_HOSTNAME
		$SSH -qTn $ADM1_HOSTNAME "mkdir /cloud_network_xmls/ > /dev/null 2>&1"
		$SSH -qTn $ADM1_HOSTNAME "cp $NETWORK_XML_DIR/* /cloud_network_xmls/"
	fi
}
function netsim_rollout_config()
{
	message "INFO: Setting unlimited iops on vms, please wait...: " INFO
	vm_set_iops_all unlimited
	echo "OK"
	netsim_rollout_part1
	netsim_rollout_part2
        #arne_validate
	netsim_post_steps
	message "INFO: Setting limited iops on vms, please wait...: " INFO
	vm_set_iops_all 300
	echo "OK"
}
function rollout_sim_part1 ()
{
	local netsim_server=$1
	local simentry=$2

	local SIMDIR=`echo "$simentry" | awk -F\; '{print $1}'`
	local SIMNAME=`echo "$simentry" | awk -F\; '{print $2}'`
	local SIMNODES_IPV4=`echo "$simentry" | awk -F\; '{print $3}'`
	local SIMNODES_IPV6=`echo "$simentry" | awk -F\; '{print $4}'`
	local SIMSL=`echo "$simentry" | awk -F\; '{print $5}'`
	local SIMNODES_SUBNETWORKS=`echo "$simentry" | awk -F\; '{print $6}'`

	local EXACT_SIM_FILENAME=""
	local EXACT_SIM_NAME=""
	#Perform actions on this sim
	EXACT_SIM_FILENAME=`find_matching_remote_sim "$netsim_server" "$SIMDIR" "$SIMNAME"`
	if [[ $? -ne 0 ]]
	then
		message "$EXACT_SIM_FILENAME\n" WARNING
		return
	fi
	EXACT_SIM_NAME=`echo $EXACT_SIM_FILENAME | sed 's/.zip$//g'`
	
	download_sim "$netsim_server" "$SIMDIR" "$EXACT_SIM_FILENAME"
	uncompress_sim "$netsim_server" "$EXACT_SIM_NAME" "$EXACT_SIM_FILENAME"
	assign_netsim_addresses "$netsim_server" "$EXACT_SIM_NAME" "$SIMNODES_IPV4" "no"
	assign_netsim_addresses "$netsim_server" "$EXACT_SIM_NAME" "$SIMNODES_IPV6" "yes"
}
function rollout_sim_part2 ()
{
        local netsim_server=$1
        local simentry=$2

        local SIMDIR=`echo "$simentry" | awk -F\; '{print $1}'`
        local SIMNAME=`echo "$simentry" | awk -F\; '{print $2}'`
        local SIMNODES_IPV4=`echo "$simentry" | awk -F\; '{print $3}'`
        local SIMNODES_IPV6=`echo "$simentry" | awk -F\; '{print $4}'`
        local SIMSL=`echo "$simentry" | awk -F\; '{print $5}'`
        local SIMNODES_SUBNETWORKS=`echo "$simentry" | awk -F\; '{print $6}'`

	# Set security related variables needed later on
	local CORBA_ON=""
	if [[ "$SIMSL" == "" ]]
        then
                SIMSL=0
        fi
        if [[ $SIMSL -gt 0 ]]
        then
		CORBA_ON="yes"
        else
                CORBA_ON="no"
        fi

        local EXACT_SIM_FILENAME=""
        local EXACT_SIM_NAME=""
        #Perform actions on this sim
        EXACT_SIM_FILENAME=`find_matching_remote_sim "$netsim_server" "$SIMDIR" "$SIMNAME"`
        if [[ $? -ne 0 ]]
        then
                message "$EXACT_SIM_FILENAME\n" WARNING
                return
        fi
        EXACT_SIM_NAME=`echo $EXACT_SIM_FILENAME | sed 's/.zip$//g'`

	create_sim_ssl_definition "$netsim_server" "$EXACT_SIM_NAME" secdefsl2 secdefsl2 /netsim/netsim_security/secdefsl2/cert.pem /netsim/netsim_security/secdefsl2/cacert.pem /netsim/netsim_security/secdefsl2/key.pem netsim
	set_corba_security "$netsim_server" "$EXACT_SIM_NAME" "$CORBA_ON" secdefsl2
	set_security_mo "$netsim_server" "$EXACT_SIM_NAME" "$SIMSL"
	start_nodes "$netsim_server" "$EXACT_SIM_NAME"

	# Create ipv4 xmls
	create_arne "$netsim_server" "$EXACT_SIM_NAME" "$SIMNODES_SUBNETWORKS" "no"

	# Create ipv6 xmls
	create_arne "$netsim_server" "$EXACT_SIM_NAME" "$SIMNODES_SUBNETWORKS" "yes"
}
function create_sim_ssl_definition ()
{
	local SERVER=$1
	local SIMNAME="$2"
	local DEFINITION_NAME="$3"
	local DESCRIPTION="$4"
	local CERT_PATH="$5"
	local CACERT_PATH="$6"
	local KEY_PATH="$7"
	local KEY_PASSWORD="$8"
	$SSH -qTn $SERVER "$MOUNTPOINT/bin/create_sim_ssl_definition.sh -s $SIMNAME -n $DEFINITION_NAME -d $DESCRIPTION -c $CERT_PATH -a $CACERT_PATH -k $KEY_PATH -p $KEY_PASSWORD"
	if [[ $? -ne 0 ]]
        then
                message "ERROR: Something went wrong creating the security definition\n" ERROR
                exit 1
        fi
}
function set_corba_security ()
{
	local SERVER=$1
	local SIMNAME="$2"
	local LEVEL="$3"
	local SEC_DEF_NAME="$4"
	mount_scripts_directory $SERVER
        OUTPUT=`$SSH -qTn $SERVER "$MOUNTPOINT/bin/set_corba_security.sh -c '$CONFIG' -m $MOUNTPOINT -n '$SIMNAME' -d '$SEC_DEF_NAME' -l '$LEVEL'"`
        if [[ $? -ne 0 ]]
        then
                message "ERROR: Something went wrong setting the corba security definition\n" ERROR
                message "---------------------------------------------------------\n" ERROR
                message "$OUTPUT" ERROR
                message "\n---------------------------------------------------------\n" ERROR
                exit 1
        else
                echo "$OUTPUT"
        fi
}
function create_ssl_definition_wlr ()
{
	$SSH -qt $netsim_server "$MOUNTPOINT/bin/create_ssl_definition.sh -n 'netsim' -d 'netsim' -c /netsim/netsim_security/secdefsl2/cert.pem -a /netsim/netsim_security/secdefsl2/cacert.pem -k /netsim/netsim_security/secdefsl2/key.pem -p netsim"
}
function copy_p12_pems_to_netsim ()
{
	local SERVER=$1
	if [[ "$SERVER" == "" ]]
	then
		SERVER=$NETSIM_HOSTNAME
	fi
	mount_scripts_directory $SERVER
	mount_scripts_directory $ADM1_HOSTNAME
	$SSH -qTn $SERVER "mkdir -p /netsim/netsim_security/secdefsl2/ > /dev/null 2>&1"

$EXPECT - <<EOF
set force_conservative 1
set timeout -1
spawn scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$ADM1_HOSTNAME:/*.pem root@$SERVER:/netsim/netsim_security/secdefsl2/
while {"1" == "1"} {
        expect {
                "assword:" {send "shroot\r"}
                eof {
                        catch wait result
                        exit [lindex \$result 3]
                }
        }
}

EOF
}
function check_nodes_synced()
{
	message "INFO: Checking are all nodes on oss synced\n" INFO
        mount_scripts_directory $ADM1_HOSTNAME
        $SSH -qtn $ADM1_HOSTNAME "$MOUNTPOINT/bin/check_nodes_synced.sh -c '$CONFIG' -m $MOUNTPOINT" 2> /dev/null
        if [[ $? -ne 0 ]]
        then
                message "ERROR: Something went wrong during the sync check, please check output above\n" ERROR
                #exit 1
        else
                echo "$OUTPUT"
        fi
}
function arne_import ()
{
	message "INFO: Starting arne imports\n" INFO
        mount_scripts_directory $ADM1_HOSTNAME
        $SSH -qTn $ADM1_HOSTNAME "$MOUNTPOINT/bin/arne_import.sh -c '$CONFIG' -m $MOUNTPOINT -o 'import' -t no"
        if [[ $? -ne 0 ]]
        then
                message "ERROR: Something went wrong during the arne imports, please check output above\n" ERROR
                exit 1
        else
                echo "$OUTPUT"
        fi
}

function arne_validate ()
{
	message "INFO: Starting arne validations\n" INFO
        mount_scripts_directory $ADM1_HOSTNAME
        $SSH -qTn $ADM1_HOSTNAME "$MOUNTPOINT/bin/arne_import.sh -c '$CONFIG' -m $MOUNTPOINT -o 'val:rall' -t no"
        if [[ $? -ne 0 ]]
        then
                message "ERROR: Something went wrong during the arne validations, please check output above\n" ERROR
                exit 1
        else
                echo "$OUTPUT"
        fi
}


function upload_arne ()
{
        local SERVER="$1"
        mount_scripts_directory $SERVER
	mount_scripts_directory $ADM1_HOSTNAME

	$EXPECT - <<EOF
set force_conservative 1
set timeout -1
spawn $SSH -qt $ADM1_HOSTNAME "scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$SERVER:/netsim/netsimdir/exported_items/*.xml /cloud_network_xmls/"
while {"1" == "1"} {
        expect {
		"assword:" {send "shroot\r"}
		eof {
			catch wait result
	                exit [lindex \$result 3]
		}
	}
}

EOF
        if [[ $? -ne 0 ]]
        then
                message "ERROR: Something went wrong uploading the arne xmls, please check output above\n" ERROR
                exit 1
        fi
}



function set_security_mo ()
{

	local SERVER="$1"
        local SIMNAME="$2"
	local SEC_LEVEL="$3"
        mount_scripts_directory $SERVER
        OUTPUT=`$SSH -qTn $SERVER "$MOUNTPOINT/bin/set_security_mo.sh -c '$CONFIG' -m $MOUNTPOINT -n '$SIMNAME' -l '$SEC_LEVEL'"`
        if [[ $? -ne 0 ]]
        then
                message "ERROR: Couldn't set the security mo, please check output below\n" ERROR
                message "---------------------------------------------------------\n" ERROR
                message "$OUTPUT" ERROR
                message "\n---------------------------------------------------------\n" ERROR
                exit 1
        else
                echo "$OUTPUT"
        fi

}
function start_nodes ()
{
	local SERVER="$1"
        local SIMNAME="$2"
	mount_scripts_directory $SERVER
	OUTPUT=`$SSH -qTn $SERVER "$MOUNTPOINT/bin/start_nodes.sh -c '$CONFIG' -m $MOUNTPOINT -n '$SIMNAME'"`
        if [[ $? -ne 0 ]]
        then
                message "ERROR: Couldn't start the desired nodes on sim $SIMNAME, see further output below\n" ERROR
                message "---------------------------------------------------------\n" ERROR
                message "$OUTPUT" ERROR
                message "\n---------------------------------------------------------\n" ERROR
                exit 1
        else
                echo "$OUTPUT"
        fi
}
function create_arne ()
{
        local SERVER="$1"
        local SIMNAME="$2"
	local SIMNODES="$3"
	local IPV6="$4"
        mount_scripts_directory $SERVER
        OUTPUT=`$SSH -qTn $SERVER "$MOUNTPOINT/bin/create_arne.sh -c '$CONFIG' -m $MOUNTPOINT -n '$SIMNAME' -s '$SIMNODES' -i '$IPV6'"`
        if [[ $? -ne 0 ]]
        then
                message "ERROR: Something went wrong creating the xmls for $SIMNAME, see further output below\n" ERROR
                message "---------------------------------------------------------\n" ERROR
                message "$OUTPUT" ERROR
                message "\n---------------------------------------------------------\n" ERROR
                exit 1
        else
                echo "$OUTPUT"
        fi
}
function assign_netsim_addresses()
{
        local SERVER="$1"
        local SIMNAME="$2"
        local SIMNODES="$3"
	local IPV6="$4"
        mount_scripts_directory $SERVER
        OUTPUT=`$SSH -qTn $SERVER "$MOUNTPOINT/bin/assign_netsim_addresses.sh -c '$CONFIG' -m $MOUNTPOINT -n '$SIMNAME' -s '$SIMNODES' -i '$IPV6'"`
        if [[ $? -ne 0 ]]
        then
                message "ERROR: Couldn't assign ip addresses to nodes on sim $SIMNAME, see further output below\n" ERROR
                message "---------------------------------------------------------\n" ERROR
                message "$OUTPUT" ERROR
                message "\n---------------------------------------------------------\n" ERROR
                exit 1
        else
                echo "$OUTPUT"
        fi
}
function download_sim ()
{
	local SERVER="$1"
	local SIMDIR="$2"
	local SIMNAME="$3"
	local OUTPUT=""
	mount_scripts_directory $SERVER
	
	OUTPUT=`$SSH -qTn $SERVER "$MOUNTPOINT/bin/download_sim.sh -c '$CONFIG' -m $MOUNTPOINT -s '$SIMDIR' -n '$SIMNAME'"`
	if [[ $? -ne 0 ]]
        then
                message "ERROR: Couldn't download the sim $SIMNAME from directory $SIMDIR, see further output below\n" ERROR
                message "---------------------------------------------------------\n" ERROR
                message "$OUTPUT" ERROR
                message "\n---------------------------------------------------------\n" ERROR
                exit 1
	else
		echo "$OUTPUT"
	fi
}
function uncompress_sim ()
{
	local SERVER="$1"
        local SIMNAME="$2"
	local SIM_FILENAME="$2"
        local OUTPUT=""
        mount_scripts_directory $SERVER

        OUTPUT=`$SSH -qTn $SERVER "$MOUNTPOINT/bin/uncompress_and_open_new.sh -c '$CONFIG' -m $MOUNTPOINT -n '$SIMNAME' -f '$SIM_FILENAME'"`
        if [[ $? -ne 0 ]]
        then
                message "ERROR: Couldn't uncompress and open the sim $SIMNAME, see further output below\n" ERROR
                message "---------------------------------------------------------\n" ERROR
                message "$OUTPUT" ERROR
                message "\n---------------------------------------------------------\n" ERROR
                exit 1
        else
                echo "$OUTPUT"
        fi
}
function install_netsim_internal ()
{
	local SERVER="$1"
	local NETSIM_VERSION="$2"
	local FORCE="$3"
	NETSIM_VERSIONS=`ls $MOUNTPOINT/files/netsim/versions/ | sort -ur`
        NETSIM_N=`echo "$NETSIM_VERSIONS" | head -1 | tail -1`
        NETSIM_N_1=`echo "$NETSIM_VERSIONS" | head -2 | tail -1`
        NETSIM_N_2=`echo "$NETSIM_VERSIONS" | head -3 | tail -1`

	if [[ "$NETSIM_VERSION" == "N" ]]
        then
                ACTUAL_NETSIM_VERSION="$NETSIM_N"
        elif [[ "$NETSIM_VERSION" == "N_1" ]]
        then
                ACTUAL_NETSIM_VERSION="$NETSIM_N_1"
        elif [[ "$NETSIM_VERSION" == "N_2" ]]
        then
                ACTUAL_NETSIM_VERSION="$NETSIM_N_2"
        else
		ACTUAL_NETSIM_VERSION="$NETSIM_VERSION"
                #message "ERROR: Don't know what version $NETSIM_VERSION is, please use N, N_1 or N_2\n" ERROR
                #exit 1
        fi

	message "INFO: Installing netsim $ACTUAL_NETSIM_VERSION on $SERVER\n" INFO
	mount_scripts_directory $SERVER
	setup_ntp_client_netsim
	$SSH -qTn $SERVER "$MOUNTPOINT/bin/setup_internal_ssh.sh"
	$SSH -qTn $SERVER "$MOUNTPOINT/bin/install_netsim.sh -c '$CONFIG' -m $MOUNTPOINT -v $ACTUAL_NETSIM_VERSION -f $FORCE"
	if [[ $? -ne 0 ]]
	then
		message "ERROR: Something wen't wrong installing netsim, check output above\n" ERROR
		exit 1
	fi
	update_netsim_license
}
function install_netsim_n ()
{
	requires_variable NETSIM_HOSTNAME
	install_netsim_internal $NETSIM_HOSTNAME N no
}
function install_netsim_n1 ()
{
	requires_variable NETSIM_HOSTNAME
        install_netsim_internal $NETSIM_HOSTNAME N_1 no
}
function install_netsim_n2 ()
{
	requires_variable NETSIM_HOSTNAME
        install_netsim_internal $NETSIM_HOSTNAME N_2 no
}
function install_netsim_config ()
{
	requires_variable NETSIM_HOSTNAME
	if [[ "$NETSIM_VERSION" == "" ]]
	then
		message "INFO: Netsim version not set in NETSIM_VERSION variable, defaulting to NETSIM_VERSION=\"N\"\n" INFO
		NETSIM_VERSION="N"
	fi
	install_netsim_internal $NETSIM_HOSTNAME $NETSIM_VERSION no
}

function install_netsim_n_force ()
{
        requires_variable NETSIM_HOSTNAME
        install_netsim_internal $NETSIM_HOSTNAME N yes
}
function install_netsim_n1_force ()
{
        requires_variable NETSIM_HOSTNAME
        install_netsim_internal $NETSIM_HOSTNAME N_1 yes
}
function install_netsim_n2_force ()
{
        requires_variable NETSIM_HOSTNAME
        install_netsim_internal $NETSIM_HOSTNAME N_2 yes
}
function install_netsim_config_force ()
{
        requires_variable NETSIM_HOSTNAME
        if [[ "$NETSIM_VERSION" == "" ]]
        then
                message "INFO: Netsim version not set in NETSIM_VERSION variable, defaulting to NETSIM_VERSION=\"N\"\n" INFO
                NETSIM_VERSION="N"
        fi
        install_netsim_internal $NETSIM_HOSTNAME $NETSIM_VERSION yes
}

function update_netsim_license ()
{
	requires_variable NETSIM_HOSTNAME
	mount_scripts_directory $NETSIM_HOSTNAME
	$SSH -qTn $NETSIM_HOSTNAME "$MOUNTPOINT/bin/update_netsim_license.sh -c '$CONFIG' -m $MOUNTPOINT"
}
function stop_netsim ()
{
	requires_variable NETSIM_HOSTNAME
	mount_scripts_directory $NETSIM_HOSTNAME
	$SSH -qt $NETSIM_HOSTNAME "$MOUNTPOINT/bin/stop_netsim.sh -c '$CONFIG' -m $MOUNTPOINT"
}
function restart_netsim ()
{
        requires_variable NETSIM_HOSTNAME
        mount_scripts_directory $NETSIM_HOSTNAME
        $SSH -qTn $NETSIM_HOSTNAME "$MOUNTPOINT/bin/restart_netsim.sh -c '$CONFIG' -m $MOUNTPOINT"
}
function start_netsim ()
{
        requires_variable NETSIM_HOSTNAME
        mount_scripts_directory $NETSIM_HOSTNAME
        $SSH -qTn $NETSIM_HOSTNAME "$MOUNTPOINT/bin/start_netsim.sh -c '$CONFIG' -m $MOUNTPOINT"
}
function message ()
{

	local MESSAGE="$1"
	local TYPE=$2

	COLOR=$white
	if [[ "$TYPE" == "ERROR" ]]
	then
		COLOR=$red
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
	echo -en "$MESSAGE"
	echo -en $white

}

function usage_msg ()
{
        message "$0
		-c <relative path to config files, you can seperate multiple config files using a colon, eg -c ../configs/file1.txt:../configs/file2.txt>
		-g <GATEWAY>
		-e <EMAIL ADDRESSES seperated by semicolons>
		-f <FUNCTION NAME>

			## Main Rollout Related Functions
			initial_rollout # Installs each server as far as it can go without attaching them together, broken down into two phases which can be run individually if needs be
				initial_rollout_part1 # Runs the initial rollout up until after the servers finish their II and reach the console login prompt
				initial_rollout_part2 # Runs post steps that run immediately after the II on each server, like vmware tools, ntp clients, removing serial ports
			common_post_steps # Performs post configuration on each server
			full_rollout # Runs both initial_rollout and common_post_steps in one go

			rollout_config # Performs any combination of initial rollout and post steps, based on these entries in youre config
			               # Set them to either yes or no
					INITIAL_INSTALL_ADM1=
						INITIAL_INSTALL_ADM1_PART1=
						INITIAL_INSTALL_ADM1_PART2=
					INITIAL_INSTALL_OSS2_ADM1=
						INITIAL_INSTALL_OSS2_ADM1_PART1=
						INITIAL_INSTALL_OSS2_ADM1_PART2=
                                        INITIAL_INSTALL_ADM2=
						INITIAL_INSTALL_ADM2_PART1=
						INITIAL_INSTALL_ADM2_PART2=
					INITIAL_INSTALL_OMSAS=
						INITIAL_INSTALL_OMSAS_PART1=
						INITIAL_INSTALL_OMSAS_PART2=
					INITIAL_INSTALL_OMSERVM=
						INITIAL_INSTALL_OMSERVM_PART1=
						INITIAL_INSTALL_OMSERVM_PART2=
					INITIAL_INSTALL_OMSERVS=
						INITIAL_INSTALL_OMSERVS_PART1=
						INITIAL_INSTALL_OMSERVS_PART2=
					INITIAL_INSTALL_UAS1=
						INITIAL_INSTALL_UAS1_PART1=
						INITIAL_INSTALL_UAS1_PART2=
					INITIAL_INSTALL_PEER1=
                                                INITIAL_INSTALL_PEER1_PART1=
                                                INITIAL_INSTALL_PEER1_PART2=
					INITIAL_INSTALL_NEDSS=
						INITIAL_INSTALL_NEDSS_PART1=
						INITIAL_INSTALL_NEDSS_PART2=
					INITIAL_INSTALL_EBAS=
						INITIAL_INSTALL_EBAS_PART1=
						INITIAL_INSTALL_EBAS_PART2=
					INITIAL_INSTALL_ENIQE=
                                                INITIAL_INSTALL_ENIQE_PART1=
                                                INITIAL_INSTALL_ENIQE_PART2=
					INITIAL_INSTALL_ENIQS=
                                                INITIAL_INSTALL_ENIQS_PART1=
                                                INITIAL_INSTALL_ENIQS_PART2=
					INITIAL_INSTALL_ENIQSC=
                                                INITIAL_INSTALL_ENIQSC_PART1=
                                                INITIAL_INSTALL_ENIQSC_PART2=
					INITIAL_INSTALL_ENIQSE=
                                                INITIAL_INSTALL_ENIQSE_PART1=
                                                INITIAL_INSTALL_ENIQSE_PART2=
					INITIAL_INSTALL_ENIQSR1=
                                                INITIAL_INSTALL_ENIQSR1_PART1=
                                                INITIAL_INSTALL_ENIQSR1_PART2=
					INITIAL_INSTALL_ENIQSR2=
                                                INITIAL_INSTALL_ENIQSR2_PART1=
                                                INITIAL_INSTALL_ENIQSR2_PART2=
					INITIAL_INSTALL_SON_VIS=
                                                INITIAL_INSTALL_SON_VIS_PART1=
                                                INITIAL_INSTALL_SON_VIS_PART2=
                                        INITIAL_INSTALL_TOR=
                                                INITIAL_INSTALL_TOR_PART1=
					
					POST_INSTALL_ADM1=                                        
					POST_INSTALL_ADM2=
					POST_INSTALL_OMSAS=
					POST_INSTALL_OMSERVM=
					POST_INSTALL_OMSERVS=
					POST_INSTALL_UAS1=
					POST_INSTALL_PEER1=
					POST_INSTALL_NEDSS=
					POST_INSTALL_EBAS=

			## Private Gateway Related
			config_gateway
			install_vmware_tools_gateway

			## ADM1 Related
			create_config_files_adm1
			add_dhcp_client_remote_adm1
			boot_from_network_adm1
			install_adm1
			wait_oss_online_adm1
			update_sentinel_license
			manage_mcs_critical_5 | manage_mcs_config | manage_mcs_all | manage_mcs_initial | manage_mcs_config_check_only
				## manage_mcs_initial can read the variable INITIAL_INSTALL_MCS= in your config.
			expand_databases
			create_caas_user_tss_adm1
			update_nmsadm_password_config # Updates the nmsadm password based on your config
			setup_ntp_client_adm1
			setup_adm1_ldap_client
			set_external_gateway_adm1
			set_prompt_adm1
			set_eeprom_text_adm1
			install_vmware_tools_adm1
			update_scs_properties # Populates the scs.properties file with ip adddresses of omservm / omservs
			enable_ms_security # Enables security on the master server

			## ADM2 Related
                        create_config_files_adm2
                        add_dhcp_client_remote_adm2
			boot_from_network_adm2
                        install_adm2
			set_external_gateway_adm2
			add_second_root_disk_adm2 # Not working yet
			switch_sybase_adm2 # Not working yet

			## OMSERVM Related
			create_config_files_omservm
			add_dhcp_client_remote_omservm
			boot_from_network_omservm
			install_omservm
			setup_resolver_omservm
			setup_ntp_client_omservm
			install_caas_omservm
			configure_csa_omservm
			setup_ssh_masterservice_omservm
			set_external_gateway_omservm
			set_prompt_omservm
			set_eeprom_text_omservm
			install_vmware_tools_omservm
			plumb_storage_nic_omservm
			create_users_config # Creates ossrc users based on the USER_LIST variable set in your config.
			                    # The entries must be of the form USERNAME PASSWORD CATEGORY UID (optional)
			                    # eg: 
			                    # USER_LIST='ekemark ekemark01 sys_adm
			                    # eeishky eeishky01 sys_adm 1005'
			add_users_to_groups_config # Creates ldap groups and adds existing ossrc users to the groups based on the GROUP_LIST variable set in your config
			                           # The entries must be of the form USERNAME GROUP UID (optional)
			                           # eg:
			                           # GROUP_LIST='ekemark ebas_group
			                           # eeishky group1
			                           # eeishky group2'
			remove_users_config # Same usage as create_users_config

			## OMSERVS Related
                        create_config_files_omservs
                        add_dhcp_client_remote_omservs
			boot_from_network_omservs
                        install_omservs
                        setup_resolver_omservs
			setup_ntp_client_omservs
                        install_caas_omservs
                        configure_csa_omservs
                        setup_ssh_masterservice_omservs
			set_external_gateway_omservs
			set_prompt_omservs
			set_eeprom_text_omservs
                        install_vmware_tools_omservs
			add_omservs_sls_url_adm1
			plumb_storage_nic_omservs
	
			## OMSAS Related
                        create_config_files_omsas
                        add_dhcp_client_remote_omsas
			boot_from_network_omsas
                        install_omsas
			setup_resolver_omsas
			setup_ntp_client_omsas
			install_caas_omsas
			configure_csa_omsas
			setup_ssh_masterservice_omsas
			set_external_gateway_omsas
			set_prompt_omsas
			set_eeprom_text_omsas
			install_vmware_tools_omsas
			generate_p12_omsas
			copy_ms_certs_omsas
			fetch_ior_files # Fetches ior files after security is enabled on the master server, called from enable_ms_security

			## COMInf Related
			setup_replication_detect # Choose the correct replication steps to run based on the types of servers in config
			setup_replication_config # Chooses the correct replication steps to run based on config
			setup_replication_single # For env with OMSAS + OMSERVM
			setup_replication_standard # For env with OMSERVM + OMSERVS
			setup_replication_enhanced # For env with OMSAS + OMSERVM + OMSERVS

			## LDAP Related
			ldap_modify # Runs all sub functions below
				disable_password_expiry
				disable_password_lockout
				disable_password_must_change
				remove_password_change_history
				reduce_min_password_length
				update_ldap_rules_omservm # Changes minimum / maximum uids, password rules etc, on the omservm

			## UAS1 Related
                        create_config_files_uas1
                        add_dhcp_client_remote_uas1
			activate_uas_uas1
			boot_from_network_uas1
			install_uas1_initial_only
			install_uas1
			uas_post_steps_uas1
			setup_ntp_client_uas1
			set_external_gateway_uas1
			set_prompt_uas1
			set_eeprom_text_uas1
			install_vmware_tools_uas1
			plumb_storage_nic_uas1

			## PEER1 Related
                        create_config_files_peer1
                        add_dhcp_client_remote_peer1
                        activate_peer_peer1
                        boot_from_network_peer1
                        install_peer1_initial_only
                        install_peer1
                        uas_post_steps_peer1
                        setup_ntp_client_peer1
                        set_external_gateway_peer1
                        set_prompt_peer1
                        set_eeprom_text_peer1
                        install_vmware_tools_peer1
			configure_peer_peer1

			## NEDSS Related
			create_config_files_nedss
			add_dhcp_client_remote_nedss
			boot_from_network_nedss
			install_nedss
			setup_ntp_client_nedss
			set_external_gateway_nedss
			set_prompt_nedss
			set_eeprom_text_nedss
			install_vmware_tools_nedss
			create_and_share_smrs_filesystems
			plumb_storage_nic_nedss
			configure_smrs_master_service
			configure_smrs_add_nedss_nedss
			configure_smrs_add_slave4_service_nedss
			configure_smrs_add_slave6_service_nedss
			add_aif_nedss

			## EBAS Related
			create_config_files_ebas
			add_dhcp_client_remote_ebas
			activate_uas_ebas
			boot_from_network_ebas
			install_ebas_initial_only
			install_ebas
			post_steps_ebas
			setup_ntp_client_ebas
			set_external_gateway_ebas
			set_prompt_ebas
			set_eeprom_text_ebas
			install_vmware_tools_ebas
			plumb_storage_nic_ebas

			## ENIQE Related
                        create_config_files_eniqe
                        add_dhcp_client_remote_eniqe
                        boot_from_network_eniqe
                        install_eniqe
                        setup_ntp_client_eniqe
                        set_external_gateway_eniqe
                        set_prompt_eniqe
                        set_eeprom_text_eniqe
                        install_vmware_tools_eniqe

			## ENIQS Related
                        create_config_files_eniqs
                        add_dhcp_client_remote_eniqs
                        boot_from_network_eniqs
                        install_eniqs
                        setup_ntp_client_eniqs
                        set_external_gateway_eniqs
                        set_prompt_eniqs
                        set_eeprom_text_eniqs
                        install_vmware_tools_eniqs

			## SON_VIS Related
                        create_config_files_son_vis
                        add_dhcp_client_remote_son_vis
                        boot_from_network_son_vis
                        install_son_vis
                        setup_ntp_client_son_vis
                        set_external_gateway_son_vis
                        set_prompt_son_vis
                        set_eeprom_text_son_vis
                        install_vmware_tools_son_vis

			## Netsim Related
			update_netsim_license # Updates the license to the latest locally stored license file
			install_netsim_config # Installs netsim version specified in config file by variable NETSIM_VERSION, eg
				NETSIM_VERSION=N # Specifies to install latest netsim version (This is the default, if the NETSIM_VERSION variable isn't set
				NETSIM_VERSION=N_1 # Specifies to install 1 netsim version back
				NETSIM_VERSION=N_2 # Specifies to install 2 netsim versions back
			install_netsim_config_force # Same as above but installs netsim even if its already installed

			install_netsim_n # Installs latest netsim version explicity
			install_netsim_n_force # Installs latest netsim version explicity even if its already installed

			install_netsim_n1 # Installs 1 netsim version back explicity
			install_netsim_n1_force # Installs 1 netsim version back explicity even if its already installed

			install_netsim_n2 # Installs 2 netsim versions back explicity
			install_netsim_n2_force # Installs 2 netsim versions back explicity even if its already installed

			install_vmware_tools_netsim

			## TA Specific
			all_rno_post_steps # Mounts 3 rational directories on the adm1 server
			all_eth_post_steps
			eba_netsim_steps # Runs commands from RTT Ticket 308854, ie copying zome zips and creating softlinks on the netsim
			all_security_post_steps # Steps specific to security like root password, /etc/hosts populating, mounts
				security_netsim_steps # Runs security TA commands from RTT Ticket 300326
			all_wlr_post_steps
" WARNING
        exit 1
}
function security_netsim_steps ()
{
	if [[  "$NETSIM_HOSTNAME" == "" ]]
	then
		message "INFO: You don't have a netsim hostname set, not doing security netsim related steps\n" INFO
		return 0
	fi
	message "INFO: Running security netsim related steps\n" INFO
	mount_scripts_directory $NETSIM_HOSTNAME
	# Create the ipv4 and ipv6 ports
	$SSH -qt $NETSIM_HOSTNAME "$MOUNTPOINT/bin/create_ports.sh"

	# Copy the security specific pem files
	message "INFO: Copying security pems to netsim\n" INFO
	$SSH -qt $NETSIM_HOSTNAME "su - netsim -c \"cp $MOUNTPOINT/files/ta_specific/security/*.pem /netsim/netsimdir/\""

	# Create the security ssl definition
	$SSH -qt $NETSIM_HOSTNAME "$MOUNTPOINT/bin/create_ssl_definition.sh -n 'CORBAdefault' -d 'default SSL for CORBA' -c /netsim/netsimdir/cert.pem -a /netsim/netsimdir/cacert.pem -k /netsim/netsimdir/key.pem -p abcd1234"

	# Create LRAN NE type
	message "INFO: Copying and uncompressing the LRAN NE type file\n" INFO
	$SSH -qt $NETSIM_HOSTNAME "su - netsim -c \"cp $MOUNTPOINT/files/ta_specific/security/ERBSC170_R24D.zip /netsim/netsimdir/\""
	$SSH -qt $NETSIM_HOSTNAME "$MOUNTPOINT/bin/uncompress_and_open.sh ERBSC170_R24D"
}
