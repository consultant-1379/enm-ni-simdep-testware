#!/usr/bin/python

import time, sys, os
script, cluster = sys.argv
file_name=cluster+".txt"
url="wget -q -O " + file_name + " https://ci-portal.seli.wh.rnd.internal.ericsson.com/generateTAFHostPropertiesJSON/?clusterId=" + cluster + "&tunnelNetsim=true&tunnel=true&pretty=1"
os.popen(url)
time.sleep(20)
fd = open(file_name,"r+")
for line in fd.readlines():
        url = line.split("haproxy")[1].split('"ipv4": "')[1].split('"')[0]
print url
remove = "rm -rf "+ file_name
os.popen(remove)
