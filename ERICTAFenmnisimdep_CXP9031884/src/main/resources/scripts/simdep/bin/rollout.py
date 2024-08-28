#!/usr/bin/python
###################################################################################
#
#     File Name : rollout.py
#
#     Version : 1.00
#
#     Author : Harsha Yeluru
#
#     Description : This script will rollout the network in parallel for Feature Test
#
#     Date Created : 15th March, 2018
#
#     Syntax : ./rollout.py
#
#     Patameters :
#          -overwrite - yes/no - to overwrite the flags present in conf file
#          -release - release version
#          -serverType - VM/VAPP - Type of server on which rollout is performed
#          -deploymentType - Type of deployment
#          -simLTE/ -simCORE/ -simWRAN - LTE/CORE/WRAN simulations to be rolled out separated by ':' resp. NO_NW_AVAILABLE if no sim to rollout
#          -securityTLS/ -securitySL2 - on/off - Add security to simulation post rollout
#          -ciPortal - yes - To fetch sims from CI Portal
#          -docker - yes/no - Whether the rollout is for Docker or VM
#          -image_build - yes/no - Whether the rollout is for Image_build or VM
#          -switchToRv - yes/no - Whether the rollout performed is for RV or MT
#
#
#     Example : ./rollout.py  -overwrite -release 18.08 -serverType VM -deploymentType mediumDeployment -simLTE LTE17-Q4-V2x80-60K-DG2-FDD-LTE61:LTE17-Q4-V2x80-60K-DG2-FDD-LTE62 -simWRAN NO_NW_AVAILABLE -simCORE NO_NW_AVAILABLE ${simPath} -securityTLS on -securitySL2 on -masterServer 131.160.129.152 -ciPortal yes -docker no -switchToRv yes
#
#     Return Values : 1 - Stautus - ONLINE / OFFLINE  
#
###################################################################################
#
from multiprocessing import Pool
import time,subprocess,os,sys,warnings
warnings.filterwarnings("ignore")
input_args = sys.argv[1:]
deploymentType, release, serverType, switchToRv ,IPV6Per ,installType, docker,image_build, rolloutType = input_args[input_args.index("-deploymentType")+1], input_args[input_args.index("-release")+1], input_args[input_args.index("-serverType")+1], input_args[input_args.index("-switchToRv")+1], input_args[input_args.index("-IPV6Per")+1], input_args[input_args.index("-installType")+1], input_args[input_args.index("-docker")+1], input_args[input_args.index("-image_build")+1],  input_args[input_args.index("-rolloutType")+1]
default_args =  input_args[0:input_args.index("-simLTE")]
default_args1 = input_args[input_args.index("-simCORE")+2:]
default_item,default_item1="",""
for item in default_args:
        default_item = default_item + " " + item
for item in default_args1:
        default_item1 = default_item1 + " " + item
def downloadSims(simName):
        for simLoc in simLocList:
                if simName+"-" in simLoc:
                        simDownload= "wget -O /netsim/netsimdir/%s.zip %s" %(simName, simLoc)
                        os.system(simDownload)
        return "INFO: Download %s successful" %(simName)
def getData(simName):
    if "no" in docker:
        createMML = "touch ../dat/MML.mml; chmod 777 ../dat/MML.mml"
        os.system(createMML)
        for simLoc in simLocList:
                if simName+"-" in simLoc:
                        simZip = simLoc.split("/")[-1].split('"')[0]
                        runFetchOpen= "su netsim -c './fetchOpenSim.pl " + simName + " " + simLoc.strip("\n") + " " + simName + ".zip no'"
                        runFetchOpenOutput=os.popen(runFetchOpen).read()
        if "Conflicts with already installed files" in runFetchOpenOutput:
                runFetchOpen= "su netsim -c './fetchOpenSim.pl " + simName + " " + simLoc.strip("\n") + " " + simName + ".zip yes'"
                os.system(runFetchOpen)
    neType=getNeType(simName)       
    return neType
