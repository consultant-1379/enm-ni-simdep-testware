#!/usr/bin/perl -w
use strict;
use warnings;
use POSIX();
use Config::Tiny;
use Storable;
###################################################################################
#     File Name    : assignPort.pl
#     Author       : Sneha Srivatsav Arra, Fatih Onur
#     Description  : See usage below.
#     Date Created : 27 January 2014
###################################################################################
#
#Variables
my $PWD = `pwd`;
chomp($PWD);
my $NETSIM_INSTALL_SHELL = "/netsim/inst/netsim_pipe";

#
#
#----------------------------------------------------------------------------------
#Check if the scrip is executed as netsim user
#----------------------------------------------------------------------------------
#
my $user = `whoami`;
chomp($user);
my $netsim = 'netsim';
if ( $user ne $netsim ) {
    print "ERROR: Not netsim user. Please execute the script as netsim user\n";
    exit(201);
}

#
#----------------------------------------------------------------------------------
#Check if the script usage is right
#---------------------------------------------------------------------------------
my $USAGE =<<USAGE;
Descr: Assigns port to every NE.
    Usage:
        $0 <storagePath> <defaultDestination> <serverType> <release> <securityStatusTLS> <switchToRvConf> <sim>
        where:
            <simName>           : The name of the simulation that needs to be opened in NETSim
            <portName>          : The name of the port that is already created.
            <simPortName>       : The name of the Port that the simulation will use
            <defaultDestination>: IP of the OSS master
            <securityStatusTLS> : Specifies if the status of TLS is on/off.
            <switchToRvConf>    : Whether the rollout performed is for RV or MT yes/no
            <ipv6Per>           : Specifies whether ipv6 nodes are need or not
        usage examples:
             $0 CORE-K-FT-M-MGwB15215-FP2x1-vApp.zip CPP CPP:10.10.10 159.25.25.6 off yes no
             $0 CORE-K-FT-M-MGwB15215-FP2x1-vApp.zip CPP CPP:10.10.10 159.25.25.6 on  no yes
        dependencies:
              1. The port should already be created.
        Return Values: 201 -> Not a netsim user
                       202 -> Usage is incorrect
                       207 -> Failed to execute system command.
USAGE

# HELP
if ( @ARGV != 7 ) {
    print "$USAGE";
    exit(202);
}
print "\n\nRUNNING: $0 @ARGV \n";

#
#-----------------------------------------------------------------------------------
#Read Parameters
#----------------------------------------------------------------------------------
my $simNameTemp              = "$ARGV[0]";
my $createPort               = "$ARGV[1]";
my $simPortName              = "$ARGV[2]";
my $createDefaultDestination = "$ARGV[3]";
my $securityStatusTLS        = "$ARGV[4]";
my $switchToRvConf           = "$ARGV[5]";
my $ipv6Per                  = "$ARGV[6]";

my @tempSimName = split( '\.zip', $simNameTemp );
my $simName = $tempSimName[0];

my $createDefaultDestinationName = "$createPort";
chomp($simPortName);

open listNeType, "$PWD/../dat/dumpNeType.txt";
my @NeType = <listNeType>;
close(listNeType);
open listNeName, "$PWD/../dat/dumpNeName.txt";
my @NeNames = <listNeName>;
close(listNeName);
my $numOfNe        = @NeNames;
my $stnName        = "SIU02";
my $stnTCUName     = "TCU02";
my $stnPort        = "STN_PROT";
my $stnPort_ipv6   = "STN_PROT_IPV6";
my $timeServer     = "TimeServer";
my $timeServerPort = "testbed";
my $netconfPort    = "NETCONF_PROT";
my $netconfPortIs  = "NETCONF_PROT_IS";
my $netconfPortIsTLS = "NETCONF_PROT_IS_TLS";
my $netconfPortIsTLSIpv6 = "NETCONF_PROT_IS_TLS_IPV6";
my $netconfTLSPort = "NETCONF_PROT_TLS";
my $netconfTLSPort_Ipv6 = "NETCONF_PROT_TLS_IPV6";
my $mcs_s_cpPort   = "MSC_S_CP";
my $lanSwitchPort  = "LANSWITCH_PROT";
my $stnPICOName    = "PICO";
my $apgPort        = "APG_APGTCP";
my $apg43l_port    = "APG43L_APGTCP";
my $apg43l_port_ipv6 = "APG43L_APGTCP_IPV6";
my $netconfDD      = "NETCONF_PROT";
my $netconfDDIs    = "NETCONF_PROT_IS";
my $lanSwitchDD    = "LANSWITCH_PROT";
my $netconfSSHPort = "NETCONF_PROT_SSH";
my $yangsnmpSSHPort = "YANG_SNMP_SSH_PROT";
my $yangsnmpSSHPort_Ipv6 = "YANG_SNMP_SSH_IPV6_PROT";
my $yangsnmpTLSPort = "YANG_SNMP_TLS_PROT";
my $yangsnmpTLSPort_Ipv6 = "YANG_SNMP_TLS_IPV6_PROT";
my $yangsnmpSSHEPGPort = "YANG_SNMP_SSH_EPG_PROT";
my $yangsnmpSSHWMGPort = "YANG_SNMP_SSH_WMG_PROT";
my $yangsnmpSSHEPGPort_Ipv6 = "YANG_SNMP_SSH_EPG_IPV6_PROT";
my $yangsnmpSSHWMGPort_Ipv6 = "YANG_SNMP_SSH_WMG_IPV6_PROT";
my $yangsnmpSSHSMSFPort = "YANG_SNMP_SSH_SMSF_PROT";
my $yangsnmpSSHSMSFPort_Ipv6 = "YANG_SNMP_SSH_SMSF_IPV6_PROT";	
my $netconfSSHMTASPort = "NETCONF_PROT_SSH_MTAS";
my $netconfEPGPort = "NETCONF_PROT_EPG";
my $netconfSSHDG2Port = "NETCONF_PROT_SSH_DG2";
my $netconfSSHPort_Ipv6 = "NETCONF_PROT_SSH_IPV6";
my $netconfSSHMTASPort_Ipv6 = "NETCONF_PROT_SSH_MTAS_IPV6";
my $netconfHTTPSTLSPort_Ipv6 = "NETCONF_HTTP_HTTPS_TLS_IPV6_PORT";
my $netconfHTTPSTLSPort = "NETCONF_HTTP_HTTPS_TLS_PORT";
my $netconfHTTPSSSHPort = "NETCONF_HTTP_HTTPS_SSH_PORT";
my $netconfHTTPSSSHPort_Ipv6 = "NETCONF_HTTP_HTTPS_SSH_IPV6_PORT";
my $lanSwitchPort_snmpv3_ipv6  = "LANSWITCH_PROT_SNMPV3_IPV6_PORT";
my $lanSwitchPort_snmpv3  = "LANSWITCH_PROT_SNMPV3";
my $lanswitchprotipv6port = "LANSWITCH_PROT_IPV6_PORT";
my $HTTPHTTPSPort = "HTTP_HTTPS_PORT";
my $HTTPHTTPSPort_ipv6 = "HTTP_HTTPS_IPV6_PORT";
my $iiopPort_ipv6 = "IIOP_PROT_IPV6";
my $iiopPort = "IIOP_PROT";
my $snmpPort = "SNMP";
my $snmpSSHPort = "SNMP_SSH_PROT";
my $snmpSSHPort_ipv6 = "SNMP_SSH_PROT_IPV6_PORT";
my $snmpTelnetPort = "SNMP_TELNET_PROT";
my $snmpTelnetPort_ipv6 = "SNMP_TELNET_PROT_IPV6_PORT";
my $snmpTelnetIc8855Port = "SNMP_TELNET_IC8855_PROT";
my $snmpTelnetIc8855Port_ipv6 = "SNMP_TELNET_IC8855_PROT_IPV6_PORT";
my $snmptelnetsecurePort = "SNMP_TELNET_SECURE_PROT";
my $snmptelnetsecurePort_ipv6= "SNMP_TELNET_SECURE_PROT_IPV6_PORT";
my $tspSSHPort =  "TSP_SSH_PROT";
my $tspSSHPort_Ipv6 = "TSP_SSH_PROT_IPV6_PORT";
my $snmpsshtelnet_prot  = "LANSWITCH_SNMP_SSH_TELNET_PORT";
my $snmpsshtelnet_prot_Ipv6 = "LANSWITCH_SNMP_SSH_TELNET_IPV6_PORT";
my $ml6352_port = "ML6352_PORT";
my $ml6352_port_Ipv6 = "ML6352_PORT_IPV6_PORT";
my $agptcp_netconf_http_https_prot = "APG_NETCONF_HTTP_HTTPS_PROT";
my $agptcp_netconf_http_https_tls_prot= "APG_NETCONF_HTTP_HTTPS_TLS_PROT";
my $agptcp_netconf_http_https_tls_ipv6_prot= "APG_NETCONF_HTTP_HTTPS_TLS_IPV6_PROT";
my $msc_bc_is_prot = "MSC_BC_IS_PROT";
my $msc_bc_is_tls_prot = "MSC_BC_IS_TLS_PROT";
my $msc_bc_is_tls_ipv6_prot = "MSC_BC_IS_TLS_IPV6_PROT";
my $fronthaul6020_port = "NETCONF_PROT_SSH_FRONTHAUL6020";
my $fronthaul6020_Ipv6 = "NETCONF_PROT_SSH_FRONTHAUL6020_IPV6";
my $fronthaul6080_port = "NETCONF_PROT_SSH_FRONTHAUL6080";
my $fronthaul6080_Ipv6 = "NETCONF_PROT_SSH_FRONTHAUL6080_IPV6";
my $fronthaulHTTPSprot = "NETCONF_HTTP_HTTPS_SSH_FRONTHAUL_PORT";
my $fronthaulHTTPSprot_Ipv6 = "NETCONF_HTTP_HTTPS_SSH_FRONTHAUL_IPV6_PORT";
my $fronthaulTLSHTTPSSNMPV3prot = "NETCONF_HTTP_HTTPS_TLS_SNMPV3_FRONTHAUL_PORT";
my $fronthaulTLSHTTPSSNMPV3prot_Ipv6 = "NETCONF_HTTP_HTTPS_TLS_SNMPV3_FRONTHAUL_IPV6_PORT";
my $netconfSSHPort_ipv6 = "NETCONF_PROT_SSH_IPV6_PORT";
my $ml6352_port_snmpv2 = "ML6352_PORT_SNMPV2";
my $ml6352_port_snmpv2_ipv6_port = "ML6352_PORT_SNMPv2_IPV6_PORT";
my $ml6352_port_snmpv3 = "ML6352_PORT_SNMPV3";
my $ml6352_port_snmpv3_ipv6_port = "ML6352_PORT_SNMPv3_IPV6_PORT";
my $netconf_prot_ipv6_port = "NETCONF_PROT_IPV6";
my $netconfTLSsnmpv3_Port = "NETCONF_PROT_TLS_SNMPV3";
my $netconfTLSsnmpv3_Port_Ipv6 = "NETCONF_PROT_TLS_SNMPV3_IPV6";
my $isProt = "IS_PROT";
my $snmpsshtelnet_Port = "SNMP_SSH_TELNET_PROT";
my $snmpsshtelnet_Port_Ipv6 = "SNMP_SSH_TELNET_IPV6_PROT";
my $o1_Port="O1_PORT";
#
#-----------------------------------------------------------------------------------
# IPV6 Parameters

#----------------------------------------------------------------------------------

my $IPV6_CONFIG_FILE  = "ipv6.txt";
my $SIM               = $simName;
my $NETSIMDIR         = "/netsim/netsimdir";
my $SIM_INTERNAL_PATH = "";
my $IPV6_CONFIG_FILE_PATH = $NETSIMDIR . "/" . $SIM . $SIM_INTERNAL_PATH . "/" . $IPV6_CONFIG_FILE;

#----------------------------------------------------------------------------------
# Defines number of ip per for exceptional nodes
#----------------------------------------------------------------------------------
my %neTypesIpMultiplier = (
    "TimeServer"       => 0,
    "MSC"              => 3,
    "BSC"              => 3,
    "vBSC"             => 3,
    "HLR-BS-CP"        => 0,
    "HLR-BS-SPX"       => 0,
    "HLR-BS-TSC"       => 0,
    "MSC-S-DB-APG43L"  => 3,
    "MSC-DB"           => 3,
    "MSC-IP-STP"       => 3,
    "MSC-BC-IS"        => 6,
    "CTC-MSC-BC-BSP"   => 3,
    "MSC-BC-BSP"       => 6,
    "MSC-vIP-STP"      => 3,
    "MSCv"             => 3,
    "vMSC"             => 3,
    "MSC-S-APG"        => 3,
    "HLR-FE"           => 3,
    "HLR-FE-BSP"       => 3,
    "HLR-FE-IS"        => 3,
    "vHLR-BS"          => 3,
    "MSC-S-CP"         => 0,
    "MSC-S-TSC"        => 0,
    "MSC-S-SPX"        => 0,
    "MSC-S-APG43L"     => 3,
    "MSC-S-CP-APG43L"  => 0,
    "MSC-S-TSC-APG43L" => 0,
    "MSC-S-SPX-APG43L" => 0,
    "BSP"              => 1,
    "ECEE"             => 3
);

