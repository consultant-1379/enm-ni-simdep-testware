#!/bin/sh

fileContent="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAqrgQB2buZMhhhS25MK8P/3kyCzTSllZnk4j6qaVio/ipo1ftP2P//8kTBbVmnYorCSmaRMV5E6cWK2ECd4yfjogxa1tqIGKvyILeMj96adkVTJCz4diK6LL8K3F+mxkczAucJAtE+CZL1DXWHjU4CxtndnfYFxz7Ry0zAxu54biyAvC9kCW1aPyBE+LfcU7PUey12V8dDABrFMlSC3mwKgPBp0tFSINzoMR+UZn92T7ukACbRrqR+vXTd3B70rT3BZd29nMFE9mH/PoXJk1A69CXZBEisd+eQDwDaljv1Z4kbaI98GtWc9Qr88TVu+GeFrtpNN1o8pexxmdQ8qjYIQ== root@ieatlms4407"
PWD=`pwd`

if [[ $# -ne 1 ]]
then
    echo -e "Invalid Arguments\nUsage:sh configPublicKey.sh simName"
    exit 1
fi
sim=$1
nodeNames=`echo -e '.open '$sim'\n.show simnes\n' | /netsim/inst/netsim_shell | grep -vE 'OK|NE|>>' | cut -d ' ' -f1`
for nodeName in ${nodeNames[@]}
do
   cd /netsim/netsim_dbdir/simdir/netsim/netsimdir/${sim}/${nodeName}/fs
   mkdir -p .ssh
   echo $fileContent > .ssh/authorized_keys
   chmod 600 .ssh/authorized_keys
done
cd ${PWD}
echo "Configured public key for the nodes present in $sim"