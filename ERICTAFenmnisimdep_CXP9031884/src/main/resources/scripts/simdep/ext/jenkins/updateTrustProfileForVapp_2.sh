#!/bin/sh

######################################################################################
#     File Name     : updateTrustProfileForVapp_2.sh
#     Author        : Surabhi Ravi Teja
#     Description   : Setup Script to update trust profiles at ENM Side
#     Date Created  : 06 Nov 2019
#######################################################################################
#
##############################################
#Fetch ENM URL
##############################################
ENM_URL="https://enmapache.athtem.eei.ericsson.se/"
crlUpdateLog="/var/tmp/crlUpdate.log"

rm -rf $crlUpdateLog
##########################################################
##  Updating Curl on Gateway
##########################################################
sed -i 's/proxy.*/proxy=http:\/\/atproxy1.athtem.eei.ericsson.se:3128\//' /etc/yum.conf
yum -y update curl > /dev/null 2>&1

##########################################################
#Install Enm_Client_Scripting
##########################################################
rm -rf enm_client_scripting*.whl
cp /var/tmp/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/get-pip.py .
python get-pip.py
curl --insecure --tlsv1.2 -c /tmp/cookie.txt -X POST "$ENM_URL/login?IDToken1=Administrator&IDToken2=TestPassw0rd"
ENMSCRIPTING_URL=`curl --insecure --tlsv1.2 -b /tmp/cookie.txt --retry 5 -LsS -w %{url_effective} -o /dev/null "$ENM_URL/scripting/enmclientscripting"`
curl -L -O --insecure --tlsv1.2 -b /tmp/cookie.txt --retry 5 -fsS "$ENMSCRIPTING_URL"
pip install enm_client_scripting*.whl
##########################################################
# Update Trust Profile on Master Server
##########################################################
cp /var/tmp/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/runCliCommand.py /var/tmp/
cp /var/tmp/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/modifyXml.py /var/tmp/
sh /var/tmp/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/updateTrustProfileForVMs.sh $ENM_URL

if [[ -d /var/tmp/Certs/certs ]]
then
   echo "INFO: Removing /var/tmp/Certs/certs directory"
   rm -rf /var/tmp/Certs/certs
fi

mkdir /var/tmp/Certs/certs
if [[ $? -ne 0 ]]
then
   echo 'ERROR: Creating certs directory failed trying again'
   mkdir /var/tmp/Certs/certs
   if [[ $? -ne 0 ]]
   then
     echo 'ERROR: Creating certs directory failed after retry'
     exit 1
   fi
fi

cd /var/tmp/Certs/certs/
if [[ $? -ne 0 ]]
then 
    echo -e 'ERROR: Unable to move to certs folder retrying'
    cd /var/tmp/Certs/certs
    if [[ $? -ne 0 ]]
    then
        echo 'ERROR: Unable to move to certs folder even after retry'
	exit 1
    fi
fi


mkdir demoCA
if [[ $? -ne 0 ]]
then
   echo 'ERROR: Creating demoCA directory failed trying again'
   mkdir demoCA
   if [[ $? -ne 0 ]]
   then
     echo 'ERROR: Creating demoCA directory failed after retry'
     exit 1
   fi
fi

touch demoCA/index.txt
if [[ $? -ne 0 ]]
then
echo 'ERROR: Creating index.txt file failed retrying'
touch demoCA/index.txt
if [[ $? -ne 0 ]]
then
echo 'ERROR: Creating index.txt file failed even after retrying'
exit 1
fi
fi

touch demoCA/crlnumber
if [[ $? -ne 0 ]]
then
echo 'ERROR: Creating crlnumber file failed retrying'
touch demoCA/crlnumber
if [[ $? -ne 0 ]]
then
echo 'ERROR: Creating crlnumber file failed even after retrying'
exit 1
fi
fi

echo 1000 > demoCA/crlnumber
if [[ $? -ne 0 ]]
then
  echo 'ERROR: Adding content to crlnumber file failed retrying'
  echo 1000 > demoCA/crlnumber
  if [[ $? -ne 0 ]]
  then 
      echo 'ERROR: Adding content to crlnumber file failed'
      exit 1
  fi
fi

cp /var/tmp/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/s_cacert.pem .
cp /var/tmp/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/NSSCA.key .
cp /var/tmp/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/crlopenssl.cnf .
openssl ca -config crlopenssl.cnf -gencrl -keyfile NSSCA.key -cert s_cacert.pem -out s_cacert.crl
if [[ -f s_cacert.crl && -s s_cacert.crl ]]
then
    echo 'INFO: CRL file generation was successfull'
else 
    echo 'ERROR: CRL file generation failed'
    exit 1
fi

/var/tmp/runCliCommand.py 'pkiadm extcaupdatecrl -fn file:s_cacert.crl --name "ENM_ExtCA3"' $ENM_URL s_cacert.crl > $crlUpdateLog