def getNeType(simName):
    simInfoFile = simName + ".txt"
    clearMML = "rm -rf ../dat/MML.mml; touch ../dat/MML.mml; chmod 777 ../dat/MML.mml; touch ../dat/dumpNeName.txt ../dat/dumpNeType.txt ../dat/listNeName.txt ../dat/listNeType.txt; chmod 777 ../dat/dumpNeName.txt ../dat/dumpNeType.txt ../dat/listNeName.txt ../dat/listNeType.txt"
    os.system(clearMML)
    runReadSimData = "su netsim -c './netsim/readSimData.pl " + simName + ".zip " + docker + "' > " + simInfoFile
    readSimDataOutput=os.popen(runReadSimData).read()
    if "Error" in readSimDataOutput:
        print "ERROR:Error while reading Sim. Retrying..."
        readSimDataOutput=os.popen(runReadSimData).read()
        if "Error" in readSimDataOutput:
                   sys.exit(1)
    if simName not in WRAN_simsList:
        getNeType = "chmod 777 %s; cat %s | grep 'neType' | sort -nk 4|head -1"%(simInfoFile, simInfoFile)
        result = os.popen(getNeType).read()
        neType = '"' + result.split("neName = ")[1].split(" neTypeFull = ")[1].split("\n")[0] + '"'
    else:
        getNeType1 = "chmod 777 %s; cat %s | grep 'neType' | sort -nk 4| sed -n '1p'"%(simInfoFile, simInfoFile)
        getNeType2 = "chmod 777 %s; cat %s | grep 'neType' | sort -nk 4| sed -n '2p'"%(simInfoFile, simInfoFile)
        result = os.popen(getNeType1).read()
        neType1 = '"' + result.split("neName = ")[1].split(" neTypeFull = ")[1].split("\n")[0] + '"'
        try:
               result = os.popen(getNeType2).read()
               neType2 = '"' + result.split("neName = ")[1].split(" neTypeFull = ")[1].split("\n")[0] + '"'
               neType = neType1 + ":" + neType2
        except:
               neType = neType1
               removeMML = "rm -rf ../dat/MML.mml; touch ../dat/MML.mml; chmod 777 ../dat/MML.mml"
               os.system(removeMML)
    return neType
def fetchipcount(simName, neType):
        global release, switchToRv
        createDatFiles = "touch ../dat/ipVars.dat ../dat/dumpDecisionParams.txt; chmod 777 ../dat/ipVars.dat ../dat/dumpDecisionParams.txt"
        os.system(createDatFiles)
        runDecisionModule = "su netsim -c './netsim/decisionModule.pl %s %s %s off %s %s'" %(simName,neType, release, IPV6Per, switchToRv)
        decisionModuleOutput = os.popen(runDecisionModule).read()
        if "Error" in decisionModuleOutput:
                print "ERROR:Error while running decisionModule. Retrying..."
                decisionModuleOutput = os.popen(runDecisionModule).read()
                if "Error" in decisionModuleOutput:
                        sys.exit(1)
        ipv4_count = int(decisionModuleOutput.split("numOfIpv4Nes= ")[1].split(" \n")[0])
        ipv6_count = int(decisionModuleOutput.split("numOfIpv6Nes= ")[1].split(" \n")[0])
        removeDatFiles = "rm -rf ../dat/MML.mml; touch ../dat/MML.mml; chmod 777 ../dat/MML.mml; rm -rf ../dat/dumpNeName.txt ../dat/dumpNeType.txt ../dat/listNeName.txt ../dat/listNeType.txt"
        os.system(removeDatFiles)
        return ipv4_count,ipv6_count