my $freeIpv4_File = "$PWD/../dat/free_IpAddr_IPv4.txt";
my $freeIpv6_File = "$PWD/../dat/free_IpAddr_IPv6.txt";
my @freeIpv4 = ();
my @freeIpv6 = ();

if ( -e $freeIpv4_File ){
    open freeIpv4Addrs, $freeIpv4_File;
    @freeIpv4 = <freeIpv4Addrs>;
    close(freeIpv4Addrs);
}

if ( -e $freeIpv6_File ){
    open freeIpv6Addrs, $freeIpv6_File;
    @freeIpv6 = <freeIpv6Addrs>;
    close(freeIpv6Addrs);
}

# Create a config
my $Config = Config::Tiny->new;

# Open the config
$Config = Config::Tiny->read($IPV6_CONFIG_FILE_PATH);

# Root name, can be update in future such as wran
my $nw = "_";

my %simNesCountMap = ();
my @simNesArr      = ();
my $count          = 0;
my $neTypeFull     = 0;
for my $line (@NeType) {
    $neTypeFull = $line;
    my @columns = split( /\s+/, $line );
    my $NE_TYPE = 1;

    #print "-------$columns[$NE_TYPE]" . "\n";
    push( @simNesArr, $columns[$NE_TYPE] );
    $simNesCountMap{ $columns[$NE_TYPE] }++;
}

my %ipv4Map  = ();
my %ipv6Map  = ();

#------------------------------------------------
# Read ip maps from the file
#------------------------------------------------
my $ipVarsRef = ();
my $ipVarsRefFile = "$PWD/../dat/ipVars.dat";
if ( -s $ipVarsRefFile ) {
    print "$ipVarsRefFile file exist \n";
    $ipVarsRef = retrieve ($ipVarsRefFile);
    %ipv4Map = %{$$ipVarsRef[0]};
    %ipv6Map = %{$$ipVarsRef[1]};
} else {
    print "INFO: $ipVarsRefFile file DOES NOT exist \n";
}


#
#-----------------------------------------------------------------------------
#SubRoutine to get free ips
#-----------------------------------------------------------------------------
sub getFreeIpGen() {
    my ( $neType, $refFreeIpv4, $refFreeIpv6, $refIpv4Map, $refIpv6Map ) = @_;
    my (%ipv4Map_) = %$refIpv4Map;
    my (%ipv6Map_) = %$refIpv6Map;

    #print "**********************\n";
    #print map { "$_ => $ipv4Map_{$_}\n" } keys %ipv4Map_;
    #print "----------------------\n";
    #print map { "$_ => $ipv6Map_{$_}\n" } keys %ipv6Map_;
    #print "**********************\n";
    my $counter = 1;
    #print $counter++ . "- ipv4:$_" foreach ( @{$refFreeIpv4} );

    #print "\n" if ( @{$refFreeIpv4} ); $counter = 1;
    $counter = 1;
    #print $counter++ . "- ipv6:$_" foreach ( @{$refFreeIpv6} );
    print "\n";
    if ( exists $$refIpv4Map{$neType} ) {
        #print "ipv4-neType=$neType exist, ipv4Map{neType}=" . $$refIpv4Map{$neType} . "\n";
        if ( $$refIpv4Map{$neType} == 0 ) {
            delete $$refIpv4Map{$neType};
            #print "neType=$neType is deleted from ipv4Map \n";
            return;    # return nothing
        }
        elsif ( --$$refIpv4Map{$neType} == 0 ) {
            delete $$refIpv4Map{$neType};
            #print "neType=$neType is deleted from ipv4Map \n";
        }

        #print "**I was here\n";
        # make sure that free ips are available by checking
        #  free ips
        return shift( @{$refFreeIpv4} ) if @{$refFreeIpv4} > 0;

        # if freeIp addr exhausted then return nothing;
        return;
    }
    if ( exists $$refIpv6Map{$neType} ) {
        # print "ipv6-neType=$neType exist, ipv6Map{lc neType}=". $$refIpv6Map{$neType} . "\n";
        if ( $$refIpv6Map{$neType} == 0 ) {
            delete $$refIpv6Map{$neType};
            # print "neType=$neType is deleted from ipv6Map \n";
            return;    # return no nothing
        }
        elsif ( --$$refIpv6Map{$neType} == 0 ) {
            delete $$refIpv6Map{$neType};
            # print "neType=$neType is deleted from ipv6Map \n";
        }
        return shift( @{$refFreeIpv6} ) if @{$refFreeIpv6} > 0;

        # if freeIp addr exhausted then return nothing;
        return;
    }
    return;   # when none of the if clause come trues
}

