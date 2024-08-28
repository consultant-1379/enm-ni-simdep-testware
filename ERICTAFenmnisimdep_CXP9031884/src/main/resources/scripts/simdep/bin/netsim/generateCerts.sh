#!/bin/sh

PWD=`dirname "$0"`
if [ -f $PWD/../conf/conf.txt ]
then
   source $PWD/../conf/conf.txt
else
   echo "ERROR:conf.txt doesn't exist"
   exit 1
fi

certsPath=$2;

#######################################################################################################################################################
# creatingConfigFiles
#######################################################################################################################################################

echo "[req]
distinguished_name = srv
prompt = no
[srv]
CN = $1
OU=TCS
C=IN
O=Ericsson
[ext]
basicConstraints=CA:FALSE
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
keyUsage = digitalSignature, nonRepudiation, keyEncipherment
crlDistributionPoints = URI:http://example.com/myca.crl" > pem.config

########################################################################################################################################################
# Generating Certs
########################################################################################################################################################
cat pem.config

echo "Copying certs from simdep"
cp $PWD/NSSCA.key  s_cacert.key
if [[ $? -ne 0 ]]
    then
        echo "ERROR: Copying s_cacert.key failed from simdep"
        exit 201
    fi
cp $PWD/NSSCA.pem  s_cacert.pem
if [[ $? -ne 0 ]]
    then
        echo "ERROR: Copying s_cacert.pem failed from simdep"
        exit 201
    fi
echo `openssl genrsa -passout pass:test1234 -out keys.pem 2048`
echo `openssl req -new -key 'keys.pem' -out 'srv-req.pem' -config 'pem.config'`
echo `cp s_cacert.key s_cacertkey.pem`
echo `openssl x509 -req -days 1024 -in 'srv-req.pem' -CA s_cacert.pem -CAkey s_cacertkey.pem -CAcreateserial -out 'cert_single.pem' -extfile 'pem.config' -extensions ext`
echo `mv keys.pem $certsPath`
echo `mv cert_single.pem $certsPath`
echo `mv s_cacert.pem $certsPath`
echo `rm -rf *.key *.pem *.config *.srl`
######################################################################################################################################################
