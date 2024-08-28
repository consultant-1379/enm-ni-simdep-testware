#!/bin/sh
#####################################################
#     File Name     : updateLdapAttributesOnNodes.sh
#     Version       : 1.04
#     Author        : Surabhi Ravi teja
#     Date          : 25 June 2019
#####################################################
#     File Name     : updateLdapAttributesOnNodes.sh
#     Version       : 1.01
#     Author        : Mitali Sinha
#####################################################
#####################################################
#Variable declarations
##############################################
ConfigType=$1
host=`hostname`
echo "testt-Mit `date`"

############################################################################################################################################
rm -rf $BSCNodeFile
rm -rf $DG2NodeFile
rm -rf $DG2TmpNodeFile
rm -rf $R6672NodeFile
rm -rf $R6675NodeFile

rm -rf /tmp/NodeData*.txt
rm -rf /tmp/ldaps_cmd.txt
echo "try jq"
cd /netsim
cp /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/jq-1.0.1.tar /netsim
#curl --retry 5 -fsS -O "https://arm901-eiffel004.athtem.eei.ericsson.se:8443/nexus/content/repositories/nss-releases/com/ericsson/nss/scripts/jq/1.0.1/jq-1.0.1.tar" || { echo "Why so serious. Call the NSS-MT Team to turn that frown upside down. They will investigate why jq.tar did not download from Nexus successfully" && exit 1; }

tar -xvf jq-1.0.1.tar
chmod +x ./jq
echo "try jq1"
BSCNodeFile=/tmp/BSCNodeDetails.txt
DG2NodeFile=/tmp/DG2NodeDetails.txt
DG2TmpNodeFile=/tmp/DG2TmpNodeDetails.txt
R6672NodeFile=/tmp/R6672NodeDetails.txt
R6675NodeFile=/tmp/R6675NodeDetails.txt

touch $BSCNodeFile
touch $DG2NodeFile
touch $DG2TmpNodeFile
touch $R6672NodeFile
touch $R6675NodeFile

echo ".generateNetworkMap" | /netsim/inst/netsim_shell
cat /netsim/netsimdir/networkMap.json | ./jq -j '.networkMap[] |select(.["nodeType"]=="BSC")|.name," ",.Simulation," ",.ip, "\n"' | sed 's/\"//g' > $BSCNodeFile
cat /netsim/netsimdir/networkMap.json | ./jq -j '.networkMap[] |select(.["nodeType"]=="MSRBS-V2")|.name," ",.Simulation," ",.ip, "\n"' | sed 's/\"//g' | grep -v "MSRBS" > $DG2TmpNodeFile
cat /netsim/netsimdir/networkMap.json | ./jq -j '.networkMap[] |select(.["nodeType"]=="R6672")|.name," ",.Simulation," ",.ip, "\n"' | sed 's/\"//g' > $R6672NodeFile
cat /netsim/netsimdir/networkMap.json | ./jq -j '.networkMap[] |select(.["nodeType"]=="R6675")|.name," ",.Simulation," ",.ip, "\n"' | sed 's/\"//g' > $R6675NodeFile

#for i in $(seq -w 0160); do cat $DG2TmpNodeFile | grep "$i " ; done > $DG2NodeFile

availablenodes=`cat $DG2TmpNodeFile|wc -l`; nodesrequired=$availablenodes; count=0; while [ $count -lt $nodesrequired ]; do for i in `cat $DG2TmpNodeFile | awk '{print $2}' | sort | uniq` ; do if [ $count -eq $nodesrequired ]; then break; else node=$(cat $DG2TmpNodeFile |grep $i -m 1); echo $node; sed -i "/$node/d" $DG2TmpNodeFile ; count=$((count+1)); fi; done; done > $DG2NodeFile

RouterSIMULATIONS=`cat /netsim/netsimdir/networkMap.json | ./jq -j '.networkMap[] |select(.["nodeType"]=="R6675" or .["nodeType"]=="R6672")|.Simulation,"\n"' | sed 's/\"//g' | sort | uniq | grep -v "RNC"`

