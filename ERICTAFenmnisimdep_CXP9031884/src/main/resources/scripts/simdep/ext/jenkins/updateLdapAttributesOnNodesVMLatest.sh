#!/bin/sh
#####################################################
#     File Name     : updateLdapAttributesOnNodesVMLatest.sh
#     Version       : 1.00
#     Author        : Surabhi Ravi teja
#     Date          : 25 June 2019
#####################################################
#Variable declarations
##############################################
ConfigType=$1
host=`hostname`

############################################################################################################################################
rm -rf $BSCNodeFile
rm -rf $DG2NodeFile
rm -rf $DG2TmpNodeFile

rm -rf /tmp/NodeData*.txt
rm -rf /tmp/ldaps_cmd.txt

cp /netsim/jq-1.0.1.tar .
tar -xvf jq-1.0.1.tar
chmod +x ./jq

BSCNodeFile=/tmp/BSCNodeDetails.txt
DG2NodeFile=/tmp/DG2NodeDetails.txt
DG2TmpNodeFile=/tmp/DG2TmpNodeDetails.txt

touch $BSCNodeFile
touch $DG2NodeFile
touch $DG2TmpNodeFile

echo ".generateNetworkMap" | /netsim/inst/netsim_shell
cat /netsim/netsimdir/networkMap.json | ./jq -j '.networkMap[] |select(.["nodeType"]=="BSC")|.name," ",.Simulation," ",.ip, "\n"' | sed 's/\"//g' > $BSCNodeFile
cat /netsim/netsimdir/networkMap.json | ./jq -j '.networkMap[] |select(.["nodeType"]=="MSRBS-V2")|.name," ",.Simulation," ",.ip, "\n"' | sed 's/\"//g' | grep -v "MSRBS" > $DG2TmpNodeFile

#for i in $(seq -w 0160); do cat $DG2TmpNodeFile | grep "$i " ; done > $DG2NodeFile

availablenodes=`cat $DG2TmpNodeFile|wc -l`; nodesrequired=$availablenodes; count=0; while [ $count -lt $nodesrequired ]; do for i in `cat $DG2TmpNodeFile | awk '{print $2}' | sort | uniq` ; do if [ $count -eq $nodesrequired ]; then break; else node=$(cat $DG2TmpNodeFile |grep $i -m 1); echo $node; sed -i "/$node/d" $DG2TmpNodeFile ; count=$((count+1)); fi; done; done > $DG2NodeFile

SIMULATIONS=`cat /netsim/netsimdir/networkMap.json | ./jq -j '.networkMap[] |select(.["nodeType"]=="BSC" or .["nodeType"]=="MSRBS-V2")|.Simulation,"\n"' | sed 's/\"//g' | sort | uniq | grep -v "RNC"`
############################################################################################################################################
if [[ $ConfigType == "DISABLE" ]]
then
    echo "$SIMULATIONS" | while read simulation
    do
	echo ".open $simulation" >> /tmp/ldaps_cmd.txt
	echo ".selectnocallback network" >> /tmp/ldaps_cmd.txt
	echo ".start -parallel 5" >> /tmp/ldaps_cmd.txt
	for NodeName in `cat /netsim/netsimdir/networkMap.json | ./jq -j --arg simulation "$simulation" '.networkMap[] | select(.["Simulation"]==$simulation) | .name,"\n"'|sed 's/\"//g'`
	do
	    echo -e ".select $NodeName \nsetmoattribute:mo=\"ManagedElement=$NodeName,SystemFunctions=1,SecM=1,UserManagement=1,LdapAuthenticationMethod=1\", attributes = \"administrativeState(Integer )=0\";\n.savenedatabase ldap force" >> /tmp/ldaps_cmd.txt
	    echo $NodeName >> /tmp/NodeData_DG2_${host}.txt
	done
    done
	rm -rf /tmp/Configured_BSC_${host}.txt 
	rm -rf /tmp/Configured_DG2_${host}.txt 
else
    Number_Of_BSC_Nodes=$2
    Number_Of_LTE_Nodes=$3
    TlsMode=$4
    AuthenticationDelay=$5

    echo "$SIMULATIONS" | while read simulation
    do
	echo ".open $simulation" >> /tmp/ldaps_cmd.txt
	echo ".selectnocallback network" >> /tmp/ldaps_cmd.txt
	echo ".start -parallel 5" >> /tmp/ldaps_cmd.txt
	if [[ $TlsMode == "LDAPS" ]]
	then
	    echo -e "ecim_configure_delay:netconfsockettime=$AuthenticationDelay;\n.savenedatabase ldap force"  >> /tmp/ldaps_cmd.txt
	fi	
    done

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
		echo "ecim_configure_delay:ldapsockettime=$AuthenticationDelay;"  >> /tmp/ldaps_cmd.txt
	    fi		
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
fi

/netsim/inst/netsim_pipe < /tmp/ldaps_cmd.txt