#
#----------------------------------------------------------------------------------
#SubRoutine Assign IP
#----------------------------------------------------------------------------------
sub assignIP {
    ( my $indexFirst, my $indexLast, my $simPortName ) = @_;
    open listNeName, "$PWD/../dat/dumpNeName.txt";
    my @NeNames = <listNeName>;
    close(listNeName);
    open listNeType, "$PWD/../dat/dumpNeType.txt";
    my @NeType = <listNeType>;
    close(listNeType);
    open listIps, "$PWD/../dat/free_IpAddr_IPv4.txt";
    my @freeIps = <listIps>;
    close(listIps);
    open listIpv6s, "$PWD/../dat/free_IpAddr_IPv6.txt";
    my @freeIpv6s = <listIpv6s>;
    close(listIpv6s);

    my $file_simNesIpTypeMap = "$PWD/../dat/simNesIpTypeMap.dat";
    my %simNesIpTypeMap = ();

    my $countIp = 0;
    my $countIpv6 =0;
    my $countNe = $indexFirst;
    if (
        (
               "$NeNames[0]" =~ /MSC/i
            || "$NeNames[0]" =~ /BSC/i
	    || ( "$NeNames[0]" =~ /ECEE/i && ( grep {$_ =~ m/CORE ECEE/i } @NeType ))
            || "$NeNames[0]" =~ /HLR/i
            || "$NeNames[0]" =~ /^BSP/i
            || ( grep {$_ =~ m/LTE MSC/i } @NeType )
            || ( grep {$_ =~ m/LTE BSC/i } @NeType )
            || ( grep {$_ =~ m/LTE vBSC/i } @NeType )
        )
        && ( "$NeNames[0]" !~ m/BBSC/ ) && ( ! grep {$_ =~ m/ECM/i } @NeType )
      )
    {
        my $nenum = 1;
        my $default_simPortName = $simPortName;
        for ( ; $countNe < $indexLast ; $countNe++ ) {
            if (   "$NeType[$countNe]" =~ m/MSC-S-CP/i
                || "$NeType[$countNe]" =~ m/MSC-S-SPX/i
                || "$NeType[$countNe]" =~ m/MSC-S-IPLB/i
                || "$NeType[$countNe]" =~ m/MSC-S-TSC/i
                || "$NeType[$countNe]" =~ m/HLR-BS-CP/i
                || "$NeType[$countNe]" =~ m/HLR-BS-SPX/i
                || "$NeType[$countNe]" =~ m/HLR-BS-TSC/i
                || "$NeType[$countNe]" =~ m/HLR-BS-IPLB/i
)
            {
                print MML ".selectnocallback $NeNames[$countNe]";
                &assignPortNoIp($mcs_s_cpPort);
            }
            elsif ( "$NeType[$countNe]" =~ m/MSC/i && ( "$simName" =~ m/MSC10/i || "$simName" =~ m/MSC11/i || "$simName" =~ m/MSC12/i || "$simName" =~ m/MSC13/i ||"$simName" =~ m/MSC14/i || "$simName" =~ m/MSC15/i || "$simName" =~ m/MSC16/i || "$simName" =~ m/MSC17/i || "$simName" =~ m/MSC18/i || "$simName" =~ m/GSM18/i || "$simName" =~ m/GSM10/i || "$simName" =~ m/GSM11/i || "$simName" =~ m/GSM12/i || "$simName" =~ m/GSM13/i ||"$simName" =~ m/GSM14/i || "$simName" =~ m/GSM15/i || "$simName" =~ m/GSM16/i || "$simName" =~ m/GSM17/i ) && (lc "$switchToRvConf" eq "no") && (lc "$ipv6Per" eq "yes") ) {
               if ( "$NeType[$countNe]" =~ m/MSC-S-IS/i ) {
                      chomp( $freeIpv6s[$countIpv6] );
                      print MML ".selectnocallback $NeNames[$countNe]\n";
                      &assignIpAddress( $netconfPortIsTLSIpv6, $freeIpv6s[$countIpv6] );
                      $countIpv6++;
                }
               elsif ("$NeType[$countNe]" =~ m/LTE MSC-BC-IS/i) {
                      print MML ".selectnocallback $NeNames[$countNe]";
                      print MML ".modifyne checkselected .set port $msc_bc_is_tls_ipv6_prot\n";
                      print MML ".set port $msc_bc_is_tls_ipv6_prot \n";
                      chomp( $freeIpv6s[$countIpv6] );
                      print MML ".modifyne set_subaddr $freeIpv6s[$countIpv6] subaddr subaddr_nodea|subaddr_nodeb\n";
                      chomp( $freeIpv6s[$countIpv6] );
                      print MML ".set taggedaddr subaddr $freeIpv6s[$countIpv6] 1\n";
                      $countIpv6++;
                      chomp( $freeIpv6s[$countIpv6] );
                      print MML ".set taggedaddr subaddr_nodea $freeIpv6s[$countIpv6] 1\n";
                      $countIpv6++;
                      chomp( $freeIpv6s[$countIpv6] );
                      print MML ".set taggedaddr subaddr_nodeb $freeIpv6s[$countIpv6] 1\n";
                      $countIpv6++;
                      chomp( $freeIpv6s[$countIpv6] );
                      print MML ".set taggedaddr subaddr_ap2 $freeIpv6s[$countIpv6] 1\n";
                      $countIpv6++;
                      chomp( $freeIpv6s[$countIpv6] );
                      print MML ".set taggedaddr subaddr_ap2nodea $freeIpv6s[$countIpv6] 1\n";
                      $countIpv6++;
                      chomp( $freeIpv6s[$countIpv6] );
                      print MML ".set taggedaddr subaddr_ap2nodeb $freeIpv6s[$countIpv6] 1\n";
                      $countIpv6++;
                      print MML ".set save\n";
                      &setDD( $msc_bc_is_tls_ipv6_prot );
                }
                elsif ( "$NeType[$countNe]" =~ m/CTC-MSC-BC-BSP/i) {
                      print MML ".selectnocallback $NeNames[$countNe]";
                      print MML ".modifyne checkselected .set port $agptcp_netconf_http_https_tls_ipv6_prot port\n";
                      print MML ".set port $agptcp_netconf_http_https_tls_ipv6_prot \n";
                      chomp( $freeIpv6s[$countIpv6] );
                      print MML ".modifyne set_subaddr $freeIpv6s[$countIpv6] subaddr subaddr_nodea|subaddr_nodeb\n";
                      chomp( $freeIpv6s[$countIpv6] );
                      print MML ".set taggedaddr subaddr $freeIpv6s[$countIpv6] 1\n";
                      $countIpv6++;
                      chomp( $freeIpv6s[$countIpv6] );
                      print MML ".set taggedaddr subaddr_nodea $freeIpv6s[$countIpv6] 1\n";
                      $countIpv6++;
                      chomp( $freeIpv6s[$countIpv6] );
                      print MML ".set taggedaddr subaddr_nodeb $freeIpv6s[$countIpv6] 1\n";
                      $countIpv6++;
                      print MML ".set save\n";
                      &setDD( $agptcp_netconf_http_https_tls_ipv6_prot );
                }
                elsif ( "$NeType[$countNe]" =~ m/MSC-BC-BSP/i) {
                      print MML ".selectnocallback $NeNames[$countNe]";
                      print MML ".modifyne checkselected .set port $agptcp_netconf_http_https_tls_ipv6_prot port\n";
                      print MML ".set port $agptcp_netconf_http_https_tls_ipv6_prot \n";
                      chomp( $freeIpv6s[$countIpv6] );
                      print MML ".modifyne set_subaddr $freeIpv6s[$countIpv6] subaddr subaddr_nodea|subaddr_nodeb\n";
                      chomp( $freeIpv6s[$countIpv6] );
                      print MML ".set taggedaddr subaddr $freeIpv6s[$countIpv6] 1\n";
                      $countIpv6++;
                      chomp( $freeIpv6s[$countIpv6] );
                      print MML ".set taggedaddr subaddr_nodea $freeIpv6s[$countIpv6] 1\n";
                      $countIpv6++;
                      chomp( $freeIpv6s[$countIpv6] );
                      print MML ".set taggedaddr subaddr_nodeb $freeIpv6s[$countIpv6] 1\n";
                      $countIpv6++;
                      chomp( $freeIpv6s[$countIpv6] );
                      print MML ".set taggedaddr subaddr_ap2 $freeIpv6s[$countIpv6] 1\n";
                      $countIpv6++;
                      chomp( $freeIpv6s[$countIpv6] );
                      print MML ".set taggedaddr subaddr_ap2nodea $freeIpv6s[$countIpv6] 1\n";
                      $countIpv6++;
                      chomp( $freeIpv6s[$countIpv6] );
                      print MML ".set taggedaddr subaddr_ap2nodeb $freeIpv6s[$countIpv6] 1\n";
                      $countIpv6++;
                      print MML ".set save\n";
                      &setDD( $agptcp_netconf_http_https_tls_ipv6_prot );
                }
               elsif ("$NeType[$countNe]" =~ m/LTE MSC/i) {
                     print MML ".selectnocallback $NeNames[$countNe]";
                     print MML ".modifyne checkselected .set port $agptcp_netconf_http_https_tls_ipv6_prot port\n";
                     print MML ".set port $agptcp_netconf_http_https_tls_ipv6_prot \n";
                     chomp( $freeIpv6s[$countIpv6] );
                     print MML ".modifyne set_subaddr $freeIpv6s[$countIpv6] subaddr subaddr_nodea|subaddr_nodeb\n";
                     chomp( $freeIpv6s[$countIpv6] );
                     print MML ".set taggedaddr subaddr $freeIpv6s[$countIpv6] 1\n";
                     $countIpv6++;
                     chomp( $freeIpv6s[$countIpv6] );
                     print MML ".set taggedaddr subaddr_nodea $freeIpv6s[$countIpv6] 1\n";
                     $countIpv6++;
                     chomp( $freeIpv6s[$countIpv6] );
                     print MML ".set taggedaddr subaddr_nodeb $freeIpv6s[$countIpv6] 1\n";
                     $countIpv6++;
                     print MML ".set save\n";
                     &setDD( $agptcp_netconf_http_https_tls_ipv6_prot );
              }
              else
                {
                    if ("$NeType[$countNe]" =~ m/msc.*apg43l/i)
                    {
                       $simPortName = "$apg43l_port_ipv6";
                    }
                    elsif ("$NeType[$countNe]" =~ m/MSC-BC-IS/i)
                    {
                       $simPortName = "$msc_bc_is_tls_ipv6_prot";
                    }
                    elsif ("$NeType[$countNe]" =~ m/LTE.*MSC/i)
                    {
                       $simPortName = "$agptcp_netconf_http_https_tls_ipv6_prot";
                    }
                    else
                    {
                       $simPortName = "$apg43l_port_ipv6";
                    }
                print MML ".selectnocallback $NeNames[$countNe]";
                print MML ".modifyne checkselected .set port $simPortName port\n";
                print MML ".set port $simPortName \n";
                chomp( $freeIpv6s[$countIpv6] );
                print MML ".modifyne set_subaddr $freeIpv6s[$countIpv6] subaddr subaddr_nodea|subaddr_nodeb\n";
                chomp( $freeIpv6s[$countIpv6] );
                print MML ".set taggedaddr subaddr $freeIpv6s[$countIpv6] 1\n";
                $countIpv6++;
                chomp( $freeIpv6s[$countIpv6] );
                print MML ".set taggedaddr subaddr_nodea $freeIpv6s[$countIpv6] 1\n";
                $countIpv6++;
                chomp( $freeIpv6s[$countIpv6] );
                print MML ".set taggedaddr subaddr_nodeb $freeIpv6s[$countIpv6] 1\n";
                $countIpv6++;
                print MML ".set save\n";
                &setDD( $simPortName );
               }
            }
            elsif ( "$NeType[$countNe]" =~ m/MSC-S-IS/i ) {
                chomp( $freeIps[$countIp] );
                print MML ".selectnocallback $NeNames[$countNe]\n";
                &assignIpAddress( $netconfPortIsTLS, $freeIps[$countIp] );
                $countIp++;
            }
            elsif ( ("$NeType[$countNe]" =~ m/BSP/i) && ("$NeType[$countNe]" !~ m/MSC/i) && ("$NeType[$countNe]" !~ m/HLR/i) ) {
              chomp( $freeIps[$countIp] );
               print MML ".selectnocallback $NeNames[$countNe]\n";
               &assignIpAddress( $netconfSSHPort, $freeIps[$countIp] );
               $countIp++;
               &setDD($netconfSSHPort);
            }
            elsif ("$NeNames[$countNe]" =~ m/$stnName/i
                || "$NeNames[$countNe]" =~ /$stnTCUName/i
                || "$NeNames[$countNe]" =~ /$stnPICOName/i )
            {
                print MML ".selectnocallback $NeNames[$countNe]";
                chomp( $freeIps[$countIp] );
                &assignIpAddress( $stnPort, $freeIps[$countIp] );
                $countIp++;

            }
            elsif ( index( $NeNames[$countNe], $timeServer ) != -1 ) {
                print MML ".selectnocallback $NeNames[$countNe]";
                &assignPortNoIp($timeServerPort);
            }
            elsif ( "$NeType[$countNe]" =~ m/LANSWITCH/i ) {
                      print MML ".selectnocallback $NeNames[$countNe]";
                      chomp( $freeIps[$countIp] );
                      &assignIpAddress( $snmpsshtelnet_prot, $freeIps[$countIp] );
                      &setDD( $snmpsshtelnet_prot );
                      $countIp++;
            }
           elsif ( "$NeType[$countNe]" =~ m/MSRBS-V2/i ) {
                      print MML ".selectnocallback $NeNames[$countNe]";
                      chomp( $freeIps[$countIp] );
                      &assignIpAddress( $netconfHTTPSTLSPort , $freeIps[$countIp] );
                      &setDD( $netconfHTTPSTLSPort );
                      $countIp++;
            }
	    elsif ( "$NeType[$countNe]" =~ m/CONTROLLER6610/i ) {
                      print MML ".selectnocallback $NeNames[$countNe]";
                      chomp( $freeIps[$countIp] );
                      &assignIpAddress( $netconfHTTPSTLSPort , $freeIps[$countIp] );
                      &setDD( $netconfHTTPSTLSPort );
                      $countIp++;
            }
            elsif ("$NeType[$countNe]" =~ m/LTE MSC-BC-IS/i) {
                      print MML ".selectnocallback $NeNames[$countNe]";
                      print MML ".modifyne checkselected .set port $msc_bc_is_tls_prot\n";
                      print MML ".set port $msc_bc_is_tls_prot \n";
                      chomp( $freeIps[$countIp] );
                      print MML ".modifyne set_subaddr $freeIps[$countIp] subaddr subaddr_nodea|subaddr_nodeb\n";
                      chomp( $freeIps[$countIp] );
                      print MML ".set taggedaddr subaddr $freeIps[$countIp] 1\n";
                      $countIp++;
                      chomp( $freeIps[$countIp] );
                      print MML ".set taggedaddr subaddr_nodea $freeIps[$countIp] 1\n";
                      $countIp++;
                      chomp( $freeIps[$countIp] );
                      print MML ".set taggedaddr subaddr_nodeb $freeIps[$countIp] 1\n";
                      $countIp++;
                      chomp( $freeIps[$countIp] );
                      print MML ".set taggedaddr subaddr_ap2 $freeIps[$countIp] 1\n";
                      $countIp++;
                      chomp( $freeIps[$countIp] );
                      print MML ".set taggedaddr subaddr_ap2nodea $freeIps[$countIp] 1\n";
                      $countIp++;
                      chomp( $freeIps[$countIp] );
                      print MML ".set taggedaddr subaddr_ap2nodeb $freeIps[$countIp] 1\n";
                      $countIp++;
                      print MML ".set save\n";
                      &setDD( $msc_bc_is_tls_prot );
            }
            elsif ("$NeType[$countNe]" =~ m/LTE BSC/i || "$NeType[$countNe]" =~ m/LTE vBSC/i) {
                      print MML ".selectnocallback $NeNames[$countNe]";
                      print MML ".modifyne checkselected .set port $agptcp_netconf_http_https_tls_prot port\n";
                      print MML ".set port $agptcp_netconf_http_https_tls_prot \n";
                      chomp( $freeIps[$countIp] );
                      print MML ".modifyne set_subaddr $freeIps[$countIp] subaddr subaddr_nodea|subaddr_nodeb\n";
                      chomp( $freeIps[$countIp] );
                      print MML ".set taggedaddr subaddr $freeIps[$countIp] 1\n";
                      $countIp++;
                      chomp( $freeIps[$countIp] );
                      print MML ".set taggedaddr subaddr_nodea $freeIps[$countIp] 1\n";
                      $countIp++;
                      chomp( $freeIps[$countIp] );
                      print MML ".set taggedaddr subaddr_nodeb $freeIps[$countIp] 1\n";
                      $countIp++;
                      print MML ".set save\n";
                      &setDD( $agptcp_netconf_http_https_tls_prot );
            }
	     elsif ("$NeType[$countNe]" =~ m/ECEE/i ) {
                      print MML ".selectnocallback $NeNames[$countNe]";
                       print MML ".modifyne checkselected .set port $HTTPHTTPSPort port\n";
                      chomp( $freeIps[$countIp] );
                      print MML ".modifyne set_subaddr $freeIps[$countIp] subaddr no_value \n";
                      print MML ".set taggedaddr subaddr $freeIps[$countIp] 1\n";
                      chomp( $freeIps[$countIp] );
                      print MML " .set taggedaddr  ipAddressvCic1 $freeIps[$countIp] 1\n";
                      $countIp++;
                      chomp( $freeIps[$countIp] );
                      print MML " .set taggedaddr  ipAddressvCic2 $freeIps[$countIp] 1\n";
                      $countIp++;
                      chomp( $freeIps[$countIp] );
                      print MML " .set taggedaddr  ipAddressvCic3 $freeIps[$countIp] 1\n";
                      $countIp++;
                      print MML ".set save\n";
                      &setDD( $HTTPHTTPSPort );
            }

            elsif ( "$NeType[$countNe]" =~ m/CTC-MSC-BC-BSP/i) {
                      print MML ".selectnocallback $NeNames[$countNe]";
                      print MML ".modifyne checkselected .set port $agptcp_netconf_http_https_tls_prot port\n";
                      print MML ".set port $agptcp_netconf_http_https_tls_prot \n";
                      chomp( $freeIps[$countIp] );
                      print MML ".modifyne set_subaddr $freeIps[$countIp] subaddr subaddr_nodea|subaddr_nodeb\n";
                      chomp( $freeIps[$countIp] );
                      print MML ".set taggedaddr subaddr $freeIps[$countIp] 1\n";
                      $countIp++;
                      chomp( $freeIps[$countIp] );
                      print MML ".set taggedaddr subaddr_nodea $freeIps[$countIp] 1\n";
                      $countIp++;
                      chomp( $freeIps[$countIp] );
                      print MML ".set taggedaddr subaddr_nodeb $freeIps[$countIp] 1\n";
                      $countIp++;
                      print MML ".set save\n";
                      &setDD( $agptcp_netconf_http_https_tls_prot );
        }
        elsif ( "$NeType[$countNe]" =~ m/MSC-BC-BSP/i) {
                      print MML ".selectnocallback $NeNames[$countNe]";
                      print MML ".modifyne checkselected .set port $agptcp_netconf_http_https_tls_prot port\n";
                      print MML ".set port $agptcp_netconf_http_https_tls_prot \n";
                      chomp( $freeIps[$countIp] );
                      print MML ".modifyne set_subaddr $freeIps[$countIp] subaddr subaddr_nodea|subaddr_nodeb\n";
                      chomp( $freeIps[$countIp] );
                      print MML ".set taggedaddr subaddr $freeIps[$countIp] 1\n";
                      $countIp++;
                      chomp( $freeIps[$countIp] );
                      print MML ".set taggedaddr subaddr_nodea $freeIps[$countIp] 1\n";
                      $countIp++;
                      chomp( $freeIps[$countIp] );
                      print MML ".set taggedaddr subaddr_nodeb $freeIps[$countIp] 1\n";
                      $countIp++;
                      chomp( $freeIps[$countIp] );
                      print MML ".set taggedaddr subaddr_ap2 $freeIps[$countIp] 1\n";
                      $countIp++;
                      chomp( $freeIps[$countIp] );
                      print MML ".set taggedaddr subaddr_ap2nodea $freeIps[$countIp] 1\n";
                      $countIp++;
                      chomp( $freeIps[$countIp] );
                      print MML ".set taggedaddr subaddr_ap2nodeb $freeIps[$countIp] 1\n";
                      $countIp++;
                      print MML ".set save\n";
                      &setDD( $agptcp_netconf_http_https_tls_prot );
        }
        elsif ("$NeType[$countNe]" =~ m/LTE MSC/i) {
                      print MML ".selectnocallback $NeNames[$countNe]";
                      print MML ".modifyne checkselected .set port $agptcp_netconf_http_https_tls_prot port\n";
                      print MML ".set port $agptcp_netconf_http_https_tls_prot \n";
                      chomp( $freeIps[$countIp] );
                      print MML ".modifyne set_subaddr $freeIps[$countIp] subaddr subaddr_nodea|subaddr_nodeb\n";
                      chomp( $freeIps[$countIp] );
                      print MML ".set taggedaddr subaddr $freeIps[$countIp] 1\n";
                      $countIp++;
                      chomp( $freeIps[$countIp] );
                      print MML ".set taggedaddr subaddr_nodea $freeIps[$countIp] 1\n";
                      $countIp++;
                      chomp( $freeIps[$countIp] );
                      print MML ".set taggedaddr subaddr_nodeb $freeIps[$countIp] 1\n";
                      $countIp++;
                      print MML ".set save\n";
                      &setDD( $agptcp_netconf_http_https_tls_prot );
        }
        elsif ( "$NeType[$countNe]" =~ m/IS IS/i ) {
                      print MML ".selectnocallback $NeNames[$countNe]";
                      chomp( $freeIps[$countIp] );
                      &assignIpAddress( $isProt , $freeIps[$countIp] );
                      &setDD( $isProt );
                      $countIp++;
        }
            # This else block will cover MSC,MSC-S-APG43L,MSC-S-APG40 and BSC
        else
                 {
                 if ( "$simName" =~ m/BSC/i )
                   {
                        if ("$NeType[$countNe]" =~ m/bsc.*apg43l/i){
                             $simPortName = "APG43L_APGTCP";
                        }
                        elsif("$NeType[$countNe]" =~ m/BSC/i)
                        {
                           $simPortName = "$agptcp_netconf_http_https_tls_prot";
                        }
                   }

                  if ( "$NeType[$countNe]" =~ m/HLR-FE/i || "$NeType[$countNe]" =~ m/vHLR-BS/i )
                    {
                     $simPortName = "$agptcp_netconf_http_https_tls_prot";

                    }
                    
                     

                 if ( "$NeType[$countNe]" =~ m/MSC/i )
                   {
                      if ("$NeType[$countNe]" =~ m/msc.*apg43l/i)
                          {
                             $simPortName = "$apg43l_port";
                          }
                         elsif ("$NeType[$countNe]" =~ m/MSC-BC-IS/i)
                         {
                            $simPortName = "$msc_bc_is_tls_prot";
                         }
                       elsif ("$NeType[$countNe]" =~ m/LTE.*MSC/i)
                         {
                            $simPortName = "$agptcp_netconf_http_https_tls_prot";
                         }
                       else
                       {
                           $simPortName = "$apg43l_port";
                       }
                   }
                print MML ".selectnocallback $NeNames[$countNe]";
                print MML ".modifyne checkselected .set port $simPortName port\n";
                print MML ".set port $simPortName \n";
                chomp( $freeIps[$countIp] );
                print MML ".modifyne set_subaddr $freeIps[$countIp] subaddr subaddr_nodea|subaddr_nodeb\n";
                chomp( $freeIps[$countIp] );
                print MML ".set taggedaddr subaddr $freeIps[$countIp] 1\n";
                $countIp++;
                chomp( $freeIps[$countIp] );
                print MML ".set taggedaddr subaddr_nodea $freeIps[$countIp] 1\n";
                $countIp++;
                chomp( $freeIps[$countIp] );
                print MML ".set taggedaddr subaddr_nodeb $freeIps[$countIp] 1\n";
                $countIp++;
                print MML ".set save\n";
                &setDD( $simPortName );
            }
        }
    }
  #below loop is for ECM nodes combination
  elsif (( (grep {$_ =~ m/ECM/i } @NeType) &&  $indexLast >= 1 && (grep {$_ !~ m/ECM-RNFVO/i } @NeType) )){
            for ( ; $countNe < $indexLast ; $countNe++ ) {
                if ("$NeType[$countNe]" =~ m/ECM/i ) {
                   chomp( $freeIps[$countIp] );
                   print MML ".selectnocallback $NeNames[$countNe]\n";
                   &assignIpAddress( $HTTPHTTPSPort, $freeIps[$countIp] );
                   &setDD( $HTTPHTTPSPort );
                   $countIp++;
                }
               elsif ( "$NeType[$countNe]" =~ m/LANSWITCH/i ) {
                print MML ".selectnocallback $NeNames[$countNe]";
                chomp( $freeIps[$countIp] );
                &assignIpAddress( $snmpsshtelnet_prot, $freeIps[$countIp] );
                &setDD( $snmpsshtelnet_prot );
                $countIp++;
               }
               elsif ( "$NeType[$countNe]" =~ m/MSRBS-V2/i ) {
                      print MML ".selectnocallback $NeNames[$countNe]";
                      chomp( $freeIps[$countIp] );
                      &assignIpAddress( $netconfHTTPSTLSPort , $freeIps[$countIp] );
                      &setDD( $netconfHTTPSTLSPort );
                      $countIp++;
                }
               elsif ( "$NeType[$countNe]" =~ m/MSC/i && ( "$simName" =~ m/MSC10/i || "$simName" =~ m/MSC11/i || "$simName" =~ m/MSC12/i || "$simName" =~ m/MSC13/i ||"$simName" =~ m/MSC14/i || "$simName" =~ m/MSC15/i || "$simName" =~ m/MSC16/i || "$simName" =~ m/MSC17/i || "$simName" =~ m/MSC18/i || "$simName" =~ m/GSM18/i || "$simName" =~ m/GSM10/i || "$simName" =~ m/GSM11/i || "$simName" =~ m/GSM12/i || "$simName" =~ m/GSM13/i ||"$simName" =~ m/GSM14/i || "$simName" =~ m/GSM15/i || "$simName" =~ m/GSM16/i || "$simName" =~ m/GSM17/i) && (lc "$switchToRvConf" eq "no") )
               {
                      if ("$NeType[$countNe]" =~ m/MSC.*apg43l/i)
                      {
                           $simPortName = "APG43L_APGTCP_IPV6";
                        }
                     elsif ("$NeType[$countNe]" =~ m/LTE.*MSC/i )
                     {
                           $simPortName = "APG_NETCONF_HTTP_HTTPS_TLS_IPV6_PROT";
                     }
                print MML ".selectnocallback $NeNames[$countNe]";
                print MML ".modifyne checkselected .set port $simPortName port\n";
                print MML ".set port $simPortName \n";
                chomp( $freeIpv6s[$countIpv6] );
                print MML ".modifyne set_subaddr $freeIpv6s[$countIpv6] subaddr subaddr_nodea|subaddr_nodeb\n";
                chomp( $freeIpv6s[$countIpv6] );
                print MML ".set taggedaddr subaddr $freeIpv6s[$countIpv6] 1\n";
                $countIpv6++;
                chomp( $freeIpv6s[$countIpv6] );
                print MML ".set taggedaddr subaddr_nodea $freeIpv6s[$countIpv6] 1\n";
                $countIpv6++;
                chomp( $freeIpv6s[$countIpv6] );
                print MML ".set taggedaddr subaddr_nodeb $freeIpv6s[$countIpv6] 1\n";
                $countIpv6++;
                print MML ".set save\n";
                &setDD( $simPortName );
              }
              elsif ( "$NeType[$countNe]" =~ m/BSC/i || "$NeType[$countNe]" =~ m/MSC/i ) {
                      if ("$NeType[$countNe]" =~ m/bsc.*apg43l/i)
                          {
                             $countIp = $countIp - 3;
                             $simPortName = "APG43L_APGTCP";
                          }
                      elsif ( "$NeType[$countNe]" =~ m/LTE.*BSC/i )
                        {
                           $simPortName = "APG_NETCONF_HTTP_HTTPS_TLS_PROT";
                        }
                     elsif ("$NeType[$countNe]" =~ m/MSC.*apg43l/i)
                        {
                           $countIp = $countIp + 1;
                           $simPortName = "APG43L_APGTCP";
                        }
                     elsif ("$NeType[$countNe]" =~ m/LTE.*MSC/i )
                        {
                           $simPortName = "APG_NETCONF_HTTP_HTTPS_TLS_PROT";
                        }

                print MML ".selectnocallback $NeNames[$countNe]";
                print MML
                  ".modifyne checkselected .set port $simPortName port\n";
                print MML ".set port $simPortName \n";
                chomp( $freeIps[$countIp] );
                print MML
                ".modifyne set_subaddr $freeIps[$countIp] subaddr subaddr_nodea|subaddr_nodeb\n";
                chomp( $freeIps[$countIp] );
                print MML ".set taggedaddr subaddr $freeIps[$countIp] 1\n";
                $countIp++;
                chomp( $freeIps[$countIp] );
                print MML
                  ".set taggedaddr subaddr_nodea $freeIps[$countIp] 1\n";
                $countIp++;
                chomp( $freeIps[$countIp] );
                print MML
                  ".set taggedaddr subaddr_nodeb $freeIps[$countIp] 1\n";
                $countIp++;
                print MML ".set save\n";
		&setDD( $simPortName );
                }
         }
  }

    else {
        # NEW IPV6 way of handling  sims
        #------------------------
        my $lastIp;
        my $countNe = 0;
        for my $ne (@simNesArr) {
            my $neName = $NeNames[$countNe];
            print MML ".selectnocallback $neName";
            chomp($neName);

            my ($ip) = &getFreeIpGen( $ne, \@freeIpv4, \@freeIpv6, \%ipv4Map,
                \%ipv6Map );
            if ( !defined $ip ){
                print "undefined-ip for ne=$ne \n";

                # Map to be used while creating arne xml
                if ( $lastIp =~ /:/ ) {
                    $simNesIpTypeMap{"$neName"} = 'ipv6';
                }
                else {
                    $simNesIpTypeMap{"$neName"} = 'ipv4';
                }

                if ( $ne =~ "GSN" ) {
                    $simPortName = "$simPortName" . "-GSN";
                    &assignIpAddress( $simPortName, $lastIp );
                    &setDD( $createDefaultDestinationName );
                    $countNe++;
                }
                next;
            }
            #print "assignPort-defined-ip=$ip";
            chomp($ip);
            $lastIp = $ip;

            # Map to be used while creating arne xml
            if ( $ip =~ /:/ ) {
                $simNesIpTypeMap{"$neName"} = 'ipv6';
            }
            else {
                $simNesIpTypeMap{"$neName"} = 'ipv4';
            }
            print "INFO: node=$ne, ip=$ip \n";
           #------------------------------------------------------------
           #Handling for Dynamic Yang nodes
           #-------------------------------------------------------------
           if (  $simName =~ m/Yang/i ) {
           
               if (( "$NeType[$countNe]" =~ "LTE oRU" ) ) {
                if ( $ip =~ /:/ ) {
                     print "INFO: IPV6 port=$o1_Port \n";
                     &assignIpAddress( $o1_Port, $ip );
                     &setDD( $o1_Port );
                 } else {
                     print "INFO: IPV4 port=$o1_Port\n";
                     &assignIpAddress( $o1_Port, $ip );
                     &setDD( $o1_Port );
                 }
             }
             elsif (( "$NeType[$countNe]" =~ "LTE vDU" ) ) {
                if ( $ip =~ /:/ ) {
                     print "INFO: IPV6 port=$yangsnmpTLSPort_Ipv6 \n";
                     &assignIpAddress( $yangsnmpTLSPort_Ipv6, $ip );
                     &setDD( $yangsnmpTLSPort_Ipv6 );
                 } else {
                     print "INFO: IPV4 port=$yangsnmpTLSPort\n";
                     &assignIpAddress( $yangsnmpTLSPort, $ip );
                     &setDD( $yangsnmpTLSPort );
                 }
             }
               
             elsif ( ( $neTypeFull =~ "vDU" || $neTypeFull =~ m/vCU/i  || $neTypeFull =~ m/vCU-CP/i || $neTypeFull =~ m/vCU-UP/i ||  $neTypeFull =~ m/RDM/i ) ) {
                if ( $ip =~ /:/ ) {
                     print "INFO: IPV6 port=$yangsnmpTLSPort_Ipv6 \n";
                     &assignIpAddress( $yangsnmpTLSPort_Ipv6, $ip );
                     &setDD( $yangsnmpTLSPort_Ipv6 );
                 } else {
                     print "INFO: IPV4 port=$yangsnmpTLSPort\n";
                     &assignIpAddress( $yangsnmpTLSPort, $ip );
                     &setDD( $yangsnmpTLSPort );
                 }
             }
             elsif ( $neTypeFull =~ m/GenericADP/i  || $neTypeFull =~ m/EPG-OI/i || $neTypeFull =~ m/vEPG-OI/i  ) {
                    if ( $ip =~ /:/ ) {
                        print "INFO: IPV6 port=$yangsnmpSSHEPGPort_Ipv6 \n";
                        &assignIpAddress( $yangsnmpSSHEPGPort_Ipv6, $ip );
                        &setDD($yangsnmpSSHEPGPort_Ipv6 );
                    } else {
                        print "INFO: IPV4 port=$yangsnmpSSHEPGPort\n";
                        &assignIpAddress( $yangsnmpSSHEPGPort, $ip );
                        &setDD( $yangsnmpSSHEPGPort );
                    }
             }
             elsif ( ( $neTypeFull =~ "CCDM" || $neTypeFull =~ "CCPC" || $neTypeFull =~ "CCRC" || $neTypeFull =~ "CCSM" || $neTypeFull =~ "LTE SC" || $neTypeFull =~ "CCES" || $neTypeFull =~ "WMG-OI" || $neTypeFull =~ "vWMG-OI"  ) ) {
         if ( $ip =~ /:/ ) {
                      print "INFO: IPV6 port=$yangsnmpSSHWMGPort_Ipv6 \n";
                      &assignIpAddress( $yangsnmpSSHWMGPort_Ipv6, $ip );
                      &setDD( $yangsnmpSSHWMGPort_Ipv6 );
                  } else {
                      print "INFO: IPV4 port=$yangsnmpSSHWMGPort\n";
                      &assignIpAddress( $yangsnmpSSHWMGPort, $ip );
                      &setDD( $yangsnmpSSHWMGPort );
                   }
         }
                   elsif ( ( $neTypeFull =~ "O1.*"  ) ) {
       
                    print "INFO: IPV4 port=$o1_Port\n";
                    &assignIpAddress( $o1_Port, $ip );
                    &setDD( $o1_Port);
}
        elsif ( ( $neTypeFull =~ "SMSF" )) {
                 if ( $ip =~ /:/ ) {
                      print "INFO: IPV6 port=$yangsnmpSSHSMSFPort_Ipv6 \n";
                      &assignIpAddress( $yangsnmpSSHSMSFPort_Ipv6, $ip );
                      &setDD( $yangsnmpSSHSMSFPort_Ipv6 );
                  } else {
                      print "INFO: IPV4 port=$yangsnmpSSHSMSFPort\n";
                      &assignIpAddress( $yangsnmpSSHSMSFPort, $ip );
                      &setDD( $yangsnmpSSHSMSFPort );
                   }
 
            }
          elsif ( ( $neTypeFull =~ "PCG"  || $neTypeFull =~ "PCC" || $neTypeFull =~ "Shared-CNF" || $neTypeFull =~ "cIMS" ) ) {
                 if ( $ip =~ /:/ ) {
                      print "INFO: IPV6 port=$yangsnmpSSHPort_Ipv6 \n";
                      &assignIpAddress( $yangsnmpSSHPort_Ipv6, $ip );
                      &setDD( $yangsnmpSSHPort_Ipv6 );
                  } else {
                      print "INFO: IPV4 port=$yangsnmpSSHPort\n";
                      &assignIpAddress( $yangsnmpSSHPort, $ip );
                      &setDD( $yangsnmpSSHPort );
                   }
            }
         
           
  }
            #------------------------------------------------------------
            #Handling for Pico and WRAN DG2 nodes
            #------------------------------------------------------------
            
            elsif ( $ne=~ "vPP" || $ne=~ "vRC" || $ne=~ "vSD" || $ne=~ "RNNODE" || $ne=~ "5GRadioNode" || $ne=~ "VTIF" || $ne=~ "VTFRadioNode" || $ne=~ "vRM" || $ne=~ "vRSM" ) {
                if ( $ip =~ /:/ ) {
                    if (lc "$securityStatusTLS" ne lc "OFF") {
                        print "INFO: IPV6 port=$netconfTLSPort_Ipv6  while TLS=$securityStatusTLS\n";
                        &assignIpAddress( $netconfTLSPort_Ipv6, $ip );
                        &setDD( $netconfTLSPort_Ipv6 );
                    } else {
                         print "INFO: IPV6 port=$netconfSSHDG2Port  while TLS=$securityStatusTLS\n";
                        &assignIpAddress( $netconfSSHDG2Port, $ip );
                        &setDD( $netconfSSHDG2Port );
                    }
                }
                else {
                    if (lc "$securityStatusTLS" ne lc "OFF") {
                        print "INFO: IPV4 port=$netconfTLSPort while TLS=$securityStatusTLS \n";
                        &assignIpAddress( $netconfTLSPort, $ip );
                        &setDD( $netconfTLSPort );
                    } else {
                        print "INFO: IPV4 port=$netconfSSHDG2Port while TLS=$securityStatusTLS \n";
                        &assignIpAddress( $netconfSSHDG2Port, $ip );
                        &setDD( $netconfSSHDG2Port );
                    }
                }
            }
            elsif (  $ne =~ "PRBS" || $ne =~ "MSRBS-V1") {
                if ( $ip =~ /:/ ) {
                    if (lc "$securityStatusTLS" ne lc "OFF") {
                        print "INFO: IPV6 port=$netconfTLSPort_Ipv6  while TLS=$securityStatusTLS\n";
                        &assignIpAddress( $netconfTLSPort_Ipv6, $ip );
                        &setDD( $netconfTLSPort_Ipv6 );
                    } else {
                         print "INFO: IPV6 port=$netconfSSHPort  while TLS=$securityStatusTLS\n";
                        &assignIpAddress( $netconfSSHPort, $ip );
                        &setDD( $netconfSSHPort );
                    }
                }
                else {
                    if (lc "$securityStatusTLS" ne lc "OFF") {
                        print "INFO: IPV4 port=$netconfTLSPort while TLS=$securityStatusTLS \n";
                        &assignIpAddress( $netconfTLSPort, $ip );
                        &setDD( $netconfTLSPort );
                    } else {
                        print "INFO: IPV4 port=$netconfSSHPort while TLS=$securityStatusTLS \n";
                        &assignIpAddress( $netconfSSHPort, $ip );
                        &setDD( $netconfSSHPort );
                    }
                }
            }
            elsif ( $ne =~ "MSRBS-V2" && $simName =~ "NRAT-SSH" ) {
                if ( $ip =~ /:/ ) {
                    print "INFO: IPV6 port=$netconfHTTPSSSHPort_Ipv6  while TLS=$securityStatusTLS\n";
                    &assignIpAddress( $netconfHTTPSSSHPort_Ipv6, $ip );
                    &setDD( $netconfHTTPSSSHPort_Ipv6 );
                }
                else {
                    print "INFO: IPV4 port=$netconfHTTPSSSHPort while TLS=$securityStatusTLS \n";
                    &assignIpAddress( $netconfHTTPSSSHPort, $ip );
                    &setDD( $netconfHTTPSSSHPort );
                }
            }
            elsif ( $ne=~ "MSRBS-V2" || $ne=~ "RAN-VNFM" || $ne=~ "EVNFM" || $ne=~ "VNF-LCM" || $ne=~ "CONTROLLER6610" ) {
                if ( $ip =~ /:/ ) {
                    if (lc "$securityStatusTLS" ne lc "OFF") {
                        print "INFO: IPV6 port=$netconfHTTPSTLSPort_Ipv6  while TLS=$securityStatusTLS\n";
                        &assignIpAddress( $netconfHTTPSTLSPort_Ipv6, $ip );
                        &setDD( $netconfHTTPSTLSPort_Ipv6 );
                    } else {
                         print "INFO: IPV6 port=$netconfHTTPSSSHPort_Ipv6  while TLS=$securityStatusTLS\n";
                        &assignIpAddress( $netconfHTTPSSSHPort_Ipv6, $ip );
                        &setDD( $netconfHTTPSSSHPort_Ipv6 );
                    }
                }
                else {
                    if (lc "$securityStatusTLS" ne lc "OFF") {
                        print "INFO: IPV4 port=$netconfHTTPSTLSPort while TLS=$securityStatusTLS \n";
                        &assignIpAddress( $netconfHTTPSTLSPort, $ip );
                        &setDD( $netconfHTTPSTLSPort );
                    } else {
                        print "INFO: IPV4 port=$netconfHTTPSSSHPort while TLS=$securityStatusTLS \n";
                        &assignIpAddress( $netconfHTTPSSSHPort, $ip );
                        &setDD( $netconfHTTPSSSHPort );
                    }
                }
            }
            elsif (  $ne=~ "OpenMano" || $ne=~ "RNFVO" || $ne=~ "HDS" || $ne=~ "HP-NFVO" || $ne=~ "SDI" ) {
                if ( $ip =~ /:/ ) {
                        print "INFO: IPV6 port=$HTTPHTTPSPort_ipv6  while TLS=$securityStatusTLS\n";
                        &assignIpAddress( $HTTPHTTPSPort_ipv6, $ip );
                        &setDD( $HTTPHTTPSPort_ipv6 );
                    } else {
                        print "INFO: IPV4 port=$HTTPHTTPSPort while TLS=$securityStatusTLS \n";
                        &assignIpAddress( $HTTPHTTPSPort, $ip );
                        &setDD( $HTTPHTTPSPort );
                    }
                }
            elsif (  $ne=~ "FRONTHAUL" && $simName =~ 6392) {
                if ( $ip =~ /:/ ) {
                        print "INFO: IPV6 port=$ml6352_port_Ipv6  while TLS=$securityStatusTLS\n";
                        &assignIpAddress( $ml6352_port_Ipv6, $ip );
                        &setDD( $ml6352_port_Ipv6 );
                    } else {
                        print "INFO: IPV4 port=$ml6352_port while TLS=$securityStatusTLS \n";
                        &assignIpAddress( $ml6352_port, $ip );
                        &setDD( $ml6352_port );
                    }
                }
            elsif (  $ne=~ "FrontHaul-6020" || $ne=~ "FrontHaul-6650" ||  $ne=~ "FrontHaul-6000" ) {
                my $FH_neTypeFull = $neTypeFull;
                chomp($FH_neTypeFull);
                my $nodeVersion =` echo $FH_neTypeFull | cut -d ' ' -f3 | sed 's/[A-Z]//g' | sed 's/-//g'`;
                if ( $nodeVersion > 2021 ) {
                    if ( $ip =~ /:/ ) {
                        print "INFO: IPV6 port=$fronthaulTLSHTTPSSNMPV3prot_Ipv6 while TLS=$securityStatusTLS\n";
                        &assignIpAddress( $fronthaulTLSHTTPSSNMPV3prot_Ipv6, $ip );
                        &setDD( $fronthaulTLSHTTPSSNMPV3prot_Ipv6 );
                    } else {
                        print "INFO: IPV4 port=$fronthaulTLSHTTPSSNMPV3prot while TLS=$securityStatusTLS \n";
                        &assignIpAddress( $fronthaulTLSHTTPSSNMPV3prot, $ip );
                        &setDD( $fronthaulTLSHTTPSSNMPV3prot );
                    }
                }
                else {
                if ( $ip =~ /:/ ) {
                        print "INFO: IPV6 port=$fronthaulHTTPSprot_Ipv6 while TLS=$securityStatusTLS\n";
                        &assignIpAddress( $fronthaulHTTPSprot_Ipv6, $ip );
                        &setDD( $fronthaulHTTPSprot_Ipv6 );
                    } else {
                        print "INFO: IPV4 port=$fronthaulHTTPSprot while TLS=$securityStatusTLS \n";
                        &assignIpAddress( $fronthaulHTTPSprot, $ip );
                        &setDD( $fronthaulHTTPSprot );
                    }
                }
            }
            elsif (  $ne=~ "FrontHaul-6080") {
                if ( $ip =~ /:/ ) {
                        print "INFO: IPV6 port=$fronthaulHTTPSprot_Ipv6  while TLS=$securityStatusTLS\n";
                        &assignIpAddress( $fronthaulHTTPSprot_Ipv6, $ip );
                        &setDD( $fronthaulHTTPSprot_Ipv6 );
                    } else {
                        print "INFO: IPV4 port=$fronthaulHTTPSprot while TLS=$securityStatusTLS \n";
                        &assignIpAddress( $fronthaulHTTPSprot, $ip );
                        &setDD( $fronthaulHTTPSprot );
                    }
                }




            #------------------------------------------------------------
            #Handling for IMS nodes
            #------------------------------------------------------------
            elsif (   $ne =~ "EME"
                || $ne =~ "WCG"
                || $ne =~ "vNSDS"
                || (( $ne =~ "HSS-FE" ) && ( $ne !~ "HSS-FE-TSP" ))
                ||( $ne =~ "UPG" && $simName =~ /^((?!TCU04).)*$/i )
                || $ne =~ "BSP"
                || $ne =~ "IPWORKS"
                || $ne =~ "MRFv"
                || $ne =~ "MRSv"
                || $ne =~ "DSC"
                || $neTypeFull =~ "WCDMA CCN"
	        || $ne =~ "AFG" ) {
                if ( $ip =~ /:/ ) {
                    print "INFO: IPV6 port=$netconfSSHPort_Ipv6 \n";
                    &assignIpAddress( $netconfSSHPort_Ipv6, $ip );
                    &setDD( $netconfSSHPort_Ipv6 );
                } else {
                    print "INFO: IPV6 port=$netconfSSHPort\n";
                    &assignIpAddress( $netconfSSHPort, $ip );
                    &setDD( $netconfSSHPort );
                }
            }
             elsif ( ( $ne =~ "vBNG" || ( $ne =~ "SSR" &&  $ne =~ /^((?!EPG-SSR).)*$/i ) || $ne =~ "Router" ) ) {
                if ( $ip =~ /:/ ) {
                    print "INFO: IPV6 port=lanSwitchPort_snmpv3_ipv6 \n";
                    &assignIpAddress( $lanSwitchPort_snmpv3_ipv6, $ip );
                    &setDD( $lanSwitchPort_snmpv3_ipv6 );
                } else {
                    print "INFO: IPV4 port=$lanSwitchPort_snmpv3\n";
                    &assignIpAddress( $lanSwitchPort_snmpv3, $ip );
                    &setDD( $lanSwitchPort_snmpv3 );
                }
            }
	     elsif ( ( $neTypeFull =~ "SBG" ) ) {
                if ( $ip =~ /:/ ) {
                    print "INFO: IPV6 port=$netconf_prot_ipv6_port \n";
                    &assignIpAddress( $netconf_prot_ipv6_port, $ip );
                    &setDD($netconf_prot_ipv6_port );
                } else {
                    print "INFO: IPV4 port=$netconfPort\n";
                    &assignIpAddress( $netconfPort, $ip );
                    &setDD( $netconfPort );
                }
            }
             elsif ( ( "$NeType[$countNe]" =~ "CCD"  && "$NeType[$countNe]" != "CCDM" ) ) {
                if ( $ip =~ /:/ ) {
                    print "INFO: IPV6 port=$HTTPHTTPSPort_ipv6\n";
                    &assignIpAddress( $HTTPHTTPSPort_ipv6, $ip );
                    &setDD($HTTPHTTPSPort_ipv6 );
                } else {
                    print "INFO: IPV4 port=$HTTPHTTPSPort\n";
                    &assignIpAddress( $HTTPHTTPSPort, $ip );
                    &setDD( $HTTPHTTPSPort );
                }
            }
	     	 #    elsif ( ( $neTypeFull =~ "O1.*"  ) ) {
       
                   # print "INFO: IPV4 port=$o1_Port\n";
                    # &assignIpAddress( $o1_Port, $ip );
                    # &setDD( $o1_Port);
                #}
            

	    elsif ( ( $neTypeFull =~ "CSCF.*CORE" ) ) {
                if ( $ip =~ /:/ ) {
                    print "INFO: IPV6 port=$netconf_prot_ipv6_port \n";
                    &assignIpAddress( $netconf_prot_ipv6_port, $ip );
                    &setDD($netconf_prot_ipv6_port );
                } else {
                    print "INFO: IPV4 port=$netconfPort\n";
                    &assignIpAddress( $netconfPort, $ip );
                    &setDD( $netconfPort );
                }
            }

             elsif ($ne =~ m/ECI/i ) {
                    print "INFO: IPV4 port=$snmpPort\n";
                    &assignIpAddress( $snmpPort, $ip );
                    &setDD( $snmpPort );
            }
            elsif ($ne =~ m/ECAS/i || $ne =~ m/DSE/i ) {
                    print "INFO: IPV4 port=$snmpPort\n";
                    &assignIpAddress( $snmpPort, $ip );
                    &setDD( $snmpPort );
            }
            elsif ($neTypeFull =~ m/EPG-OI 3-4-DY-V1/i || $neTypeFull =~ m/EPG-OI 3-4-DY-V2/i || $simName =~ m/CORE119/i || $simName =~ m/CORE128/i || $neTypeFull =~ m/EPG-OI 3-5-DY-V1/i || $neTypeFull =~ m/EPG-OI 3-5-DY-V3/i || $neTypeFull =~ m/EPG-OI 3-5-DY-V2/i || $neTypeFull =~ m/vEPG-OI 3-13-V1/i || $neTypeFull =~ m/GenericADP 1-0-V1/i || $simName =~ m/5G133/i || $neTypeFull =~ m/EPG-OI 3-4-DY-V3/i || $neTypeFull =~ m/EPG-OI 3-5-DY-V4/i || $neTypeFull =~ m/vEPG-OI 3-5-DY-V2/i || $neTypeFull =~ m/vEPG-OI 3-4-DY-V1/i || $simName =~ m/CORE135/i || $simName =~ m/CORE126/i ) {
                   if ( $ip =~ /:/ ) {
                       print "INFO: IPV6 port=$yangsnmpSSHEPGPort_Ipv6 \n";
                       &assignIpAddress( $yangsnmpSSHEPGPort_Ipv6, $ip );
                       &setDD($yangsnmpSSHEPGPort_Ipv6 );
                   } else {
                       print "INFO: IPV4 port=$yangsnmpSSHEPGPort\n";
                       &assignIpAddress( $yangsnmpSSHEPGPort, $ip );
                       &setDD( $yangsnmpSSHEPGPort );
                   }
             }
             elsif ($ne =~ m/EPG-OI/i ) {
                    print "INFO: IPV4 port=$netconfEPGPort\n";
                    &assignIpAddress( $netconfEPGPort, $ip );
                    &setDD( $netconfEPGPort );
            }
             elsif ( $ne =~ m/NRF/i || $ne =~ m/NSSF/i || $ne =~ m/UDR/i || $ne =~ m/AUSF/i) {
                    print "INFO: IPV4 port=$netconfSSHPort\n";
                    &assignIpAddress( $netconfSSHPort, $ip );
                    &setDD( $netconfSSHPort );
            }

            #------------------------------------------------------------
            #Handling for RV nodes
            #------------------------------------------------------------

             elsif ( ( $ne =~ "R6673" || $ne =~ "R6675" || $ne=~ "R6672" || $ne=~ "R6371" || $ne=~ "R6471-1" || $ne=~ "R6471-2" || $ne=~ "R6274" || $ne=~ "R6273" || $ne=~ "R6676" || $ne=~ "R6678" || $ne=~ "R6671" ) ) {
                if ( $ip =~ /:/ ) {
                    print "INFO: IPV6 port=$netconfTLSPort_Ipv6\n";
                    &assignIpAddress( $netconfTLSsnmpv3_Port_Ipv6, $ip );
                    &setDD( $netconfTLSsnmpv3_Port_Ipv6 );
                } else {
                    print "INFO: IPV4 port=$netconfTLSPort\n";
                    &assignIpAddress( $netconfTLSsnmpv3_Port, $ip );
                    &setDD( $netconfTLSsnmpv3_Port );
                }
            }
            elsif ( ( $neTypeFull =~ "vDU 1-0-DY-V1" || $neTypeFull =~ "vDU 1-0-DY-V2" || $neTypeFull =~ "vDU 0-7-4-DY-V1" || $neTypeFull =~ "vDU 0-10-1-DY-V1" || $neTypeFull =~ "vDU 0-11-1-DY-V1" || $neTypeFull =~ "vDU 0-12-3-DY-V1" || $neTypeFull =~ m/vCU-CP 1-0-V1/i || $neTypeFull =~ m/ vCU-UP 0-3-1-V1/i || $neTypeFull =~ m/vCU-CP 0-1-6-V1/i || $neTypeFull =~ m/vCU-UP 1-0-V1/i || $neTypeFull =~ m/vCU-CP 0-5-1-V1/i || $neTypeFull =~ m/vCU-UP 0-6-1-V1/i || $simName =~ m/5G130/i || $simName =~ m/5G131/i  || $simName =~ m/5G116/i || $simName =~ m/5G134/i ) ) {
                if ( $ip =~ /:/ ) {
                    print "INFO: IPV6 port=$yangsnmpTLSPort_Ipv6 \n";
                    &assignIpAddress( $yangsnmpTLSPort_Ipv6, $ip );
                    &setDD( $yangsnmpTLSPort_Ipv6 );
                } else {
                    print "INFO: IPV4 port=$yangsnmpTLSPort\n";
                    &assignIpAddress( $yangsnmpTLSPort, $ip );
                    &setDD( $yangsnmpTLSPort );
                }
            }
            elsif ( ( $neTypeFull =~ "PCG 1-0-V1" || $neTypeFull =~ "PCG 1-0-V2" ||  $simName =~ m/5G118/i || $neTypeFull =~ "PCC 1-9-V1" || $simName =~ m/5G132/i ) ) {
                if ( $ip =~ /:/ ) {
                     print "INFO: IPV6 port=$yangsnmpSSHPort_Ipv6 \n";
                     &assignIpAddress( $yangsnmpSSHPort_Ipv6, $ip );
                     &setDD( $yangsnmpSSHPort_Ipv6 );
                 } else {
                     print "INFO: IPV4 port=$yangsnmpSSHPort\n";
                     &assignIpAddress( $yangsnmpSSHPort, $ip );
                     &setDD( $yangsnmpSSHPort );
                  }
           }
        elsif ( ( $neTypeFull =~ "SMSF 1-0-V1" || $simName =~ m/5G129/i )) {
                if ( $ip =~ /:/ ) {
                     print "INFO: IPV6 port=$yangsnmpSSHSMSFPort_Ipv6 \n";
                     &assignIpAddress( $yangsnmpSSHSMSFPort_Ipv6, $ip );
                     &setDD( $yangsnmpSSHSMSFPort_Ipv6 );
                 } else {
                     print "INFO: IPV4 port=$yangsnmpSSHSMSFPort\n";
                     &assignIpAddress( $yangsnmpSSHSMSFPort, $ip );
                     &setDD( $yangsnmpSSHSMSFPort );
                  }

           }
           elsif ( ( $neTypeFull  =~ "LTE SCU" ) || ( $neTypeFull  =~ "LTE ESC" ) ) {
                        if ( $ip =~ /:/ ) {
                   print "INFO: IPV6 port=$netconfHTTPSTLSPort_Ipv6 \n";
                   &assignIpAddress( $netconfHTTPSTLSPort_Ipv6, $ip );
                   &setDD( $netconfHTTPSTLSPort_Ipv6 );
               } else {
                   print "INFO: IPV4 port=$netconfHTTPSTLSPort \n";  
                   &assignIpAddress( $netconfHTTPSTLSPort, $ip );
                   &setDD( $netconfHTTPSTLSPort );
               }
            }
	elsif ( ( $neTypeFull =~ "CCDM 1-0-V1" || $neTypeFull =~ "CCDM 1-3-1-V1" || $neTypeFull =~ "CCDM 1-3-1-RI-V1" || $neTypeFull =~ "CCDM 1-3-1-RI-V2" || $neTypeFull =~ "CCPC 1-0-V1" || $neTypeFull =~ "CCRC 1-0-V1" || $neTypeFull =~ "CCSM 1-0-V1" || $neTypeFull =~ "LTE SC 1-0-V1" || $neTypeFull =~ "CCES 1-0-V1" || $neTypeFull =~ "CCDM 1-0-V2" || $neTypeFull =~ "CCPC 1-0-V2" || $neTypeFull =~ "CCRC 1-0-V2" || $neTypeFull =~ "CCSM 1-0-V2" || $neTypeFull =~ "LTE SC 1-0-V2" || $neTypeFull =~ "CCES 1-0-V2" || $simName =~ m/5G112/i || $simName =~ m/5G113/i || $simName =~ m/5G114/i || $simName =~ m/5G115/i || $simName =~ m/5G117/i || $simName =~ m/5G127/i || $neTypeFull =~ "WMG-OI 2-3-V1" || $neTypeFull =~ "WMG-OI 2-3-V2" || $neTypeFull =~ "vWMG-OI 2-3-V1" || $neTypeFull =~ "vWMG-OI 2-3-V2" || $simName =~ m/CORE120/i || $simName =~ m/CORE125/i || $simName =~ m/CORE127/i || $simName =~ m/CORE129/i || $neTypeFull =~ "WMG-OI 2-5-V1" || $neTypeFull =~ "vWMG-OI 2-5-V1" || $neTypeFull =~ "vWMG-OI 2-6-V1" ) ) {
	if ( $ip =~ /:/ ) {
                     print "INFO: IPV6 port=$yangsnmpSSHWMGPort_Ipv6 \n";
                     &assignIpAddress( $yangsnmpSSHWMGPort_Ipv6, $ip );
                     &setDD( $yangsnmpSSHWMGPort_Ipv6 );
                 } else {
                     print "INFO: IPV4 port=$yangsnmpSSHWMGPort\n";
                     &assignIpAddress( $yangsnmpSSHWMGPort, $ip );
                     &setDD( $yangsnmpSSHWMGPort );
                  }
           }

                  elsif ( ( $ne =~ "EPG-EVR" ||  $ne =~ "EPG-SSR" || $ne =~ "PCC" || $ne =~ "PCG"  || $ne =~ "NeLS" || $ne =~ "SCEF" || $neTypeFull =~ "EIR" || $ne =~ "CCDM" || $ne =~ "CCPC" || $ne =~ "CCRC" || $ne =~ "CCSM" || ( $neTypeFull =~ "LTE SC" && $neTypeFull !~ "LTE SCU" ) || $ne =~ "EDA" || $ne =~ "CCES" || $ne =~ "vDU" || $ne =~ "CUDB" ) ) {
                if ( $ip =~ /:/ ) {
                    print "INFO: IPV6 port=$netconfSSHPort_Ipv6 \n";
                    &assignIpAddress( $netconfSSHPort_Ipv6, $ip );
                    &setDD( $netconfSSHPort_Ipv6 );
                } else {
                    print "INFO: IPV4 port=$netconfSSHPort\n";
                    &assignIpAddress( $netconfSSHPort, $ip );
                    &setDD( $netconfSSHPort );
                }
            }
            elsif ( $neTypeFull =~ m/MTAS.*CORE/i ) {
                if ( $ip =~ /:/ ) {
                     print "INFO: IPV6 port=$netconfSSHMTASPort_Ipv6 \n";
                     &assignIpAddress( $netconfSSHMTASPort_Ipv6, $ip );
                     &setDD( $netconfSSHMTASPort_Ipv6 );
                } else {
                     print "INFO: IPV4 port=$netconfSSHMTASPort\n";
                     &assignIpAddress( $netconfSSHMTASPort, $ip );
                     &setDD( $netconfSSHMTASPort );
                }
            }
            elsif ($ne =~"MTAS" ) {
                if ( $ip =~ /:/ ) {
                    print "INFO: IPV6 port=$tspSSHPort_Ipv6 \n";
                    &assignIpAddress( $tspSSHPort_Ipv6, $ip );
                    &setDD( $tspSSHPort_Ipv6 );
                } else {
                    print "INFO: IPV4 port=$tspSSHPort\n";
                    &assignIpAddress( $tspSSHPort, $ip );
                    &setDD( $tspSSHPort );
                }
            }
            elsif ( ( $ne =~ "MLTN" ) ) {
                if ( $ip =~ /:/ ) {
                    print "INFO: IPV6 port=$snmpTelnetPort_ipv6\n";
                    &assignIpAddress( $snmpTelnetPort_ipv6, $ip );
                    &setDD( $snmpTelnetPort_ipv6 );
                } else {
                    print "INFO: IPV4 port=$snmpTelnetPort\n";
                    &assignIpAddress( $snmpTelnetPort, $ip );
                    &setDD( $snmpTelnetPort );
                }
            }
            elsif ( ( $neTypeFull =~ "ML 6366" || $neTypeFull =~ "ML 6651" || $neTypeFull =~ "ML 6371" || $neTypeFull =~ "ML 6654" || $neTypeFull =~ "ML 6200" || $neTypeFull =~ "ML 6691" || $neTypeFull =~ "HSM" )) {
                if ( $ip =~ /:/ ) {
                    print "INFO: IPV6 port=$snmpTelnetPort_ipv6\n";
                    &assignIpAddress( $snmpTelnetPort_ipv6, $ip );
                    &setDD( $snmpTelnetPort_ipv6 );
                } else {
                    print "INFO: IPV4 port=$snmpTelnetPort\n";
                    &assignIpAddress( $snmpTelnetPort, $ip );
                    &setDD( $snmpTelnetPort );
                }
            }
            elsif ( (  $neTypeFull =~ "BB IC 8855" )) {
                if ( $ip =~ /:/ ) {
                    print "INFO: IPV6 port=$snmpTelnetIc8855Port_ipv6\n";
                    &assignIpAddress( $snmpTelnetIc8855Port_ipv6, $ip );
                    &setDD( $snmpTelnetIc8855Port_ipv6 );
                } else {
                    print "INFO: IPV4 port=$snmpTelnetIc8855Port\n";
                    &assignIpAddress( $snmpTelnetIc8855Port, $ip );
                    &setDD( $snmpTelnetIc8855Port );
                }
            }
            elsif ( ( lc($ne) =~ "mgw" ) ) {
                if ( $ip =~ /:/ ) {
                    print "INFO: IPV6 port=$iiopPort_ipv6\n";
                    &assignIpAddress( $iiopPort_ipv6, $ip );
                    &setDD( $iiopPort_ipv6 );
                } else {
                    print "INFO: IPV4 port=$iiopPort\n";
                    &assignIpAddress( $iiopPort, $ip );
                    &setDD( $iiopPort );
                }
            }
            elsif ( ( $ne =~ "SpitFire" ) ) {
                         if ( $ip =~ /:/ ) {
                    print "INFO: IPV6 port=$netconfTLSPort_Ipv6\n";
                    &assignIpAddress( $netconfTLSPort_Ipv6, $ip );
                    &setDD( $netconfTLSPort_Ipv6 );
                } else {
                    print "INFO: IPV4 port=$netconfTLSPort\n";
                    &assignIpAddress( $netconfTLSPort, $ip );
                    &setDD( $netconfTLSPort );
                }
            }
            
           elsif ( ( $neTypeFull  =~ "ESC" || $ne =~ "SCU" || $ne =~ "ERS" ) ) {
                          if ( $ip =~ /:/ ) {
                    print "INFO: IPV6 port=$lanSwitchPort_snmpv3_ipv6 \n";
                    &assignIpAddress( $lanSwitchPort_snmpv3_ipv6, $ip );
                    &setDD( $lanSwitchPort_snmpv3_ipv6 );
                } else {
                    print "INFO: IPV4 port=$lanSwitchPort_snmpv3 \n";
                    &assignIpAddress( $lanSwitchPort_snmpv3 , $ip );
                    &setDD( $lanSwitchPort_snmpv3  );
                }
            }
         

         elsif ( ( $ne =~ "STN" ) ) {
                if ( $ip =~ /:/ ) {
                    print "INFO: IPV6 port=$stnPort_ipv6 \n";
                    &assignIpAddress( $stnPort_ipv6, $ip );
                    &setDD( $stnPort_ipv6 );
                } else {
                    print "INFO: IPV4 port=$stnPort\n";
                    &assignIpAddress( $stnPort, $ip );
                    &setDD( $stnPort );
                }
            }
            elsif ((  $neTypeFull=~ "ML 6352")) {
               if ( $ip =~ /:/ ) {
                       print "ML 6352 PortIPv6\n";
                       print "INFO: IPV6 port $ml6352_port_snmpv3_ipv6_port while TLS=$securityStatusTLS\n";
                       &assignIpAddress( $ml6352_port_snmpv3_ipv6_port, $ip );
                       &setDD( $ml6352_port_snmpv3_ipv6_port );
                   } else {
                       print "ML 6352 PortIPv4\n";
                       print "INFO: IPV4 port=$ml6352_port_snmpv3 while TLS=$securityStatusTLS \n";
                       &assignIpAddress( $ml6352_port_snmpv3, $ip );
                       &setDD( $ml6352_port_snmpv3 );
                   }
               }
              elsif (( $neTypeFull=~ "LANSWITCH.*" || $neTypeFull=~ "JUNIPER PTX" || $neTypeFull=~ "JUNIPER SRX" || $neTypeFull=~ "JUNIPER VSRX" || $neTypeFull=~ "JUNIPER VMX")) {
                 if ( $ip =~ /:/ ) {
                       print "INFO: IPV6 port $snmpsshtelnet_prot_Ipv6 while TLS=$securityStatusTLS\n";
                       &assignIpAddress( $snmpsshtelnet_prot_Ipv6, $ip );
                       &setDD( $snmpsshtelnet_prot_Ipv6 );
                   } else {
                       print "LANSWITCH_SNMP_SSH_PORT\n";
                       print "INFO: IPV4 port=$snmpsshtelnet_prot while TLS=$securityStatusTLS \n";
                       &assignIpAddress( $snmpsshtelnet_prot, $ip );
                       &setDD( $snmpsshtelnet_prot );
                   }
               }
	       elsif (( $neTypeFull=~ "JUNIPER MX")) {
                 if ( $ip =~ /:/ ) {
                       print "INFO: IPV6 port $snmpsshtelnet_Port_Ipv6 while TLS=$securityStatusTLS\n";
                       &assignIpAddress( $snmpsshtelnet_Port_Ipv6, $ip );
                       &setDD( $snmpsshtelnet_Port_Ipv6 );
                   } else {
                       print "SNMP_SSH_TELNET_PORT\n";
                       print "INFO: IPV4 port=$snmpsshtelnet_Port while TLS=$securityStatusTLS \n";
                       &assignIpAddress( $snmpsshtelnet_Port, $ip );
                       &setDD( $snmpsshtelnet_Port );
                   }
               }



            #--------------------------------------------------------------------------------------
            #Handling Compact MSC-S-DB
            #-------------------------------------------------------------------------------------
            elsif ( $ne =~ "MSC-S-DB" ) {
                &setDD( $apgPort );
                print MML ".selectnocallback $NeNames[$countNe]";
                print MML ".modifyne checkselected .set port $apgPort port\n";
                print MML ".set port $apgPort \n";
                $countIp++;
                chomp( $freeIps[$countIp] );
                print MML ".modifyne set_subaddr $freeIps[$countIp] subaddr subaddr_nodea|subaddr_nodeb\n";
                chomp( $freeIps[$countIp] );
                print MML ".set taggedaddr subaddr $freeIps[$countIp] 1\n";
                $countIp++;
                chomp( $freeIps[$countIp] );
                print MML ".set taggedaddr subaddr_nodea $freeIps[$countIp] 1\n";
                $countIp++;
                chomp( $freeIps[$countIp] );
                print MML ".set taggedaddr subaddr_nodeb $freeIps[$countIp] 1\n";
                $countIp++;
                print MML ".set save\n";
            }
            else {
                &assignIpAddress( $simPortName, $ip );
            }
            $countNe++;
        }

        #------------------------
        #=cut
    }
    if ( keys (%simNesIpTypeMap) > 0 ) {
        print "Saving $file_simNesIpTypeMap file\n";
        store \%simNesIpTypeMap, $file_simNesIpTypeMap || die "ERROR: Can not store $file_simNesIpTypeMap \n";
        my $simNesIpTypeMapRef = \%simNesIpTypeMap;
        print map { "$_ => $$simNesIpTypeMapRef{$_}\n" } keys %$simNesIpTypeMapRef;

    }
    else {
        if ( -e $file_simNesIpTypeMap ) {
            print "Deleteing: $file_simNesIpTypeMap file\n";
            `rm -v $file_simNesIpTypeMap`;
        } else {
            print "FILE=$file_simNesIpTypeMap DOES NOT exist \n";
        }
    }
}