SIMULATIONS=`cat /netsim/netsimdir/networkMap.json | ./jq -j '.networkMap[] |select(.["nodeType"]=="BSC" or .["nodeType"]=="MSRBS-V2")|.Simulation,"\n"' | sed 's/\"//g' | sort | uniq | grep -v "RNC"`
############################################################################################################################################
if [[ $ConfigType == "DISABLE" ]]
then
    echo "$SIMULATIONS" | while read simulation
    do
        echo ".open $simulation" >> /tmp/ldaps_cmd.txt
        echo ".selectnocallback network" >> /tmp/ldaps_cmd.txt
        echo ".start -parallel 5" >> /tmp/ldaps_cmd.txt
    if [[ $simulation == *"GSM"* ]]
    then
            for NodeName in `cat /netsim/netsimdir/networkMap.json | ./jq -j --arg simulation "$simulation" '.networkMap[] | select(.["Simulation"]==$simulation and .["nodeType"]=="BSC") | .name,"\n"'|sed 's/\"//g'`
            do
            echo -e ".select $NodeName \nsetmoattribute:mo=\"ManagedElement=$NodeName,SystemFunctions=1,SecM=1,UserManagement=1,LdapAuthenticationMethod=1\", attributes = \"administrativeState(Integer )=0\";\n.savenedatabase ldap force" >> /tmp/ldaps_cmd.txt
                echo $NodeName >> /tmp/NodeData_DG2_${host}.txt
            done
    else
            for NodeName in `cat /netsim/netsimdir/networkMap.json | ./jq -j --arg simulation "$simulation" '.networkMap[] | select(.["Simulation"]==$simulation) | .name,"\n"'|sed 's/\"//g'`
            do
            echo -e ".select $NodeName \nsetmoattribute:mo=\"ManagedElement=$NodeName,SystemFunctions=1,SecM=1,UserManagement=1,LdapAuthenticationMethod=1\", attributes = \"administrativeState(Integer )=0\";\n.savenedatabase ldap force" >> /tmp/ldaps_cmd.txt
                echo $NodeName >> /tmp/NodeData_DG2_${host}.txt
            done
    fi
    done
        rm -rf /tmp/Configured_BSC_${host}.txt
        rm -rf /tmp/Configured_DG2_${host}.txt

    echo "$RouterSIMULATIONS" | while read simulation
    do
        echo ".open $simulation" >> /tmp/ldaps_cmd.txt
        echo ".selectnocallback network" >> /tmp/ldaps_cmd.txt
        echo ".start -parallel 5" >> /tmp/ldaps_cmd.txt
        for NodeName in `cat /netsim/netsimdir/networkMap.json | ./jq -j --arg simulation "$simulation" '.networkMap[] | select(.["Simulation"]==$simulation) | .name,"\n"'|sed 's/\"//g'`
        do
            echo -e ".select $NodeName \nsetmoattribute:mo=\"ManagedElement=1,SystemFunctions=1,SecM=1,UserManagement=1,LdapAuthenticationMethod=1\", attributes = \"administrativeState(Integer )=0\";\n.savenedatabase ldap force" >> /tmp/ldaps_cmd.txt
            echo $NodeName >> /tmp/NodeData_Router_${host}.txt
        done
    done
     rm -rf /tmp/Configured_Router_${host}.txt
