#!/bin/sh

tafServer="tafexem1"

/usr/bin/expect <<EOF
    set timeout -1
        spawn scp -rp -o StrictHostKeyChecking=no /var/tmp/ERICTAFenmnisimdep_CXP9031884 root@${tafServer}:/var/tmp/
       expect {
            -re assword: {send "shroot\r";exp_continue}
        }
        sleep 120
    spawn ssh -o StrictHostKeyChecking=no root@${tafServer} /var/tmp/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/updateTrustProfileForVapp_2.sh
       expect {
            -re assword: {send "shroot\r";exp_continue}
                }
        sleep 480
EOF

echo "INFO: Copying  from $tafServer:/var/tmp/trustProfile.log and /var/tmp/crlUpdate.log to GatewayServer $GatewayServer"
/usr/bin/expect  <<EOF
        spawn scp -rp -o StrictHostKeyChecking=no root@${tafServer}:/var/tmp/trustProfile.log /var/tmp/
                expect {
                        -re assword: {send "shroot\r";exp_continue}
                }
        sleep 5
	spawn scp -rp -o StrictHostKeyChecking=no root@${tafServer}:/var/tmp/crlUpdate.log /var/tmp/
                expect {
                        -re assword: {send "shroot\r";exp_continue}
                }
        sleep 5
EOF
