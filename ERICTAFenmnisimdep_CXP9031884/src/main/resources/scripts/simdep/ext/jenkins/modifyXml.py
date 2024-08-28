#!/usr/bin/python
import sys
import os
import xml.etree.ElementTree as ET

inputFileName=sys.argv[1]
outputFileName=sys.argv[2]

tree=ET.parse(inputFileName)
root=tree.getroot()

for e in root.findall('TrustProfile'):
    if e.get('Name') == "ENM_SBI_FCTP_TP":
	   for e1 in e.findall('ExternalCA'):
	       for c in e1.findall('CertificateAuthority'):
		       if c.find('Name').text == "ENM_ExtCA3":
			      e.remove(e1)
tree.write(outputFileName)
