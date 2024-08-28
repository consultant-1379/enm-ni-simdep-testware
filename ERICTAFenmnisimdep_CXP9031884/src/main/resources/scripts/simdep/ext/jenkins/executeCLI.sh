#!/bin/bash
sshhost=$1
user=$2
password=$3
command=$4
shift 4
echo $command
/usr/bin/expect <<EOF
spawn -noecho ssh -t -o UserKnownHostsFile=/dev/null -o CheckHostIP=no -o StrictHostKeyChecking=no -l $user $sshhost $command
set timeout 60
expect {
         "*password*"  {
              send "12shroot\r"
          exp_continue
    }
  timeout { send_user "\nFailed to get password prompt\n"; exit 0 }
    eof { send_user "\nPassword is already enabled\n"; exit 0 }
      "*Username*"  {
              send "administrator\r"
          exp_continue
    }
    timeout { send_user "\nFailed to get password prompt\n"; exit 1 }
    eof { send_user "\nPassword is already enabled\n"; exit 1 }
    "*Password*" {
         send "TestPassw0rd\r"
        }
}
expect eof
EOF