def fetchips(simName, ipv4_count, ipv6_count, type):
        createTempIpv4Files = "touch /tmp/%s_ipv4.txt ../dat/tmp1.txt; head -%d ../dat/avail_IpAddr_IPv4.txt > /tmp/%s_ipv4.txt; tail -n +%d ../dat/avail_IpAddr_IPv4.txt > ../dat/tmp1.txt" %(simName, int(ipv4_count), simName, int(ipv4_count)+1)
        os.system(createTempIpv4Files)
        cmd="cat /tmp/%s_ipv4.txt | wc -l" %(simName)
        check_Ipv4=int(os.popen(cmd).read())
        if check_Ipv4 < int(ipv4_count):
           print "ERROR: Server does not have sufficient ipv4 ips"
           sys.exit(1)
        moveIpv4FilesToDat = "mv ../dat/tmp1.txt ../dat/avail_IpAddr_IPv4.txt; mkdir -p /tmp/%s/%s/simNetDeployer/%s/dat/; cp /tmp/%s_ipv4.txt /tmp/%s/%s/simNetDeployer/%s/dat/free_IpAddr_IPv4.txt" %(type, simName, release, simName, type, simName, release)
        os.system(moveIpv4FilesToDat)
        createTempIpv6Files = "touch /tmp/%s_ipv6.txt ../dat/tmp.txt; head -%d ../dat/avail_IpAddr_IPv6.txt > /tmp/%s_ipv6.txt; tail -n +%d ../dat/avail_IpAddr_IPv6.txt > ../dat/tmp.txt" %(simName, int(ipv6_count), simName, int(ipv6_count)+1)
        os.system(createTempIpv6Files)
        cmd="cat /tmp/%s_ipv6.txt | wc -l" %(simName)
        check_Ipv6=int(os.popen(cmd).read())
        if check_Ipv6 < int(ipv6_count):
           print "ERROR: Server does not have sufficient ipv6 ips"
           sys.exit(1)
        moveIpv6FilesToDat = "mv ../dat/tmp.txt ../dat/avail_IpAddr_IPv6.txt; cp /tmp/%s_ipv6.txt /tmp/%s/%s/simNetDeployer/%s/dat/free_IpAddr_IPv6.txt" %(simName, type, simName, release)
        os.system(moveIpv6FilesToDat)
def createPort(simName):
        getDD="head -1 /tmp/%s_ipv4.txt" %(simName)
        ddIp=os.popen(getDD).read().strip()
        createMML = "touch MML.mml; chmod 777 MML.mml"
        os.system(createMML)
        runCreatePort="su netsim -c './netsim/createPort.pl %s %s'" %(ddIp, docker)
        os.system(runCreatePort)
        removeMML = "rm -rf MML.mml"
        os.system(removeMML)
def startNodes(simName):
    neType=simToNeType[simName]
    if simName != "None" and simName != "NO_NW_AVAILABLE":
        createMML = "touch /var/%s_start.mml; chmod 777 /var/%s_start.mml; touch /var/Tacacs_%s.mml; chmod 777 /var/Tacacs_%s.mml"%(simName,simName,simName,simName)
        os.system(createMML)
        print "INFO:Starting Nodes for %s"%(simName)
        print neType
        runStartNes = "su netsim -c '../utils/netsim/startNes.pl -simName %s -all -neTypesFull "%(simName) +'"' +neType+'" -deploymentType '+ deploymentType +' -rv '+ switchToRv +"'"
        print runStartNes
        contentFileCmd="ls /netsim/simdepContents | grep content"
        contentFiles=os.popen(contentFileCmd).read()
        if "Simnet_1_8K_CXP9034760" in contentFiles:
             runStartNes = "su netsim -c '../utils/netsim/startNes.pl -simName %s -neTypesFull "%(simName) +'"' +neType+'" -deploymentType '+ deploymentType +' -rv '+ switchToRv +"'"
             startNes=""
             setLoadBal=os.popen(runStartNes).read()
             print setLoadBal
        else:
            runStartNes = "su netsim -c '../utils/netsim/startNes.pl -simName %s -all -neTypesFull "%(simName) +'"' +neType+'" -deploymentType '+ deploymentType +' -rv '+ switchToRv +"'"
            startNes=os.popen(runStartNes).read()
        removeMML = "rm -rf /var/%s_start.mml /var/Tacacs_%s.mml"%(simName,simName)
        os.system(removeMML)
        createMML =  "touch /var/%s_start.mml; chmod 777 /var/%s_start.mml; touch /var/Tacacs_%s.mml; chmod 777 /var/Tacacs_%s.mml"%(simName,simName,simName,simName)
        os.system(createMML)
        if "Error" in startNes:
            print "ERROR:Error starting nodes. Retrying..."
            runStartNes = "su netsim -c '../utils/netsim/startNes.pl -simName %s -all -neTypesFull "%(simName) +'"' +neType+'" -deploymentType '+ deploymentType +"'"
            startNes=os.popen(runStartNes).read()
            removeMML = "rm -rf /var/%s_start.mml /var/Tacacs_%s.mml"%(simName,simName)
            os.system(removeMML)
            createMML =  "touch /var/%s_start.mml; chmod 777 /var/%s_start.mml; touch /var/Tacacs_%s.mml; chmod 777 /var/Tacacs_%s.mml"%(simName,simName,simName,simName)
            os.system(createMML)
            if "Error" in startNes:
                print "ERROR:Error while starting Simulation %s. Retrying Rollout"%(simName)
                print startNes
                rollout(simName)
                print "INFO:Starting Nodes for %s"%(simName)
                runStartNes = "su netsim -c '../utils/netsim/startNes.pl -simName %s -all -neTypesFull "%(simName) +'"' +neType+'" -deploymentType '+ deploymentType +' -rv '+ switchToRv +"'"
                print runStartNes
                startNes=os.popen(runStartNes).read()
                if "Error" in startNes:
                        print startNes
                        return "ERROR: %s : OFFLINE"%(simName)
                else:
                        print "INFO:Simulation %s started successfully"%(simName)
                        return "INFO: %s : ONLINE"%(simName)
        else:
                print "INFO:Simulation %s started successfully"%(simName)
                print startNes
                return "INFO: %s : ONLINE"%(simName)
        removeMML = "rm -rf /var/%s_start.mml /var/Tacacs_%s.mml"%(simName,simName)
        os.system(removeMML)
