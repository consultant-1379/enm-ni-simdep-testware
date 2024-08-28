#!/usr/bin/env expect

# Created by  : Fatih Onur
# Created on  : 2016.07.06

### VERSION HISTORY
# Purpose     : To execute commands as s root user
# Description : Development and testing of simulations
# Date        : 07 July 2016
# Who         : Fatih Onur

############################################################
#Switching root user to execute given command
###########################################################

set cmd [lindex $argv 0]

spawn su root -c $cmd
expect {
    "Password:" {
        send "shroot\r"
        exp_continue
    }
    eof { exit }
}