#!/usr/bin/env expect

# Created by  : Komal Chowdhary
# Created on  : 27.11.2014

### VERSION HISTORY
# Version     : 1.0
# Purpose     : To invoke expect environment from bash script 
# Date        : 27 NOV 2014
# Who         : Komal Chowdhary




###############################################
#Set some Variables
###############################################
set timeout -1
set user root
set host ossmaster
set netsim_user netsim
set netsim_host netsim

#########################################
#FTP the CleanOss script to ossmaster server
##########################################

#expect command is used to automate control of interactive applications such as telnet ,ftp, ssh.
spawn ftp $host
expect "Name (ossmaster:netsim):"
send "$user\r"
expect "Password:"
send "shroot\r"
expect "ftp>"
send "bin\r"
expect "ftp>"
send " cd /home/nmsadm\r"
expect "ftp>"
send "put cOss.sh\r"
expect "ftp>"
send "bye\r"
expect eof

###############################################
#Change the permissions of the cleanOss script
###############################################

spawn ssh $user@$host chmod u+x /home/nmsadm/cOss.sh 

while {1} {
  expect {

    eof                          {break}
    "The authenticity of host"   {send "yes\r"}
    "Password:"                  {send "shroot\r"}
    "*\]"                        {send "exit\r"}
  }
}
wait

###############################################
#Execute the cleanOss script
###############################################

spawn ssh $user@$host /home/nmsadm/cOss.sh

while {1} {
  expect {
 
    eof                          {break}
    "The authenticity of host"   {send "yes\r"}
    "Password:"                  {send "shroot\r"}
    "*\]"                        {send "exit\r"}
  }
}
wait

exit