def rollout(simName):
        global default_item,default_item1,release
        if simName in CORE_simsList:
                triggerRollout = './invokeSimNetDeployer.pl '+ default_item + ' -simLTE "" -simWRAN "" -simCORE ' + simName + default_item1.replace("NO_NW_AVAILABLE","") + ">>" + simName +".log"
                subprocess.call(triggerRollout,shell=True)
                checkRolloutStatus = "cat /tmp/CORE/%s/simNetDeployer/%s/logs/final*.txt | grep ONLINE" %(simName,release)
                output = os.popen(checkRolloutStatus).read()
                if output =="":
                        print "INFO:Retrying  simulation rollout. \n"
                        subprocess.call(triggerRollout,shell=True)
                checkSecurityStatus ="cat /tmp/CORE/%s/simNetDeployer/%s/logs/*setUpSecurity* | grep 'Create or modify of NE type not in progress'"%(simName, release)
                checkSecurityStatusOutput = os.popen(checkSecurityStatus).read()
                if checkSecurityStatusOutput !="":
                        subprocess.call(triggerRollout,shell=True)
        elif simName in LTE_simsList:
                triggerRollout = './invokeSimNetDeployer.pl' + default_item+' -simLTE ' + simName +' -simCORE "" -simWRAN ""' + default_item1.replace("NO_NW_AVAILABLE","") + ">>" + simName +".log"
                subprocess.call(triggerRollout,shell=True)
                checkRolloutStatus = "cat /tmp/LTE/%s/simNetDeployer/%s/logs/final*.txt | grep ONLINE" %(simName, release)
                output = os.popen(checkRolloutStatus).read()
                if output =="":
                        print "INFO:Retrying  simulation rollout. \n"
                        subprocess.call(triggerRollout,shell=True)
                checkSecurityStatus ="cat /tmp/LTE/%s/simNetDeployer/%s/logs/*setUpSecurity* | grep 'Create or modify of NE type not in progress'"%(simName, release)
                checkSecurityStatusOutput = os.popen(checkSecurityStatus).read()
                if checkSecurityStatusOutput !="":
                        subprocess.call(triggerRollout,shell=True)
        elif simName in WRAN_simsList:
                triggerRollout = './invokeSimNetDeployer.pl' + default_item + ' -simWRAN '+simName+' -simCORE "" -simLTE ""' + default_item1.replace("NO_NW_AVAILABLE","") + ">>" + simName +".log"
                subprocess.call(triggerRollout,shell=True)
                checkRolloutStatus = "cat /tmp/WRAN/%s/simNetDeployer/%s/logs/final*.txt | grep ONLINE" %(simName, release)
                output = os.popen(checkRolloutStatus).read()
                if output =="":
                        print "INFO:Retrying  simulation rollout. \n"
                        subprocess.call(triggerRollout,shell=True)
                checkSecurityStatus ="cat /tmp/WRAN/%s/simNetDeployer/%s/logs/*setUpSecurity* | grep 'Create or modify of NE type not in progress'"%(simName, release)
                checkSecurityStatusOutput = os.popen(checkSecurityStatus).read()
                if checkSecurityStatusOutput !="":
                        subprocess.call(triggerRollout,shell=True)
        if "ONLINE" in output:
                status = simName + ":ONLINE"
        else:
                status = simName + ":OFFLINE"
