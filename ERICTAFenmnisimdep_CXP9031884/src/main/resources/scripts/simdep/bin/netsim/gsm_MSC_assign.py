from multiprocessing import Pool
import sys
from xml.dom import minidom
import time,subprocess,os,sys,warnings
warnings.filterwarnings("ignore")
def write_file(elem,count,simName):
  cmd="rm -rf /netsim/node_%d_out.txt ; touch /netsim/node_%d_out.txt ; chmod 777 /netsim/node_%d_out.txt" %(count,count,count)
  print("count in function",count)
  os.system(cmd)
  file=open("/netsim/node_%d_out.txt" %count,"w")
  file.write(elem.toxml())
  file.close()
  assigIp="sh /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/gsmAssignIp.sh /netsim/node_%d_out.txt %s " %(count,simName)
  os.system(assigIp)
  #sys.stdout.close()
simName=sys.argv[1]
file = minidom.parse('/netsim/netsimdir/exported_items/%s_fetcher_create.xml' %(simName)) 
ME = file.getElementsByTagName('IPAddressing')
count=1
for elem in ME:
  print(count)
  print(elem.toxml())
  write_file(elem,count,simName)
  count+=1

