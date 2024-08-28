#!/usr/bin/python
import os
print "INFO: Checking if any node is stopped"
stoppedNodes = os.popen("echo '.show allsimnes' | /netsim/inst/netsim_shell | grep started | grep -v 'n/a' | wc -l").read()
if int(stoppedNodes) == 0:
    print "INFO: All nodes are started"
else:
    print "ERROR: Few nodes are in stopped state"
print "INFO: Checking for PM Subscription"
genstatsCheck=os.popen("crontab -l | grep pm | wc -l").read()
if int(genstatsCheck) >> 0:
    print "INFO: PM Subscription applied"
else:
    print "ERROR: No PM Subscription"
print "INFO: Check if all simulations are rolled out"
simulationCount=os.popen("echo '.show simulations' | /netsim/inst/netsim_shell | grep -v 'simulations' | grep -v 'default' | wc -l").read()
if int(simulationCount) == 4:
    print "INFO: All Simulations successfully rolledout"
else:
    print "ERROR: Few Simulations Missing"
if int(stoppedNodes) != 0:
    print "Following Simulations are in stopped state:"
    stoppedNodes = os.popen("echo '.show allsimnes' | /netsim/inst/netsim_shell | grep started | grep -v 'n/a' | awk '{print $1}'").read()
    print stoppedNodes
