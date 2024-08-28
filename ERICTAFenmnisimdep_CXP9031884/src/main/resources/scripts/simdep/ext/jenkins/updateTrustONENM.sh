clusterId=$1
drop=$2
simdep_release=$3
deployment_type=$4
enm_gui_link=$5
version=`echo "${simdep_release//.}"`
default=15407
    chmod 777 ${workspace}/erictafENMNISIMDEP_cxp9031884/SRC/MAIN/RESOURCES/SCRIPTS/SIMDEP/EXT/JENKINS/UPDATEtRUSTonenm_nohaproxy.SH
if [ -z $enm_gui_link ] 
then
    sh ${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/updateTrustONENM_NOHAPROXY.sh $clusterId $drop $simdep_release $deployment_type > ${WORKSPACE}/applyCerts.log
	cat ${WORKSPACE}/applyCerts.log
else
   sh ${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/updateTrustONENM_NOHAPROXY.sh $clusterId $drop $simdep_release $deployment_type $enm_gui_link > ${WORKSPACE}/applyCerts.log
	cat ${WORKSPACE}/applyCerts.log
fi

	status=$(cat ${WORKSPACE}/applyCerts.log | grep -i "Trust Profile is successfully updated")
    if [[ -z  $status ]]; then
	    echo "ERROR: Applying Certs got failed"
            cat ${WORKSPACE}/applyCerts.log
	    exit 1
else
    echo "Certs applied successfully"
    cat ${WORKSPACE}/applyCerts.log
fi

DROP_temp=`echo "${drop//.}"`
if [[ $DROP_temp -ge "1713" && $DROP_temp -le "1801" && $deployment_type == "Physical" ]]
then
    sh ${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/nodesCleanUp.sh $clusterId $drop $deployment_type > ${WORKSPACE}/nodesCleanUp.log
#    sleep 20m
elif [[ $DROP_temp -ge 1801 ]]
then
    sh ${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/nodesCleanUp.sh $clusterId $drop $deployment_type > ${WORKSPACE}/nodesCleanUp.log
fi
status=$(cat ${WORKSPACE}/nodesCleanUp.log | grep -i "ERROR")
if [[ ! -z $status ]]
then
   echo "ERROR: nodesCleanup got failed"
   cat ${WORKSPACE}/nodesCleanUp.log
   exit 1
else
   cat ${WORKSPACE}/nodesCleanUp.log
fi
sleep 20m