def getAllNeTypes(simName, simType):
        printDumpNeType="cat /tmp/%s/%s/simNetDeployer/%s/dat/dumpNeType.txt"%(simType, simName, release)
        dumpNeTypeOutput, neTypes = list(set(os.popen(printDumpNeType).read().split("\n"))), ""
        print dumpNeTypeOutput
        for item in dumpNeTypeOutput:
            if neTypes != "":
                neTypes = neTypes + ":" + item
            else:
                neTypes = item
        print neTypes
        return neTypes
clearTmp = "rm -rf /tmp/CORE/* /tmp/LTE/* /tmp/WRAN/*"
os.system(clearTmp)
getSimnetContents = "ls /netsim/simdepContents/Simnet*content"
result = os.popen(getSimnetContents).read()
if "no" in docker:
   runShowIps = "sh ../utils/netsim/showIPs.sh ../ %s"%(rolloutType)
   os.system(runShowIps)
   usedIpsCmd="../utils/netsim/checkUsedIps.sh %s"%(rolloutType)
   os.system(usedIpsCmd)
   usedIpsCmd1="cat ../dat/avail_IpAddr_IPv4.txt ../dat/used_IpAddr_IPv4.txt | sort | uniq -u > ../dat/temp.txt; mv ../dat/temp.txt ../dat/avail_IpAddr_IPv4.txt"
   os.system(usedIpsCmd1)
   usedIpsCmd2="cat ../dat/avail_IpAddr_IPv6.txt ../dat/used_IpAddr_IPv6.txt | sort | uniq -u > ../dat/temp6.txt; mv ../dat/temp6.txt ../dat/avail_IpAddr_IPv6.txt"
   os.system(usedIpsCmd2)
createSimsList="touch /netsim/simdepContents/simsList.txt; chmod 777 /netsim/simdepContents/simsList.txt"
os.system(createSimsList)
simsList, CORE_simsList, LTE_simsList, WRAN_simsList, simLocList=[], [], [], [], []
simsFileDesc=open(result.strip("\n"),"r")
for simLoc in simsFileDesc.readlines():
        simLocList.append(simLoc)
if "-simCORE" in input_args:
        CORE_sims=input_args[(input_args.index("-simCORE"))+1]
        CORE_simsList=CORE_sims.split(':')
        CORE_simsList=filter(lambda a: a != "NO_NW_AVAILABLE", CORE_simsList)
        simsList+=CORE_simsList
if "-simLTE" in input_args:
        LTE_sims = input_args[(input_args.index("-simLTE"))+1]
        LTE_simsList = LTE_sims.split(':')
        LTE_simsList=filter(lambda a: a != "NO_NW_AVAILABLE", LTE_simsList)
        simsList+=LTE_simsList
if "-simWRAN" in input_args:
        WRAN_sims = input_args[(input_args.index("-simWRAN"))+1]
        WRAN_simsList = WRAN_sims.split(':')
        WRAN_simsList=filter(lambda a: a != "NO_NW_AVAILABLE", WRAN_simsList)
        simsList+=WRAN_simsList
