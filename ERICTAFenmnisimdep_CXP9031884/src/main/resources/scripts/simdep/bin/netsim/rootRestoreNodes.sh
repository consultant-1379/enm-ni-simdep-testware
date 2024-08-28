#!/bin/sh

set -o pipefail

if [[ ! -f /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/restore_all_nodes.sh ]]
then
   echo "ERROR: Error restore_all_nodes.sh script node present"
   exit 1
fi

su netsim -c "sh /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/restore_all_nodes.sh | /netsim/inst/netsim_shell"

if [[ $? -ne 0 ]]
then
   echo "ERROR: Error restore of nodes failed"
   exit 1
fi