#
#----------------------------------------------------------------------------------
#SubRoutine to assign  port with IP address
#---------------------------------------------------------------------------------

sub assignIpAddress {
    ( my $portName, my $presentIpAdress ) = @_;
    print MML ".modifyne checkselected .set port $portName port\n";
    print MML ".set port $portName\n";
    print MML ".modifyne set_subaddr $presentIpAdress subaddr no_value\n";
    print MML ".set taggedaddr subaddr $presentIpAdress 1\n";
    print MML ".set save\n";
}

#
#----------------------------------------------------------------------------------
#SubRoutine to assign Ports which does not requires IP Address
#---------------------------------------------------------------------------------

sub assignPortNoIp {
    ( my $portName ) = @_;
    print MML ".modifyne checkselected .set port $portName port\n";
    print MML ".set port $portName\n";
    print MML ".set save\n";
}

#
#----------------------------------------------------------------------------------
#SubRoutine to assign DD
#---------------------------------------------------------------------------------
sub assignDD {
    ( my $createDefaultDestinationName, my $indexFirst, my $indexLast ) = @_;
    open listNeName, "$PWD/../dat/dumpNeName.txt";
    @NeNames = <listNeName>;
    close(listNeName);
    open listNeType, "$PWD/../dat/dumpNeType.txt";
    my @NeType = <listNeType>;
    close(listNeType);
    while ( $indexFirst < $indexLast ) {
        chomp( $NeNames[$indexFirst] );
        my $var = $NeNames[$indexFirst];
        if (   "$NeType[$indexFirst]" =~ m/MSC-S-IS/i )
        {
            print MML ".selectnocallback $var\n";
            &setDD($netconfDDIs);
            $indexFirst++;
        }

        elsif ("$NeType[$indexFirst]" =~ m/MSC-S-CP/i
            || "$NeType[$indexFirst]" =~ m/MSC-S-SPX/i
            || "$NeType[$indexFirst]" =~ m/MSC-S-IPLB/i
            || "$NeType[$indexFirst]" =~ m/MSC-S-TSC/i
            || "$NeType[$indexFirst]" =~ m/HLR-BS-CP/i
            ||  "$NeType[$indexFirst]" =~ m/HLR-BS-TSC/i
            ||  "$NeType[$indexFirst]" =~ m/HLR-BS-SPX/i
            ||  "$NeType[$indexFirst]" =~ m/HLR-BS-IPLB/i)
        {
            # No need of default destination for the above nodes.
            $indexFirst++;
        }
        elsif ( "$NeNames[$indexFirst]" =~ m/$timeServer/i ) {
            $indexFirst++;
        }
        elsif ( "$NeType[$indexFirst]" =~ m/LANSWITCH/i ) {
            print MML ".selectnocallback $var\n";
            $indexFirst++;
        }

        elsif ( "$NeType[$indexFirst]" =~ m/BSC.*APG43L/i
            || "$NeType[$indexFirst]" =~ m/MSC.*APG43L/i ) {
            #print MML ".selectnocallback $var\n";
            #&setDD("APG43L_APGTCP");
            $indexFirst++;
        }
        elsif ( "$NeType[$indexFirst]" =~ m/ECM/i ) {
            $indexFirst++;
        }
       elsif ( "$NeType[$indexFirst]" =~ m/LTE.*BSC/i ) {
            #print MML ".selectnocallback $var\n";
            #&setDD("$agptcp_netconf_http_https_tls_prot");
            $indexFirst++;
        }
        elsif ( "$NeType[$indexFirst]" =~ m/MSC-BC-IS/i ) {
            #print MML ".selectnocallback $var\n";
            #&setDD($msc_bc_is_tls_prot);
            $indexFirst++;
}
       elsif ( "$NeType[$indexFirst]" =~ m/LTE.*MSC/i ) {
            #print MML ".selectnocallback $var\n";
            #&setDD($agptcp_netconf_http_https_tls_prot);
            $indexFirst++;
}
       elsif ( "$NeType[$indexFirst]" =~ m/HLR-FE/i || "$NeType[$indexFirst]" =~ m/vHLR-BS/i ) {
            print MML ".selectnocallback $var\n";
            &setDD($agptcp_netconf_http_https_tls_prot);
            $indexFirst++;
        }


         elsif ( "$NeType[$indexFirst]" =~ /MSC-S-DB/i ) {
            $indexFirst++;
        }
        elsif ( "$NeType[$indexFirst]" =~ /MSRBS-V2/i || "$NeType[$indexFirst]" =~ /RAN-VNFM/i || "$NeType[$indexFirst]" =~ /EVNFM/i || "$NeType[$indexFirst]" =~ /VNF-LCM/i || "$NeType[$indexFirst]" =~ /CONTROLLER6610/i || "$NeType[$indexFirst]" =~ /LTE SCU/i || "$NeType[$indexFirst]" =~ /SCEF/i ) {
            $indexFirst++;
        }
         elsif ( ( "$NeType[$indexFirst]" =~ /vBNG/i || ( "$NeType[$indexFirst]" =~ /SSR/i && "$NeType[$indexFirst]" =~ /^((?!EPG-SSR).)*$/i ) || "$NeType[$indexFirst]" =~ /Router 8801/i ) ) {
            $indexFirst++;
            next;
        }
        elsif ( "$NeType[$indexFirst]" =~ /vPP/i
               || "$NeType[$indexFirst]" =~ /vRC/i
               || "$NeType[$indexFirst]" =~ /RNNODE/i
               || "$NeType[$indexFirst]" =~ /vSD/i
               || "$NeType[$indexFirst]" =~ /5GRadioNode/i
               || "$NeType[$indexFirst]" =~ /VTIF/i
               || "$NeType[$indexFirst]" =~ /VTFRadioNode/i ) {
            $indexFirst++;
        }
        elsif (   "$NeType[$indexFirst]" =~ /PRBS/i
               || (( "$NeType[$indexFirst]" =~ /HSS-FE/i ) && ( "$NeType[$indexFirst]" !~ /HSS-FE-TSP/i ))
               || "$NeType[$indexFirst]" =~ /EME/i
               || "$NeType[$indexFirst]" =~ /WCG/i
               || "$NeType[$indexFirst]" =~ /vNSDS/i
               ||( "$NeType[$indexFirst]" =~ /UPG/i && $simName =~ /^((?!TCU04).)*$/i )
               || "$NeType[$indexFirst]" =~ /MRFv/i
               || "$NeType[$indexFirst]" =~ /MRSv/i
               || "$NeType[$indexFirst]" =~ /BSP/i
               || "$NeType[$indexFirst]" =~ /IPWORKS/i
               || "$NeType[$indexFirst]" =~ /DSC/i
               || "$NeType[$indexFirst]" =~ /WCDMA CCN/i
	       || "$NeType[$indexFirst]" =~ /AFG/i
               || "$NeType[$indexFirst]" =~ m/SBG/i
               || "$NeType[$indexFirst]" =~ m/CCD/i ) {
            $indexFirst++;
            next;
        }
        elsif (  "$NeType[$indexFirst]" =~ /R6675/i
              || "$NeType[$indexFirst]" =~ /R6672/i
              || "$NeType[$indexFirst]" =~ /R6371/i
              || "$NeType[$indexFirst]" =~ /R6471-1/i
              || "$NeType[$indexFirst]" =~ /R6471-2/i
              || "$NeType[$indexFirst]" =~ /R6274/i
              || "$NeType[$indexFirst]" =~ /R6273/i
              || "$NeType[$indexFirst]" =~ /R6673/i
              || "$NeType[$indexFirst]" =~ /R6676/i
              || "$NeType[$indexFirst]" =~ /R6678/i
              || "$NeType[$indexFirst]" =~ /R6671/i
              || "$NeType[$indexFirst]" =~ /ML-FRONTHAUL 6392/i
              || "$NeType[$indexFirst]" =~ /FRONTHAUL-6020/i
              || "$NeType[$indexFirst]" =~ /FRONTHAUL-6650/i
              || "$NeType[$indexFirst]" =~ /FRONTHAUL-6080/i  
              || "$NeType[$indexFirst]" =~ /FRONTHAUL-6000/i ) {
            $indexFirst++;
            next;
        }
        elsif ( "$NeType[$indexFirst]" =~ /MTAS/i || "$NeType[$indexFirst]" =~ /EPG-EVR/i || "$NeType[$indexFirst]" =~ /EPG-SSR/i || "NeType[$indexFirst]" =~ /PCC/i || "$NeType[$indexFirst]" =~ /PCG/i || "$NeType[$indexFirst]" =~ /CCDM/i || "$NeType[$indexFirst]" =~ /CCPC/i || "$NeType[$indexFirst]" =~ /CCRC/i || "$NeType[$indexFirst]" =~ /LTE SC/i || "$NeType[$indexFirst]" =~ /EDA/i || "$NeType[$indexFirst]" =~ /CCSM/i || "$NeType[$indexFirst]" =~ /CCES/i || "$NeType[$indexFirst]" =~ /vDU/i ) {
            $indexFirst++;
            next;
        }
        elsif ( "$NeType[$indexFirst]" =~ /STN/i ) {
            $indexFirst++;
            next;
        }
        elsif ( "lc($NeType[$indexFirst])" =~ /mgw/i ) {
            $indexFirst++;
            next;
        }
        elsif ( "$NeType[$indexFirst]" =~ /MLTN/i || "$NeType[$indexFirst]" =~ /VMX/i || "$NeType[$indexFirst]" =~ /JUNIPER PTX/i || "$NeType[$indexFirst]" =~ /JUNIPER SRX/i || "$NeType[$indexFirst]" =~ /JUNIPER VSRX/i || "$NeType[$indexFirst]" =~ /BB IC 8855/i ) {
            $indexFirst++;
            next;
        }
        elsif ( "$NeType[$indexFirst]" =~ /SpitFire/i || "$NeType[$indexFirst]" =~ /ML 6352/i || "$NeType[$indexFirst]" =~ /ML 6651/i || "$NeType[$indexFirst]" =~ /ML 6371/i || "$NeType[$indexFirst]" =~ /ML 6654/i ||"$NeType[$indexFirst]" =~ /ML 6366/i || "$NeType[$indexFirst]" =~ /ML 6200/i || "$NeType[$indexFirst]" =~ /ML 6691/i || "$NeType[$indexFirst]" =~ /HSM/i) {
            $indexFirst++;
            next;
        }
        elsif ( "$NeType[$indexFirst]" =~ /IS IS/i ) {
            $indexFirst++;
            next;
         }
         elsif ( "$NeType[$indexFirst]" =~ /OpenMano/i || "$NeType[$indexFirst]" =~ /RNFVO/i || "$NeType[$indexFirst]" =~ /HP-NFVO/i || "$NeType[$indexFirst]" =~ /EPG-OI/i ) {
            $indexFirst++;
            next;
        }
        elsif ( "$createDefaultDestinationName" =~ /YANG_SNMP_TLS_PROT/i ) {
            $indexFirst++;
            next;
        }
        elsif ( "$NeType[$indexFirst]" =~ /CSCF.*CORE/i ) {
            $indexFirst++;
            next;
         }
	 elsif ( "$NeType[$indexFirst]" =~ /HDS/i || "$NeType[$indexFirst]" =~ /CUDB/i || "$NeType[$indexFirst]" =~ /SDI/i ) {
            $indexFirst++;
            next;
         }
          elsif ( "$NeType[$indexFirst]" =~ /JUNIPER MX/i ) {
            $indexFirst++;
            next;
         }
elsif( "$NeType[$indexFirst]" =~ m/O1/i || "$createDefaultDestinationName" =~ m/YANG_PROT/i ) {
          $indexFirst++;
           next;
}
elsif( "$NeType[$indexFirst]" =~ m/LTE oRU/i || "$createDefaultDestinationName" =~ m/YANG_PROT/i ) {
          $indexFirst++;
           next;
}
elsif( "$NeType[$indexFirst]" =~ m/vDU 5-93-0-V1/i ) {
          $indexFirst++;
           next;
}

        else {
            if (
                "$NeType[$indexFirst]" =~ m/$stnName/i

                || "$NeType[$indexFirst]" =~ /$stnTCUName/i
                || "$NeNames[$indexFirst]" =~ /$stnPICOName/i
              )
            {
                $createDefaultDestinationName = "SNMP_SSH_PROT";
            }
            print MML ".selectnocallback $var\n";
            &setDD($createDefaultDestinationName);
            $indexFirst++;
        }
    }
}