else
    echo "$SIMULATIONS" | while read simulation
    do
        echo ".open $simulation" >> /tmp/ldaps_cmd.txt
        echo ".selectnocallback network" >> /tmp/ldaps_cmd.txt
        echo ".start -parallel 5" >> /tmp/ldaps_cmd.txt
    if [[ $simulation == *"GSM"* ]]
    then
            for NodeName in `cat /netsim/netsimdir/networkMap.json | ./jq -j --arg simulation "$simulation" '.networkMap[] | select(.["Simulation"]==$simulation and .["nodeType"]=="BSC") | .name,"\n"'|sed 's/\"//g'`
            do
            echo -e ".select $NodeName \nsetmoattribute:mo=\"ManagedElement=$NodeName,SystemFunctions=1,SecM=1,UserManagement=1,LdapAuthenticationMethod=1\", attributes = \"administrativeState(Integer )=0\";\n.savenedatabase ldap force" >> /tmp/ldaps_cmd.txt
                echo $NodeName >> /tmp/NodeData_DG2_${host}.txt
            done
    else
            for NodeName in `cat /netsim/netsimdir/networkMap.json | ./jq -j --arg simulation "$simulation" '.networkMap[] | select(.["Simulation"]==$simulation) | .name,"\n"'|sed 's/\"//g'`
            do
            echo -e ".select $NodeName \nsetmoattribute:mo=\"ManagedElement=$NodeName,SystemFunctions=1,SecM=1,UserManagement=1,LdapAuthenticationMethod=1\", attributes = \"administrativeState(Integer )=0\";\n.savenedatabase ldap force" >> /tmp/ldaps_cmd.txt
                echo $NodeName >> /tmp/NodeData_DG2_${host}.txt
            done
    fi
    done
        rm -rf /tmp/Configured_BSC_${host}.txt
        rm -rf /tmp/Configured_DG2_${host}.txt

    echo "$RouterSIMULATIONS" | while read simulation
    do
        echo ".open $simulation" >> /tmp/ldaps_cmd.txt
        echo ".selectnocallback network" >> /tmp/ldaps_cmd.txt
        echo ".start -parallel 5" >> /tmp/ldaps_cmd.txt
        for NodeName in `cat /netsim/netsimdir/networkMap.json | ./jq -j --arg simulation "$simulation" '.networkMap[] | select(.["Simulation"]==$simulation) | .name,"\n"'|sed 's/\"//g'`
        do
            echo -e ".select $NodeName \nsetmoattribute:mo=\"ManagedElement=1,SystemFunctions=1,SecM=1,UserManagement=1,LdapAuthenticationMethod=1\", attributes = \"administrativeState(Integer )=0\";\n.savenedatabase ldap force" >> /tmp/ldaps_cmd.txt
            echo $NodeName >> /tmp/NodeData_Router_${host}.txt
        done
    done
     rm -rf /tmp/Configured_Router_${host}.txt

    Number_Of_BSC_Nodes=$2
    Number_Of_LTE_Nodes=$3
    TlsMode="LDAPS"
    AuthenticationDelay=0
    CLUSTER_ID=$6
    Deployment=$7
    ENM_URL=$8

    #echo "$SIMULATIONS" | while read simulation
    #do
        #echo ".open $simulation" >> /tmp/ldaps_cmd.txt
        #echo ".selectnocallback network" >> /tmp/ldaps_cmd.txt
        #echo ".start -parallel 5" >> /tmp/ldaps_cmd.txt
        #if [[ $TlsMode == "LDAPS" ]]
        #then
            #echo -e "ecim_configure_delay:netconfsockettime=$AuthenticationDelay;\n.savenedatabase ldap force"  >> /tmp/ldaps_cmd.txt
        #echo -e ".savenedatabase ldap force"  >> /tmp/ldaps_cmd.txt
        #fi
    #done

#    echo shroot | sudo -S -u root bash -c "sh /var/simnet/enm-ni-simdep/scripts/simdep/ext/jenkins/setupLdap.sh $CLUSTER_ID $Deployment $ConfigType"

     ##############################################
     #Fetch ENM URL
     ##############################################
     if [[ -z $ENM_URL ]]; then
      if [[ $Deployment == "Openstack" ]]; then
         #Downlaoding Jq Files
