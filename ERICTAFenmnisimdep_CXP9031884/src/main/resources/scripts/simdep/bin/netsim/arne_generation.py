#!/usr/bin/python
import os,sys
############################################################################

#Author: I Chaitanya <zchaill>
#Date: 4-sep-2018
#Description: This is to generate ARNE xml during simdep rollout   

############################################################################
def generate_ARNE_XML(target_simulation,password):
    action="started"
    output="skipped"
    cmd=CREATE_SIMULATION_XML_FILE_CMD.format(sim=target_simulation, password=password)
    output=os.popen(cmd).read()
    if "valid" in output:
          stmt="INFO:ARNE XML creation is successful for {0}".format(target_simulation)
          action="created"
          print stmt
    else:
          stmt="ERROR:ARNE XML creation has been failed for {0}".format(target_simulation)
          action="failed"
          print stmt
    fh=open("{0}/{1}".format(LOG_PATH,LOG_FILE),"a")
    fh.write("{0}:{1}".format(target_simulation,action))
    fh.close()
    if "skipped" in output:
        stmt="INFO:ARNE XML creation is skipped for {0}".format(target_simulation)
        action="not needed"
        print stmt

simsList=sys.argv[1]
pathSpecifier=sys.argv[2]
CREATE_SIMULATION_XML_FILE_CMD = "bash -c \"echo .open {sim}; echo .select network; echo .createarne R12.2 {sim}_fetcher NETSim %nename {password} IP secure sites no_external_associations defaultgroups\" | /netsim/inst/netsim_pipe -stop_on_error"
LOG_PATH="/tmp/ARNE_LOGS/"
date=os.popen("date | awk '{print $4}'").read()
LOG_FILE="ArneLogs_{0}".format(date.strip("\n"))
cmd="mkdir -p {0}".format(LOG_PATH)
os.system(cmd)
print "INFO:LOG PATH IS CREATED TO %s"%(LOG_PATH)
cmd="touch {0}/{1}".format(LOG_PATH,LOG_FILE)
os.system(cmd)
cmd="pwd"
if "no" in pathSpecifier:
    WORKDIR=(os.popen(cmd).read()).strip("\n")
else:
    WORKDIR="/var/simnet/enm-ni-simdep/scripts/simdep/bin"
#cmd="cat %s/../conf/arne.properties"%(WORKDIR)
#list=os.popen(cmd).read()
#regexList=list.split(",")
generate_ARNE_XML(simsList,"netsim")
