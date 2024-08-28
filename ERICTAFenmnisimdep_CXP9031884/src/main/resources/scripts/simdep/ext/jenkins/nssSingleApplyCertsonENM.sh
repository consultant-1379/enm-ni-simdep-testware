#!/bin/sh
clusterId=$1
drop=$2
simdep_release=$3
deployment_type=$4
nexusLink="https://arm1s11-eiffel004.eiffel.gic.ericsson.se:8443/nexus/"
MT_utils_version="RELEASE"

echo "clusterId=$clusterId drop=$drop simdep_release=$simdep_release deployment_type=$deployment_type MT_utils_version=$MT_utils_version"

echo "Retrieving Scripts from Nexus"
tarFileName="utils_${MT_utils_version}.tar.gz"
echo "Downloading file - ${tarFileName} - to the workspace"
curl -s --noproxy \* -L "${nexusLink}service/local/artifact/maven/redirect?r=releases&g=com.ericsson.mtg&a=utils&p=tar.gz&v=${MT_utils_version}" -o ${tarFileName}
tar -zxf ${tarFileName}
curl -O ERICTAFenmnisimdep_CXP9031884.jar ${nexusLink}content/groups/public/com/ericsson/ci/simnet/ERICTAFenmnisimdep_CXP9031884/${simdep_release}/ERICTAFenmnisimdep_CXP9031884-${simdep_release}.jar
mkdir -p ERICTAFenmnisimdep_CXP9031884/src/main/resources;
unzip ERICTAFenmnisimdep_CXP9031884.jar -d ERICTAFenmnisimdep_CXP9031884/src/main/resources
chmod -R 755 ./*
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
spawn scp -rp -o StrictHostKeyChecking=no root@${WLVM_IP}:$TRUST_PROFILE_LOG .
expect {
    -re assword: {send "shroot\r";exp_continue}
}
    sleep 5
EOF1


        OUTPUT=$(grep "sucessfully updated" trustProfile.log)
        if [ ! -z "$OUTPUT" -a "$OUTPUT"!=" " ]; then
            echo "Trust Profile is successfully updated"
        else
            echo "Trust Profile is not successfully updated"
            exit 1
        fi
        
        if [[ $deployment_type == "Physical" && $DROP_temp -ge 1713 ]]; then
        ##########################################################
        # For Physical environments with Drop greater than or equal to 17.13
        ##########################################################
            export Drop=$drop
            ./nodesCleanUp.sh $clusterId $Drop $deployment_type
            echo "INFO: Waiting for credm Job to run. Sleeping for 27 minutes"
            sleep 27m
        else
             echo "INFO: Waiting for credm Job to run. Sleeping for 30 minutes"
             sleep 30m
        fi
else
        if [[ $deployment_type == "Cloud" ]]; then
        ##########################################################
        # For Openstack tenancies with drop greater then 18.01
        ##########################################################
       cp ${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/bin/netsim/jq-1.0.1.tar . ; tar -xvf jq-1.0.1.tar ; chmod +x ./jq
        sed_id=`curl -s "http://atvdit.athtem.eei.ericsson.se/api/deployments/?q=name=$clusterId" | ./jq '.[].enm.sed_id' | sed 's/\"//g'`
        ClusterName=`curl -s "http://atvdit.athtem.eei.ericsson.se/api/documents/$sed_id" | ./jq '.content.parameters.httpd_fqdn' | sed 's/\"//g' | awk -F. '{print $1}'`
    elif [[ $deployment_type == "Physical" ]]; then
        ##########################################################
        # For Physical environments with Drop greater than 18.01
        ##########################################################
        ClusterName=$clusterId
    fi
        sh /root/TLS/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/setupUpdateTrustProfile.sh $ClusterName $deployment_type
        sh /root/TLS/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/nodesCleanUp.sh $clusterId $drop $deployment_type
        sleep 20m
fi
