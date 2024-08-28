#!/bin/bash

##############################################
#     File Name     : fetchLdapAttributes.sh
#     Version       : 1.00
#     Author        : Mitali Sinha
#######################################################################################
##############################################
#Variable declarations
##############################################
LdapAttributesLog="/var/tmp/LdapAttributes.log"
ENM_URL=$1

#################################################
# Removing LDAP Logs
#################################################
#rm -rf $LdapAttributesLog
#################################################
# Running ldap attributes fetchimg command
#################################################
echo "INFO: Running ldap attributes fetchimg command"
echo "ENM URL= $ENM_URL"
python /var/tmp/runCliCommand.py 'secadm ldap configure --manual' $ENM_URL > $LdapAttributesLog
if [[ $? -ne 0 ]]
then
    echo "ERROR: Executing secadm ldap configure --manual failed."
    exit 201
else
    echo "sucessfully updated"
fi
                chmod 777 $LdapAttributesLog
                cat $LdapAttributesLog

