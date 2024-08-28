#!/bin/sh
swapoff -a
mkdir -p /var/lib/swap
dd if=/dev/zero of=/var/lib/swap/swapfile bs=1M count=16000
mkswap /var/lib/swap/swapfile
swapon /var/lib/swap/swapfile
echo "/dev/sda1            swap                 swap       defaults              0 0" > /etc/fstab
echo "/dev/sda2            /                    reiserfs   acl,user_xattr        1 1" >> /etc/fstab
echo "/dev/sdb1 /store reiserfs defaults 0 0" >> /etc/fstab
echo "proc                 /proc                proc       defaults              0 0" >> /etc/fstab
echo "sysfs                /sys                 sysfs      noauto                0 0" >> /etc/fstab
echo "debugfs              /sys/kernel/debug    debugfs    noauto                0 0" >> /etc/fstab
echo "devpts               /dev/pts             devpts     mode=0620,gid=5       0 0" >> /etc/fstab
echo "tmpfs /pms_tmpfs tmpfs rw,size=72G 0 0" >> /etc/fstab
echo  "/var/lib/swap/swapfile    swap    swap    defaults   0  0"  >>  /etc/fstab
swapon -a
swapon -s
updatedSwap=`free -g | grep -w "Swap:" | awk '{print $2}'`
echo "updated swapMemory is $updatedSwap gb";