#        cp /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/jq-1.0.1.tar /netsim ; tar -xvf jq-1.0.1.tar ; chmod +x ./jq
         sed_id=`curl -s "http://atvdit.athtem.eei.ericsson.se/api/deployments/?q=name=$CLUSTER_ID" | ./jq '.[].enm.sed_id' | sed 's/\"//g'`
         ClusterName=`curl -s "http://atvdit.athtem.eei.ericsson.se/api/documents/$sed_id" | ./jq '.content.parameters.httpd_fqdn' | sed 's/\"//g' | awk -F. '{print $1}'`
         ENM_URL="https://$ClusterName.athtem.eei.ericsson.se/"
      else
         cp /var/simnet/enm-ni-simdep/scripts/simdep/ext/jenkins/fetchEnmUrl.py /netsim
         ENM_URL=`python fetchEnmUrl.py $CLUSTER_ID`
         ENM_URL="https://$ENM_URL/"
      fi
     fi
    echo "## ENM_URL=$ENM_URL ## "

    echo "## CLUSTER_ID=$CLUSTER_ID ##"

    ##########################################################
    #Install Enm_Client_Scripting
    ##########################################################
    #cp $WORKSPACE/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/get-pip.py .
    echo shroot | sudo -S -u root bash -c "cd /var/simnet/enm-ni-simdep/scripts/simdep/ext/jenkins;sudo python get-pip.py"
    curl --insecure  --tlsv1 -c /tmp/cookie.txt -X POST "$ENM_URL/login?IDToken1=Administrator&IDToken2=TestPassw0rd"
    ENMSCRIPTING_URL=`curl --insecure  --tlsv1 -b /tmp/cookie.txt --retry 5 -LsS -w %{url_effective} -o /dev/null "$ENM_URL/scripting/enmclientscripting"`
    echo "## ENMSCRIPTING_URL=$ENMSCRIPTING_URL ##"
    curl -L -O --insecure --tlsv1 -b /tmp/cookie.txt --retry 5 -fsS "$ENMSCRIPTING_URL"
    sudo pip install enm_client_scripting*.whl