if "no" in docker:
    if "offline" in installType:
        mvcmd="mv /netsim/simsZip/* /netsim/netsimdir/ "
        os.system(mvcmd)
    else:
        pool = Pool(processes=len(simsList))
        print(pool.map(downloadSims, simsList))
        pool.terminate()
simToNeType={}
for sim in CORE_simsList:
                print "INFO:Fetching info for ",sim
                neType = getData(sim)
                ip_count = fetchipcount(sim, neType)
                fetchips(sim,ip_count[0],ip_count[1],"CORE")
for sim in LTE_simsList:
                print "INFO:Fetching info for ",sim
                neType = getData(sim)
                ip_count = fetchipcount(sim, neType)
                fetchips(sim,ip_count[0],ip_count[1], "LTE")
for sim in WRAN_simsList:
                print "INFO:Fetching info for ",sim
                neType = getData(sim)
                ip_count = fetchipcount(sim, neType)
                fetchips(sim,ip_count[0],ip_count[1], "WRAN")
createPort(simsList[0])
pool = Pool(processes=20)
pool.map(rollout, simsList)
pool.terminate()
for sim in CORE_simsList:
                simToNeType[sim]=getAllNeTypes(sim, "CORE")
for sim in LTE_simsList:
                simToNeType[sim]=getAllNeTypes(sim, "LTE")
for sim in WRAN_simsList:
                simToNeType[sim]=getAllNeTypes(sim, "WRAN")
for sim in simsList:
        printLog = "cat %s.log"%(sim)
        print os.popen(printLog).read()
        tlsFP=open("/netsim/simdepContents/SimsTLSCheck.txt","a+")
        certsFp=open("/netsim/simdepContents/SimsCertsCheck.txt","a+")
        statement="INFO: Applied Latest TLS versions for %s sim"%(sim)
        statement1="INFO: Applied New certs for %s sim"%(sim)
        tlsFP.write(statement)
        tlsFP.write("\n")
        certsFp.write(statement1)
        certsFp.write("\n")
contentFileCmd="ls /netsim/simdepContents | grep content"
contentFiles=os.popen(contentFileCmd).read()
#if "Simnet_1_8K_CXP9034760" in contentFiles:
#    for sim in simsList:
#        cmd="touch Tacacs_%s.mml; chmod 777 Tacacs_%s.mml"%(sim,sim)
#        os.system(cmd)
#        applyTacacs = "su netsim -c '../utils/netsim/set_tacacs.sh %s'"%(sim)
#        TacacsOutput=os.popen(applyTacacs).read()
#        print TacacsOutput
#        cmd1="rm -rf Tacacs_%s.mml"%(sim)
#        os.system(cmd1)
print "Configuring default public key for scef nodes"
for sim in simsList:
  if "SCEF" in sim:
      scefCmd="su netsim -c 'sh netsim/configPubilcKey.sh %s'"%(sim)
      scefOutput=os.popen(scefCmd).read()
      print scefOutput
simStatus=[]
if docker == "no":
    if image_build == "yes":
         pool1 = Pool(processes=5)
         pool1.map(startNodes, simsList)
         pool1.terminate()
    else:
        for sim in simsList:
            status = startNodes(sim)
            simStatus.append(status)
createMML="touch save_MML.mml;chmod 777 save_MML.mml"
os.system(createMML)
saveLoadConfig = " su netsim -c 'sh netsim/saveLoadBalance.sh'"
Output=os.popen(saveLoadConfig).read()
print Output
if switchToRv == "yes":
    pathSpecifier="no"
    for sim in simsList:
        arneCmd="su netsim -c 'python netsim/arne_generation.py %s %s'"%(sim,pathSpecifier)
        arneOutput=os.popen(arneCmd).read()
        print arneOutput
print "INFO: Generating summary report for all simulation\n"
removeTempFiles = "rm -rf /tmp/*ipv*.txt *.mml *.log /netsim/*.mml /var/*.mml"
os.system(removeTempFiles)
print "INFO: All activities related to SimNet Deployer are now complete.\n"
