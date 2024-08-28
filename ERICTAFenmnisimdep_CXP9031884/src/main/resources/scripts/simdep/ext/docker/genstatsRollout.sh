#!/bin/bash

#####################################################################################
# COPYRIGHT Ericsson 2018
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
#####################################################################################

######################################################################################
# Version no    :  NSS 18.13
# Purpose       :  Script is responsible rollout genstats on netsim docker base image
# Date          :  24/07/2018
# Last Modified :  kumar.dhiraj7@tcs.com
######################################################################################

nssRelease=$1
deplType=$2
genstats_rpm_version=$3
recording_file_version=$4
autorollout_version=$5
nexusLink="https://arm1s11-eiffel004.eiffel.gic.ericsson.se:8443/nexus/"
genStats="${nexusLink}content/repositories/releases/com/ericsson/cifwk/netsim/ERICnetsimpmcpp_CXP9029065/${genstats_rpm_version}/ERICnetsimpmcpp_CXP9029065-${genstats_rpm_version}.rpm"
recordings_files="${nexusLink}content/repositories/nss/com/ericsson/nss/Genstats/recording_files/${recording_file_version}/recording_files-${recording_file_version}.zip"
auto_rollout="${nexusLink}content/repositories/nss/com/ericsson/nss/Genstats/genstatsAutoRollout/${autorollout_version}/genstatsAutoRollout-${autorollout_version}.zip"
miniconda="https://arm901-eiffel004.athtem.eei.ericsson.se:8443/nexus/content/repositories/nss-releases/com/ericsson/nss/Genstats/Miniconda2/21.07.1/Miniconda2-21.07.1.zip"

#zypper install -y which python-pip python-mako ntp expect rsh rsh-server xinetd cronie
#zypper install -y which python-pip python-mako ntp expect

setup_rsh_and_cron()
{
hostfile=/etc/hosts
rsh_file=/etc/pam.d/rsh
eqiv_file=/etc/hosts.equiv
securetty_file=/etc/securetty
rsh_file_xinetd=/etc/xinetd.d/rsh
rlogin_file_xinetd=/etc/xinetd.d/rlogin
rhosts_file=~/.rhosts

IP=`hostname -i`

sed -i '/disable/s/.*/        disable = no/' ${rsh_file_xinetd}
sed -i '/disable/s/.*/        disable = no/' ${rlogin_file_xinetd}

grep "$IP netsim" ${hostfile} > /dev/null
if [ $? -ne 0 ];then
    sed '/netsim/d' ${hostfile} > /tmp/hosts_tmp
    echo "$IP netsim"  >> /tmp/hosts_tmp
    mv /tmp/hosts_tmp ${hostfile}
fi

echo "+ +" > ${eqiv_file}

echo "+ +" > ${rhosts_file}

chmod 600 ${hostfile}
chmod 600 ${rhosts_file}
chmod 600 ${eqiv_file}

grep "rsh" "${securetty_file}"  > /dev/null
if [ $? -ne 0 ];then
    echo "rsh" >> "${securetty_file}"
fi

cat "${rsh_file}" | grep "pam_rhosts.so" | grep "sufficient"  > /dev/null
if [ $? -ne 0 ];then
    sed -i '/pam_rhosts\.so/s/required/sufficient/' "${rsh_file}"
fi

chkconfig rsh on
nohup /usr/sbin/xinetd &
nohup /usr/sbin/cron &
}

setup_rsh_and_cron

cd /tmp
curl -L ${miniconda} -o /netsim/Miniconda2.sh
bash /netsim/Miniconda2.sh -b -p /netsim/miniconda
/netsim/miniconda/bin/conda install -y mako
sudo wget ${genStats}
sudo rm -rf -r /netsim_users
sudo rpm -Uvh --force /tmp/${genStats##*/}
sudo rm ${genStats##*/}
cd / && \
chown netsim:netsim -R netsim_users
cd /netsim_users/pms/bin

mkdir -p /netsim/genstats/
cd /netsim/genstats/
wget ${recordings_files}
unzip -o ${recordings_files##*/}
rm  ${recordings_files##*/}
cd ..
chown netsim:users -R genstats

cd /
mkdir -p pms_tmpfs
chmod 777 pms_tmpfs
cd /tmp
wget ${auto_rollout}
unzip -o ${auto_rollout##*/}
mv netsim_cfg_template /netsim_users/auto_deploy/bin/
chown netsim:netsim /netsim_users/auto_deploy/bin/netsim_cfg_template

expect -c "spawn ssh -oStrictHostKeyChecking=no netsim@netsim; expect 'Password:'; send \"netsim\r\";\
expect 'netsim@netsim:~> ';\
send \"python /netsim_users/auto_deploy/bin/getSimulationData.py\r\";\
expect 'netsim@netsim:~> ';\
send \"mkdir -p /netsim_users/pms/logs/; touch /netsim_users/pms/logs/GetEutranData.log; mkdir /netsim_users/pms/etc/; touch /netsim_users/pms/etc/eutrancellfdd_list.txt\; mkdir /netsim/genstats/logs/rollout_console \r\";\
expect 'netsim@netsim:~> ';\
send \"cd /netsim\r\";\
expect 'netsim@netsim:~> ';\
send \"/netsim_users/auto_deploy/bin/cfgGenerator.py --nssRelease ${nssRelease} --deplType ${deplType} --edeStatsCheck False --ossEnabled False\r\";\
expect 'netsim@netsim:~> ';\
send \"sed -i 's/SET_BANDWIDTH_LIMITING=ON/SET_BANDWIDTH_LIMITING=OFF/g' /tmp/netsim\r\";\
expect 'netsim@netsim:~> ';\
send \"cp /tmp/netsim /netsim/netsim_cfg\r\";\
expect 'netsim@netsim:~> ';\
send \"/netsim_users/pms/bin/GetEutranData.py\r\";\
expect 'netsim@netsim:~> ';\
send \"mkdir -p /netsim_users/pms/xml_templates; mkdir -p  /netsim_users/pms/rec_templates; mkdir -p /netsim/genstats/xml_templates; mkdir /netsim/genstats/logs\r\";\
expect 'netsim@netsim:~> ';\
send \"/netsim_users/auto_deploy/bin/TemplateGenerator.py\r\";\
expect 'netsim@netsim:~> ';\
send \"/netsim_users/pms/bin/pm_setup_stats_recordings.sh -c /netsim/netsim_cfg -b False\r\";\

interact"