##########################################################
##########################################################
cp /var/simnet/enm-ni-simdep/scripts/simdep/ext/jenkins/runCliCommand.py /var/tmp/

    getattributes () {
        
        ########################################
        echo "### LDAP Attributes for $node  ###"
        ########################################
        
        echo shroot | sudo -S -u root bash -c "sh /var/simnet/enm-ni-simdep/scripts/simdep/ext/jenkins/fetchLdapAttributes.sh $ENM_URL"
        cp /var/tmp/LdapAttributes.log /netsim/
        
        file1="/netsim/LdapAttributes.log"

        V2=$(cat $file1 | awk 'FNR == 2 {print $1}')
        fallbackLdapIpv4Address=$(cat $file1 | grep -w fallbackLdapIpv4Address |awk '{print $2}')

        V3=$(cat $file1 | awk 'FNR == 3 {print $1}')
        ldapIpv4Address=$(cat $file1 | grep -w ldapIpv4Address |awk '{print $2}')

        if [[ $TlsMode == "LDAP" ]]
        then
        V4=$(cat $file1 | awk 'FNR == 4 {print $1}')
        Port=$(cat $file1 | grep -w tlsPort | awk '{print $2}')
        tlsMode=0
        else
        V5=$(cat $file1 | awk 'FNR == 5 {print $1}')
        Port=$(cat $file1 | grep -w ldapsPort |awk '{print $2}')
        tlsMode=1
        fi

        V6=$(cat $file1 | awk 'FNR == 6 {print $1}')
        fallbackLdapIpv6Address=$(cat $file1 | grep -w fallbackLdapIpv6Address | awk '{print $2}')

        V7=$(cat $file1 | awk 'FNR == 7 {print $1}')
        ldapIpv6Address=$(cat $file1 | grep -w ldapIpv6Address| awk '{print $2}')

        V8=$(cat $file1 | awk 'FNR == 8 {print $1}')
        bindDn=$(cat $file1 | grep -w bindDn)
        bindDn_Value=$(echo $bindDn | cut -d " " -f2-)
        bindDn_FinalValue=$(echo $bindDn_Value |sed -e "s/  */,/g")


        V9=$(cat $file1 | awk 'FNR == 9 {print $1}')
        baseDn=$(cat $file1 | grep -w baseDn)
        baseDn_Value=$(echo $baseDn | cut -d " " -f2-)
        baseDn_FinalValue=$(echo $baseDn_Value |sed -e "s/  */,/g")


        V10=$(cat $file1 | awk 'FNR == 10 {print $1}')
        bindPassword=$(cat $file1 | grep -w bindPassword | awk '{print $2}')
        }



    ############################ Configuration Setup for BSC nodes ##############################################

        rm -rf /tmp/NodeData_BSC_${host}.txt

        if [ -s "/tmp/Configured_BSC_${host}.txt" ]
        then
                ConfiguredBSCCount=`cat /tmp/Configured_BSC_${host}.txt | wc -l`
                TotalBSCCount=`cat $BSCNodeFile | wc -l`
                if [ $ConfiguredBSCCount -eq $TotalBSCCount ]
                then
                        echo "All BSC nodes are already configured with LDAP on server ${host}"
                        rm -rf $BSCNodeFile
                else
                        for i in `cat /tmp/Configured_BSC_${host}.txt | awk '{print $1}'`
                        do
                                sed -i "/$i/d" $BSCNodeFile
                        done
                        head -n $Number_Of_BSC_Nodes $BSCNodeFile > /tmp/NodeData_BSC_${host}.txt
                fi
        else
                head -n $Number_Of_BSC_Nodes $BSCNodeFile > /tmp/NodeData_BSC_${host}.txt
        fi

    if [ -s "$BSCNodeFile" ] && [ ! -z "$Number_Of_BSC_Nodes" ] && [ $Number_Of_BSC_Nodes -ne 0 ];
    then
        while read node sim ip;
        do
            echo ".open $sim" >> /tmp/ldaps_cmd.txt
            echo ".select $node" >> /tmp/ldaps_cmd.txt

            getattributes

            if [[ $ip =~ ":" ]]
            then
                fallbackLdapIpvAddress=$fallbackLdapIpv6Address
                ldapIpvAddress=$ldapIpv6Address
            else
                fallbackLdapIpvAddress=$fallbackLdapIpv4Address
                ldapIpvAddress=$ldapIpv4Address
            fi
            echo ".start" >> /tmp/ldaps_cmd.txt
            echo "createmo:parentid=\"ManagedElement=$node,SystemFunctions=1,SecM=1,UserManagement=1,LdapAuthenticationMethod=1\",type=\"Ldap\",name=\"1\";" >> /tmp/ldaps_cmd.txt
            echo "setmoattribute:mo=\"ManagedElement=$node,SystemFunctions=1,SecM=1,UserManagement=1,LdapAuthenticationMethod=1\", attributes = \"administrativeState(Integer )=1\";" >> /tmp/ldaps_cmd.txt
            echo "setmoattribute:mo=\"ManagedElement=$node,SystemFunctions=1,SecM=1,UserManagement=1,LdapAuthenticationMethod=1,Ldap=1\", attributes = \"fallbackLdapIpAddress(string)=$fallbackLdapIpvAddress||ldapIpAddress(string)=$ldapIpvAddress|| tlsMode(Integer)=$tlsMode|| serverPort(uint16)=$Port ||bindDn(string)=$bindDn_FinalValue|| profileFilter(Integer)=1||baseDn(string)=$baseDn_FinalValue||bindPassword(struct EcimPassword)=[true,$bindPassword]\";" >> /tmp/ldaps_cmd.txt
            echo "e: MOId_$node= csmo:ldn_to_mo_id(null,ecim_netconflib:string_to_ldn(\"ManagedElement=$node,SystemFunctions=1,SecM=1,UserManagement=1,LdapAuthenticationMethod=1\"))." >> /tmp/ldaps_cmd.txt
            echo "e: {_csnvs, _AttrNames, _AttrVals, {enum, AttrTypes}} = csmo:get_attribute(null, MOId_$node, administrativeState)." >> /tmp/ldaps_cmd.txt
            echo "e: csmo:get_enum_value(null, MOId_$node, administrativeState, AttrTypes)." >> /tmp/ldaps_cmd.txt
            echo "e: ProMOIds_$node= csmo:ldn_to_mo_id(null,ecim_netconflib:string_to_ldn(\"ManagedElement=$node,SystemFunctions=1,SecM=1,UserManagement=1,LdapAuthenticationMethod=1,Ldap=1\"))." >> /tmp/ldaps_cmd.txt
            echo "e: {_csnv, _AttrName, _AttrVal, {enum, AttrType}} = csmo:get_attribute(null, ProMOIds_$node, profileFilter)." >> /tmp/ldaps_cmd.txt
            echo "e: csmo:get_enum_value(null, ProMOIds_$node, profileFilter, AttrType)." >> /tmp/ldaps_cmd.txt
            #if [[ $TlsMode == "LDAP" ]]
            #then
                #echo "ecim_configure_delay:ldapsockettime=$AuthenticationDelay;"  >> /tmp/ldaps_cmd.txt
            #fi
            echo ".savenedatabase ldap force" >> /tmp/ldaps_cmd.txt
        done < /tmp/NodeData_BSC_${host}.txt
        cat /tmp/NodeData_BSC_${host}.txt >> /tmp/Configured_BSC_${host}.txt
    else
        echo "No LDAP configuration done for BSC nodes because of no BSC nodes on server or Job triggered with Number Of BscNodes as NULL or 0"
    fi


    ############################ Configuration Setup for DG2 nodes ##############################################

        rm -rf /tmp/NodeData_DG2_${host}.txt

        if [ -s "/tmp/Configured_DG2_${host}.txt" ]
        then
                ConfiguredDG2Count=`cat /tmp/Configured_DG2_${host}.txt | wc -l`
                TotalDG2Count=`cat $DG2NodeFile | wc -l`
                if [ $ConfiguredDG2Count -eq $TotalDG2Count ]
                then
                        echo "All DG2 nodes are already configured with LDAP on server ${host}"
                        rm -rf $DG2NodeFile
                else
                        for i in `cat /tmp/Configured_DG2_${host}.txt | awk '{print $1}'`
                        do
                                sed -i "/$i/d" $DG2NodeFile
                        done
                        head -n $Number_Of_LTE_Nodes $DG2NodeFile > /tmp/NodeData_DG2_${host}.txt
                fi
        else
                head -n $Number_Of_LTE_Nodes $DG2NodeFile > /tmp/NodeData_DG2_${host}.txt
        fi

    if [ -s "$DG2NodeFile" ] && [ ! -z "$Number_Of_LTE_Nodes" ] && [ $Number_Of_LTE_Nodes -ne 0 ];
    then
        while read node sim ip;
        do
            echo ".open $sim" >> /tmp/ldaps_cmd.txt
            echo ".select $node" >> /tmp/ldaps_cmd.txt

            getattributes

            if [[ $ip =~ ":" ]]
            then
                fallbackLdapIpvAddress=$fallbackLdapIpv6Address
                ldapIpvAddress=$ldapIpv6Address
            else
                fallbackLdapIpvAddress=$fallbackLdapIpv4Address
                ldapIpvAddress=$ldapIpv4Address
            fi
            echo ".start" >> /tmp/ldaps_cmd.txt
            echo "createmo:parentid=\"ManagedElement=$node,SystemFunctions=1,SecM=1,UserManagement=1,LdapAuthenticationMethod=1\",type=\"Ldap\",name=\"1\";" >> /tmp/ldaps_cmd.txt
            echo "setmoattribute:mo=\"ManagedElement=$node,SystemFunctions=1,SecM=1,UserManagement=1,LdapAuthenticationMethod=1\", attributes = \"administrativeState(Integer )=1\";" >> /tmp/ldaps_cmd.txt
            echo "setmoattribute:mo=\"ManagedElement=$node,SystemFunctions=1,SecM=1,UserManagement=1,LdapAuthenticationMethod=1,Ldap=1\", attributes = \"fallbackLdapIpAddress(string)=$fallbackLdapIpvAddress||ldapIpAddress(string)=$ldapIpvAddress|| tlsMode(Integer)=$tlsMode|| serverPort(uint16)=$Port ||bindDn(string)=$bindDn_FinalValue|| profileFilter(Integer)=1||baseDn(string)=$baseDn_FinalValue||bindPassword(struct EcimPassword)=[true,$bindPassword]\";" >> /tmp/ldaps_cmd.txt
            echo "e: MOId_$node= csmo:ldn_to_mo_id(null,ecim_netconflib:string_to_ldn(\"ManagedElement=$node,SystemFunctions=1,SecM=1,UserManagement=1,LdapAuthenticationMethod=1\"))." >> /tmp/ldaps_cmd.txt
            echo "e: {_csnvs, _AttrNames, _AttrVals, {enum, AttrTypes}} = csmo:get_attribute(null, MOId_$node, administrativeState)." >> /tmp/ldaps_cmd.txt
            echo "e: csmo:get_enum_value(null, MOId_$node, administrativeState, AttrTypes)." >> /tmp/ldaps_cmd.txt
            echo "e: ProMOIds_$node= csmo:ldn_to_mo_id(null,ecim_netconflib:string_to_ldn(\"ManagedElement=$node,SystemFunctions=1,SecM=1,UserManagement=1,LdapAuthenticationMethod=1,Ldap=1\"))." >> /tmp/ldaps_cmd.txt
            echo "e: {_csnv, _AttrName, _AttrVal, {enum, AttrType}} = csmo:get_attribute(null, ProMOIds_$node, profileFilter)." >> /tmp/ldaps_cmd.txt
            echo "e: csmo:get_enum_value(null, ProMOIds_$node, profileFilter, AttrType)." >> /tmp/ldaps_cmd.txt
            if [[ $TlsMode == "LDAP" ]]
            then
                echo "ecim_configure_delay:ldapsockettime=300;"  >> /tmp/ldaps_cmd.txt
            fi
            echo ".savenedatabase ldap force" >> /tmp/ldaps_cmd.txt
        done < /tmp/NodeData_DG2_${host}.txt
        cat /tmp/NodeData_DG2_${host}.txt >> /tmp/Configured_DG2_${host}.txt
    else
        echo "No LDAP configuration done for DG2 nodes because of no DG2 nodes on server or Job triggered with Number Of DG2Nodes as NULL or 0"
    fi
        ############################ Configuration Setup for Router nodes ##############################################

        rm -rf /tmp/NodeData_Router_${host}.txt

        if [[ `cat $R6672NodeFile | wc -l` -ne 0 ]]
        then
            if [ -s "/tmp/Configured_Router_${host}.txt" ]
            then
                ConfiguredRouterCount=`cat /tmp/Configured_Router_${host}.txt | wc -l`
                TotalRouterCount=`cat $R6672NodeFile | wc -l`
                if [ $ConfiguredRouterCount -eq $TotalRouterCount ]
                then
                        echo "All R6672 nodes are already configured with LDAP on server ${host}"
                        rm -rf $R6672NodeFile
                else
                        for i in `cat /tmp/Configured_Router_${host}.txt | awk '{print $1}'`
                        do
                                sed -i "/$i/d" $R6672NodeFile
                        done
                        cat $R6672NodeFile > /tmp/NodeData_Router_${host}.txt
                fi
            else
                cat $R6672NodeFile > /tmp/NodeData_Router_${host}.txt
            fi
        elif [[ `cat $R6675NodeFile | wc -l` -ne 0 ]]
        then
            if [ -s "/tmp/Configured_Router_${host}.txt" ]
            then
                ConfiguredRouterCount=`cat /tmp/Configured_Router_${host}.txt | wc -l`
                TotalRouterCount=`cat $R6675NodeFile | wc -l`
                if [ $ConfiguredRouterCount -eq $TotalRouterCount ]
                then
                        echo "All R6675 nodes are already configured with LDAP on server ${host}"
                        rm -rf $R6675NodeFile
                else
                        for i in `cat /tmp/Configured_Router_${host}.txt | awk '{print $1}'`
                        do
                                sed -i "/$i/d" $R6675NodeFile
                        done
                        cat $R6675NodeFile > /tmp/NodeData_Router_${host}.txt
                fi
            else
                cat $R6675NodeFile > /tmp/NodeData_Router_${host}.txt
            fi
        fi

    if [ -s "$R6675NodeFile" ] || [ -s "$R6672NodeFile" ];
    then
        userLabel="ENM"
        while read node sim ip;
        do
            echo ".open $sim" >> /tmp/ldaps_cmd.txt
            echo ".select $node" >> /tmp/ldaps_cmd.txt

            getattributes

            if [[ $ip =~ ":" ]]
            then
                fallbackLdapIpvAddress=$fallbackLdapIpv6Address
                ldapIpvAddress=$ldapIpv6Address
            else
                fallbackLdapIpvAddress=$fallbackLdapIpv4Address
                ldapIpvAddress=$ldapIpv4Address
            fi
            echo ".start" >> /tmp/ldaps_cmd.txt
            echo "setmoattribute:mo=\"ManagedElement=1,SystemFunctions=1,SecM=1,UserManagement=1,LdapAuthenticationMethod=1\", attributes = \"administrativeState(Integer )=1\";" >> /tmp/ldaps_cmd.txt
            echo "setmoattribute:mo=\"ManagedElement=1,SystemFunctions=1,SecM=1,UserManagement=1,LdapAuthenticationMethod=1,Ldap=1\", attributes = \"fallbackLdapIpAddress(string)=$fallbackLdapIpvAddress||ldapIpAddress(string)=$ldapIpvAddress|| tlsMode(Integer)=$tlsMode|| userLabel(string)=$userLabel || serverPort(uint16)=$Port ||bindDn(string)=$bindDn_FinalValue|| profileFilter(Integer)=1||baseDn(string)=$baseDn_FinalValue||bindPassword(struct EcimPassword)=[true,$bindPassword]\";" >> /tmp/ldaps_cmd.txt
            echo "e: MOId_$node= csmo:ldn_to_mo_id(null,ecim_netconflib:string_to_ldn(\"ManagedElement=1,SystemFunctions=1,SecM=1,UserManagement=1,LdapAuthenticationMethod=1\"))." >> /tmp/ldaps_cmd.txt
            echo "e: {_csnvs, _AttrNames, _AttrVals, {enum, AttrTypes}} = csmo:get_attribute(null, MOId_$node, administrativeState)." >> /tmp/ldaps_cmd.txt
            echo "e: csmo:get_enum_value(null, MOId_$node, administrativeState, AttrTypes)." >> /tmp/ldaps_cmd.txt
            echo "e: ProMOIds_$node= csmo:ldn_to_mo_id(null,ecim_netconflib:string_to_ldn(\"ManagedElement=1,SystemFunctions=1,SecM=1,UserManagement=1,LdapAuthenticationMethod=1,Ldap=1\"))." >> /tmp/ldaps_cmd.txt
            echo "e: {_csnv, _AttrName, _AttrVal, {enum, AttrType}} = csmo:get_attribute(null, ProMOIds_$node, profileFilter)." >> /tmp/ldaps_cmd.txt
            echo "e: csmo:get_enum_value(null, ProMOIds_$node, profileFilter, AttrType)." >> /tmp/ldaps_cmd.txt
            if [[ $TlsMode == "LDAP" ]]
            then
                echo "ecim_configure_delay:ldapsockettime=300;"  >> /tmp/ldaps_cmd.txt
            fi
            echo ".savenedatabase ldap force" >> /tmp/ldaps_cmd.txt
        done < /tmp/NodeData_Router_${host}.txt
        cat /tmp/NodeData_Router_${host}.txt >> /tmp/Configured_Router_${host}.txt
    else
        echo "No LDAP configuration done for Router nodes because of no Router nodes on server "
    fi
fi

if [[ -f /tmp/ldaps_cmd.txt ]] 
then
    /netsim/inst/netsim_pipe < /tmp/ldaps_cmd.txt
    
else
   echo "/tmp/ldaps_cmd.txt file is not present : No LDAP nodes are present in the $host"
fi   
