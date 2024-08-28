#!/usr/bin/python

import urllib2
import os,sys
from os import path
import xml.etree.ElementTree as ET

drop1=sys.argv[1]
drop=drop1.replace(".","-")
network=os.popen("cat /netsim/simdepContents/NRMDetails | grep 'RolloutNetwork' | awk -F '=' '{print $2}'").read().rstrip()
if bool(network):
    if network in "rvModuleLRAN_60KCells_vLarge_NRM1.2" or network in "rvModuleWRAN_10KCells_NRM5" or network in "rvModuleGRAN_30KCells_NRM5":
        try:
           webUrl=urllib2.urlopen("https://arm901-eiffel004.athtem.eei.ericsson.se:8443/nexus/content/repositories/nss/com/ericsson/nss/Ciphers/%s/"%drop)
        except:
           print "ERROR: The patch to skip the ciphers check was not present for rolled out drop %s or unable to get the patch link...Please contact NSS team"%drop1
           sys.exit(1)
        data = webUrl.read().decode("utf-8")
        start_index = data.find("<a href=\"https:")
        end_index = data.find("</a>",start_index)
        tmpLink = data[start_index:end_index]
        patchName = tmpLink.split(">")[-1].replace("/","")
        downloadxml = "wget -O maven-metadata.xml https://arm901-eiffel004.athtem.eei.ericsson.se:8443/nexus/content/repositories/nss/com/ericsson/nss/Ciphers/%s/%s/maven-metadata.xml"%(drop,patchName)
        os.system(downloadxml)
        if path.getsize('maven-metadata.xml'):
           tree = ET.parse('maven-metadata.xml')
           root = tree.getroot()
           version=""
           for element in root.findall('versioning'):
               version = element.find("release").text
           print version
           downloadPatch = "wget -O /netsim/inst/%s.zip https://arm901-eiffel004.athtem.eei.ericsson.se:8443/nexus/content/repositories/nss/com/ericsson/nss/Ciphers/%s/%s/%s/%s-%s.zip"%(patchName,drop,patchName,version,patchName,version)
           link="https://arm901-eiffel004.athtem.eei.ericsson.se:8443/nexus/content/repositories/nss/com/ericsson/nss/Ciphers/%s/%s/%s/%s-%s.zip"%(drop,patchName,version,patchName,version)
           print link
           os.system(downloadPatch)
           install = "echo -e '.install patch %s.zip\n' | su netsim -c /netsim/inst/netsim_shell"%patchName
           output = os.popen(install).read()
           if "OK" in output:
               print "INFO: Patch to skip ciphers check was installed"
               print output
               fp=open("/netsim/simdepContents/NetsimPatches_CXP9032769.Urls","a")
               fp.write('url = "'+link+'"\n')
               fp.close()
           else:
               print "ERROR: Unable to install the patch to skip the ciphers check"
               print output
               sys.exit(1)
        else:
           print "ERROR: The patch to skip ciphers check was not present for rolled out drop %s....Please contact NSS team for further information"%drop1
           sys.exit(1)
    else:
        print "INFO: patch to skip ciphers check was not needed for module %s"%network
else:
    print "INFO: unable to get the network name as NRMDetails file was not present in simdepcontents"
