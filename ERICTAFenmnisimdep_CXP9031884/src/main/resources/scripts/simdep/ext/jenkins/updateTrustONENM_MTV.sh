clusterId=$1
drop=$2
simdep_release=$3
deployment_type=$4
enm_gui_link=$5
version=`echo "${simdep_release//.}"`
default=15407
    chmod 777 ${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/updateTrustONENM_NOHAPROXY.sh
if [ -z $enm_gui_link ]
then
    sh ${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/updateTrustONENM_NOHAPROXY.sh $clusterId $drop $simdep_release $deployment_type > ${WORKSPACE}/applyCerts.log
else
   sh ${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/updateTrustONENM_NOHAPROXY.sh $clusterId $drop $simdep_release $deployment_type $enm_gui_link > ${WORKSPACE}/applyCerts.log
fi
        cat ${WORKSPACE}/applyCerts.log
        status=$(cat ${WORKSPACE}/applyCerts.log | grep -i "Trust Profile is successfully updated")
        if [[ -z  $status ]]; then
             echo "ERROR: Applying Certs on ENM got failed"
	     cat ${WORKSPACE}/applyCerts.log
             exit 1
else
    echo "INFO: Certs applied successfully"
    cat  ${WORKSPACE}/applyCerts.log
fi
sleep 30m
