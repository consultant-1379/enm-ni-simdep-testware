######################################################################################
#     File Name     : updateTrustProfileForVapp_1.sh
#     Author        : Surabhi Ravi Teja
#     Description   : Setup Script to update trust profiles at ENM Side
#     Date Created  : 06 Nov 2019
#######################################################################################

export GatewayServer=$nodeIP

/usr/bin/expect <<EOF
    set timeout -1
	spawn scp -rp -o StrictHostKeyChecking=no $WORKSPACE/ERICTAFenmnisimdep_CXP9031884 root@${GatewayServer}:/var/tmp/
       expect {
            -re assword: {send "shroot\r";exp_continue}
        }
	sleep 120
    spawn ssh -o StrictHostKeyChecking=no root@${GatewayServer} /var/tmp/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/updateTrustProfileForVapp_TAF.sh
       expect {
            -re assword: {send "shroot\r";exp_continue}
		}
	sleep 120
EOF


echo "INFO: Copying  from $GatewayServer:/var/tmp/trustProfile.log and /var/tmp/crlUpdate.log to $WORKSPACE"
/usr/bin/expect  <<EOF
	spawn scp -rp -o StrictHostKeyChecking=no root@${GatewayServer}:/var/tmp/trustProfile.log ${WORKSPACE}
		expect {
			-re assword: {send "shroot\r";exp_continue}
		}
	sleep 5
	spawn scp -rp -o StrictHostKeyChecking=no root@${GatewayServer}:/var/tmp/crlUpdate.log ${WORKSPACE}
                expect {
                        -re assword: {send "shroot\r";exp_continue}
                }
        sleep 5
EOF

if [ -f "$WORKSPACE/crlUpdate.log" ];
then
        OUTPUT=`cat $WORKSPACE/crlUpdate.log | grep "updated successfully"`

        if [ ! -z "$OUTPUT" -a "$OUTPUT"!=" " ]; then
                echo "CRL is successfully updated"
        else
                echo "CRL is not successfully updated"
                exit 1
        fi
else
        echo "CRL is not successfully updated"
        exit 1
fi

if [ -f "$WORKSPACE/trustProfile.log" ];
then 
	OUTPUT=`cat $WORKSPACE/trustProfile.log | grep "sucessfully updated"`

	if [ ! -z "$OUTPUT" -a "$OUTPUT"!=" " ]; then
		echo "Trust Profile is successfully updated"
		echo "INFO: Waiting for credm Job to run. Sleeping for 20 minutes"
		sleep 20m
	else
		echo "Trust Profile is not successfully updated"
		exit 1
	fi
else
	echo "Trust Profile is not successfully updated"
	exit 1
fi