sub setDD {
    ( my $DDName ) = @_;
    print MML ".modifyne checkselected external $DDName default destination\n";
    print MML ".set external  $DDName\n";
    print MML ".set save\n";
}

#----------------------------------------------------------------------------------
#Define NETSim MO file and Open file in append mode
#----------------------------------------------------------------------------------
my $MML_MML = "MML.mml";
open MML, "+>>$MML_MML";

#
#-----------------------------------------------------------------------------------
#Assign IPs
#-----------------------------------------------------------------------------------
print MML ".open $simName\n";

#
#----------------------------------------------------------------------------------
#MAIN - assign IPs
#----------------------------------------------------------------------------------
my $indexStart = 0;
my $indexStop  = $numOfNe;
if ( $createPort =~ /SGSN$/ ) {
    if ( $simName =~ m/SGSN-SPP/i ) {
        $indexStop   = $numOfNe;
        $simPortName = "$simPortName" . "-GSN";
        &assignIP( $indexStart, $indexStop, $simPortName );
        &assignDD( $createDefaultDestinationName, $indexStart, $indexStop );
    }
    else {
        #$indexStop = ( $numOfNe / 2 );
        &assignIP( $indexStart, $indexStop, $simPortName );
        #$indexStart  = "$indexStop";
        #$indexStop   = $numOfNe;
        #$simPortName = "$simPortName" . "-GSN";
        #&assignIP( $indexStart, $indexStop, $simPortName );
        #&assignDD( $createDefaultDestinationName, $indexStart, $indexStop );
    }
}
else {
    &assignIP( $indexStart, $indexStop, $simPortName );
}
if (   $createPort =~ /NETCONF_PROT$/
    || $createPort =~ /NETCONF_PROT_TLS$/
    || $createPort =~ /NETCONF_PROT_SSH$/
    || $createPort =~ /NETCONF_PROT_SSH_MME$/
    || $createPort =~ /NETCONF_PROT_SSH_FRONTHAUL6020/
    || $createPort =~ /NETCONF_PROT_SSH_FRONTHAUL6080/
    || $createPort =~ /NETCONF_PROT_SSH_MME_ECIM/
    || $createPort =~ /NETCONF_PROT_SSH_SPITFIRE/
    || $createPort =~ /SGSN_PROT/
    || $createPort =~ /SNMP/
    || $createPort =~ /SNMP_TELNET_PROT/
    || $createPort =~ /SNMP_TELNET_SECURE_PROT/
    || $createPort =~ /SNMP_SSH_TELNET_PROT/
    || $createPort =~ /APG/ 
    || $createPort =~ /STN_PROT/
    || $createPort =~ /TSP_PROT/
    || $createPort =~ /TSP_SSH_PROT/
    || $createPort =~ /HTTP_HTTPS_PORT/
    || $createPort =~ /SNMP_SSH_PROT/
    || $createPort =~ /NETCONF_PROT_SSH_DG2$/
    || $createPort =~ /NETCONF_HTTP_HTTPS_TLS_PORT$/
    || $createPort =~ /ML6352_PORT$/
    || $createPort =~ /ML6352_PORT_SNMPV2$/
    || $createPort =~ /MLPT_PORT$/
    || $createPort =~ /LANSWITCH_PROT_SNMPV3$/
    || $createPort =~ /NETCONF_HTTP_HTTPS_SSH_PORT$/
    || $createPort =~ /NETCONF_HTTP_HTTPS_SSH_FRONTHAUL_PORT/)
{
    &assignDD( $createDefaultDestinationName, $indexStart, $indexStop );
}

system("$NETSIM_INSTALL_SHELL < $MML_MML");
if ($? != 0)
{
    print "ERROR: Failed to execute system command ($NETSIM_INSTALL_SHELL < $MML_MML)\n";
    exit(207);
}
close MML;
system("rm $MML_MML");
if ($? != 0)
{
    print "INFO: Failed to execute system command (rm $MML_MML)\n";
}


