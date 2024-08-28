#!/bin/sh
clusterId=$1
drop=$2
simdep_release=$3
deployment_type=$4
enm_gui_link=$5
MT_utils_version="RELEASE"
nexusLink="https://arm1s11-eiffel004.eiffel.gic.ericsson.se:8443/nexus/"

if [ -z $enm_gui_link ]
then
echo "clusterId=$clusterId drop=$drop simdep_release=$simdep_release deployment_type=$deployment_type MT_utils_version=$MT_utils_version"
else 
echo "clusterId=$clusterId drop=$drop simdep_release=$simdep_release deployment_type=$deployment_type enm_gui_link=$enm_gui_link MT_utils_version=$MT_utils_version"
fi
echo "Retrieving Scripts from Nexus"
tarFileName="utils_${MT_utils_version}.tar.gz"
echo "Downloading file - ${tarFileName} - to the workspace"
curl -s --noproxy \* -L "${nexusLink}service/local/artifact/maven/redirect?r=releases&g=com.ericsson.mtg&a=utils&p=tar.gz&v=${MT_utils_version}" -o ${tarFileName}
if [[ $? -ne 0 ]]
   then
       echo "ERROR INFO: Downloading file - ${tarFileName} - to the workspace failed "
   fi
tar -zxf ${tarFileName}
sed -i 's/\r//' `find ./ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins -print | egrep -i 'sh|pl|txt'`
DROP_temp=`echo "${drop//.}"`
default=1801
if [ $DROP_temp -le $default ]
##########################################################
# For Drops less than 18.01
##########################################################
then
    if [[ $deployment_type == "Cloud" ]]; then
        ##########################################################
        # For Cloud tenancies
        # Get Workload VM IP, so that it can be used by all build steps
        ##########################################################

        WLVM_IP=$(python MTELoopScripts/etc/pylibs/retrieve_maintrack_openstack_deployment_details.py -c ${clusterId} --workload_vm_ip --print_to_screen)
        echo "Workload VM IP=${WLVM_IP}"

    elif [[ $deployment_type == "Physical" ]]; then
        ##########################################################
        # For Physical environments
        # Get Workload VM IP, so that it can be used by all build steps
        ##########################################################
        
        WLVM_IP=$(python -c "from MTELoopScripts.etc.pylibs import retrieve_dmt_information; print retrieve_dmt_information.search_for_workload_vm_ip(${clusterId})")
        echo "WLVM_IP=${WLVM_IP}"   
        fi

    echo "INFO: Setting Up Passwordless SSH between Jenkins Slave and WLVM"
    python MTELoopScripts/etc/ssh_operator.py -c -i "${WLVM_IP}" -u root -p 12shroot

    ##########################################################
    # Update Trust Profile
    ##########################################################

    echo "INFO: Running PKI command via the cli App "
    cd ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/
    scp -rp -o StrictHostKeyChecking=no  updateTrustProfile.sh root@${WLVM_IP}:/var/tmp/

ssh -o UserKnownHostsFile=/dev/null -o CheckHostIP=no -o StrictHostKeyChecking=no root@${WLVM_IP} /bin/bash<<EOF
/opt/ericsson/enmutils/bin/cli_app 'pkiadm pfm -l -type trust';
chmod 777 /var/tmp/updateTrustProfile.sh; /var/tmp/updateTrustProfile.sh;
EOF
/usr/bin/expect  <<EOF1
spawn scp -rp -o StrictHostKeyChecking=no root@${WLVM_IP}:$TRUST_PROFILE_LOG $WORKSPACE
expect {
    -re assword: {send "shroot\r";exp_continue}
}
    sleep 5
EOF1
    
    
    OUTPUT=$(grep "sucessfully updated" ${WORKSPACE}/trustProfile.log)
    if [ ! -z "$OUTPUT" -a "$OUTPUT"!=" " ]; then
        echo "Trust Profile is successfully updated"
    else
        echo "Trust Profile is not successfully updated"
        exit 1
    fi
else
    if [ -z $enm_gui_link ]
    then
    if [[ $deployment_type == "Cloud" ]]; then
        ##########################################################
        # For Openstack tenancies with drop greater then 18.01
        ##########################################################
        cp ${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/bin/netsim/jq-1.0.1.tar . ; tar -xvf jq-1.0.1.tar ; chmod +x ./jq
        sed_id=`curl -s "http://atvdit.athtem.eei.ericsson.se/api/deployments/?q=name=$clusterId" | ./jq '.[].enm.sed_id' | sed 's/\"//g'`
        ClusterName=`curl -s "http://atvdit.athtem.eei.ericsson.se/api/documents/$sed_id" | ./jq '.content.parameters.httpd_fqdn' | sed 's/\"//g'`
        if [[ $? -ne 0 ]]
        then
            echo "ERROR INFO: Error fetching ClusterName"
            echo "The value of httpd_fqdn in DIT should be properly set  ,Ex: for  ieatenmc3b04 deployment the value ieatenmc3b04-11.athtem.eei.ericsson.se"
            
            
        fi
  
    elif [[ $deployment_type == "Physical" ]]; then
        ##########################################################
        # For Physical environments with Drop greater than 18.01
        ##########################################################
        ClusterName=$clusterId
    fi
   else
     ClusterName=$clusterId
fi
if [ -z $enm_gui_link ]
then
    ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/setupUpdateTrustProfile.sh $ClusterName $deployment_type $clusterId
else
   ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/setupUpdateTrustProfile.sh $ClusterName $deployment_type $clusterId $enm_gui_link
fi
fi
