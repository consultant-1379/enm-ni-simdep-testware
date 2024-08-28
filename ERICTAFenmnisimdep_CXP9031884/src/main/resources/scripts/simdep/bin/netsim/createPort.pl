#!/usr/bin/perl -w
###################################################################################
#
#     File Name : createPort.pl
#
#     Version : 5.00
#
#     Author : Jigar Shah
#
#     Description : The script creates the following Ports
#
#     Date Created : 27 January 2014
#
#     Syntax : ./createPort.pl <IP Address> <DefaultDestination>
#
#     Parameters : <IP Address> The Base IP which would be assigned to the nodes
#                  <Port Name> The ports supported are CPP, SGSN
#                  <ossMaster>
#
#     Example :  ./createPort.pl 10.10.10.0 CPP 159.75.62.1
#
#     Dependencies : 1.
#
#     NOTE: Please add the supported nodes, when support is available.
#
#     Return Values : N/A
#
###################################################################################
#
#----------------------------------------------------------------------------------
#Variables
#----------------------------------------------------------------------------------
my $NETSIM_INSTALL_SHELL   = "/netsim/inst/netsim_pipe";
my $lineAddPort            = undef;
my $lineConfigPort         = undef;
my $flagDefaultDestination = undef;
my $hostName               = `hostname`;
chomp($hostName);

#
#----------------------------------------------------------------------------------
#Check if the scrip is executed as netsim user
#----------------------------------------------------------------------------------
#
$user = `whoami`;
chomp($user);
$netsim = 'netsim';
if ( $user ne $netsim ) {
    print "ERROR: Not netsim user. Please execute the script as netsim user\n";
    exit(201);
}

#
#----------------------------------------------------------------------------------
#Check if the script usage is right
#----------------------------------------------------------------------------------
$USAGE = "Usage: $0 <DefaultDestination> <docker>\n  E.g. $0 192.168.100.5 no\n";
if ( @ARGV != 2 ) {
    print "ERROR: $USAGE";
    exit(202);
}
print "RUNNING: $0 @ARGV \n";

#
#----------------------------------------------------------------------------------
#Environment Variable
#---------------------------------------------------------------------------------
# real ip addr removed from params due to no need real IP addr for port creation
my $createDefaultDestination = "$ARGV[0]";
my $docker                   = "$ARGV[1]";
my $flagSgsn                 = 0;
my $dummyPortAddrIpv4        = "192.168.0.1";
my $dummyPortAddrIpv6        = "2001:1b70:82a1:103::64:1";

# for now added here but must be moved to config file
my $createDefaultDestinationIpv6 = "2001:1b70:82a1:0103::12";
if ( $docker =~ m/yes/i )
{
$hostName = "netsim";
}
chomp($hostName);
#
#----------------------------------------------------------------------------------
#Map the Port and create Port
#----------------------------------------------------------------------------------
sub buildPort {
    ( my $lineAddPort, my $lineConfigPort, my $portName ) = @_;
    print "Create Port for $portName \n";
    print MML ".select configuration\n";
    print MML "$lineAddPort\n";
    print MML "$lineConfigPort\n";
    print MML ".config save\n";
}

sub buildDD {
    (
        my $lineAddPortDd,
        my $lineConfigPortDd,
        my $createDefaultDestinationName,
        my $hostName
    ) = @_;
    print MML ".select configuration\n";

    print MML "$lineAddPortDd\n";
    print MML
      ".config external servers $createDefaultDestinationName $hostName\n";

    print MML "$lineConfigPortDd\n";
    print MML ".config save\n";
}

#----------------------------------------------------------------------------------
#Subroutine to create ports
#----------------------------------------------------------------------------------
sub createPorts {
    ( my $createPort ) = @_;
    $_ = $createPort;
    my $portName = "$createPort";

    if ( $_ =~ m/SGSN$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netsimwpp $hostName";
        $lineConfigPort =
          ".config port address $portName $dummyPortAddrIpv4 4001";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $portName    = "$createPort-GSN";
        $lineAddPort = ".config add port $portName snmp_ssh_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 1161 public 2 %unique %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName snmp_ssh_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestination 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( $_ =~ m/IIOP_PROT/ ) {
        $lineAddPort = ".config add port $portName iiop_prot $hostName";
        $lineConfigPort =
".config port address $portName nehttpd $dummyPortAddrIpv4 56834 56836 no_value";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );

    }
    elsif ( $_ =~ m/NETCONF_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 1161 public 2 %unique 1 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestination 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( $_ =~ m/NETCONF_PROT_IS$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 161 public 1 %unique 1 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
           ".config add external $createDefaultDestinationName netconf_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestination 10163 2";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( $_ =~ m/NETCONF_PROT_IS_TLS$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 161 public 1 %unique 2 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
           ".config add external $createDefaultDestinationName netconf_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestination 10163 2";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( $_ =~ m/NETCONF_PROT_TLS$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 161 public 3|2|1 %unique 2 mediation authpass privpass 1 1";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( $_ =~ m/NETCONF_PROT_TLS_SNMPV3$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4  161 public 3|2|1 %unique 2 AuthPrivMD5DES ericsson ericsson 2 2 ";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( $_ =~ m/NETCONF_PROT_SSH$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 1161 public 2 %unique 3 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $hostName 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( $_ =~ m/YANG_SNMP_SSH_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName yang_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 1161 public 2 %unique 3 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
".config add external $createDefaultDestinationName yang_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $hostName 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
    elsif ( $_ =~ m/YANG_SNMP_TLS_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName yang_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 1161 public 1|2|3 %unique 2 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
".config add external $createDefaultDestinationName yang_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $hostName 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
    elsif ( $_ =~ m/NETCONF_PROT_SSH_MTAS$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 161 public 2 %unique 3 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
".config add external $createDefaultDestinationName netconf_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $hostName 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
     elsif ( $_ =~ m/NETCONF_PROT_SSH_FRONTHAUL6020$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 161 public 2 %unique 3 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $hostName 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( $_ =~ m/NETCONF_PROT_SSH_FRONTHAUL6080$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 161 public 2 %unique 3 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $hostName 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( $_ =~ m/NETCONF_PROT_SSH_DG2$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 161 public 3|2|1 %unique 3 mediation authpass privpass 1 1";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_prot";
       $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( $_ =~ m/NETCONF_PROT_EPG$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 1161 public 3 %unique 3 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( $_ =~ m/YANG_SNMP_SSH_EPG_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName yang_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 1161 public 1|2|3 %unique 3 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName yang_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
elsif ( $_ =~ m/YANG_SNMP_SSH_WMG_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName yang_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 1161 public 3|2|1 %unique 3 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName yang_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }    

elsif ( $_ =~ m/YANG_SNMP_SSH_SMSF_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName yang_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 1161 public 3|2|1 %unique 3 %simname_%nename authpass privpass 2 2 authPrivSHA1DES ericsson ericsson 3 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName yang_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }  

    elsif ( $_ =~ m/NETCONF_PROT_SSH_SPITFIRE$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 161 public 3|2|1 %unique 3 ericsson authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( $_ =~ m/NETCONF_PROT_SSH_MME$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 161 public 3|2|1 %unique 3 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
     elsif ( $_ =~ m/NETCONF_PROT_SSH_MME_ECIM$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 25161 public 3|2|1 %unique 3 %nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( $_ =~ m/SGSN_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName sgsn_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 1161 public 2 %unique 4001 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName sgsn_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestination 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( $_ =~ m/SNMP_SSH_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName snmp_ssh_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 161 public 1|2 %unique %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName snmp_ssh_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestination 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( $_ =~ m/SNMP$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName snmp $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 1161 public 1|2 %unique %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName snmp";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestination 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( $_ =~ m/SNMP_TELNET_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName snmp_telnet_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 161 public,private,trap 1|2|3 %unique no_value authPrivSHA1DES ericsson ericsson 3 2 admin_user ericsson no_value 2 1 authPrivMD5DES ericsson ericsson 2 2 oper_user ericsson ericsson 2 1 view_user ericsson ericsson 2 1 control_user ericsson ericsson 2 1 authNoPrivMD5None ericsson no_value 2 1 authNoPrivSHA1None ericsson ericsson 3 1 noAuthNoPriv ericsson ericsson 1 1";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName snmp_telnet_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
  elsif ( $_ =~ m/SNMP_TELNET_IC8855_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName snmp_telnet_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 161 public,private,trap 1|2|3 %unique 1 authPrivSHA1DES ericsson ericsson 3 2 admin_user ericsson no_value 2 1 authPrivMD5DES ericsson ericsson 2 2 oper_user ericsson ericsson 2 1 view_user ericsson ericsson 2 1 control_user ericsson ericsson 2 1 authNoPrivMD5None ericsson no_value 2 1 authNoPrivSHA1None ericsson ericsson 3 1 noAuthNoPriv ericsson ericsson 1 1";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName snmp_telnet_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }

elsif ( $_ =~ m/SNMP_TELNET_SECURE_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName snmp_telnet_https_http_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 161 public,private,trap 1|2|3 %unique no_value authPrivSHA1DES ericsson ericsson 3 2 admin_user ericsson no_value 2 1 authPrivMD5DES ericsson ericsson 2 2 oper_user ericsson ericsson 2 1 view_user ericsson ericsson 2 1 control_user ericsson ericsson 2 1 authNoPrivMD5None ericsson no_value 2 1 authNoPrivSHA1None ericsson ericsson 3 1 noAuthNoPriv ericsson ericsson 1 1";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName snmp_telnet_https_http_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
    elsif ( $_ =~ m/SNMP_SSH_TELNET_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName snmp_ssh_telnet_prot $hostName";
         $lineConfigPort = ".config port address $portName $dummyPortAddrIpv4 161 public 1|2|3"
          . " %unique NoAuthNoPriv no_value no_value 1 1 AuthNoPriv_MD5_None ericsson no_value 2 1"
          . " AuthNoPriv_SHA1_None ericsson no_value 3 1 AuthPriv_MD5_DES ericsson ericsson 2 2"
          . " AuthPriv_SHA1_DES ericsson ericsson 3 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName snmp_ssh_telnet_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
    elsif ( $_ =~ m/LANSWITCH_SNMP_SSH_TELNET_PORT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName snmp_ssh_telnet_prot $hostName";
         $lineConfigPort = ".config port address $portName $dummyPortAddrIpv4 161 public 1|2|3"
          . " %unique NoAuthNoPriv no_value no_value 1 1 AuthNoPriv_MD5_None ericsson no_value 2 1"
          . " AuthNoPriv_SHA1_None ericsson no_value 3 1 AuthPriv_MD5_DES ericsson ericsson 2 2"
          . " AuthPriv_SHA1_DES ericsson ericsson 3 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName snmp_ssh_telnet_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $hostName 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }

    elsif ( $_ =~ m/MLPT_PORT$/){
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName xrpc_snmp_ssh_http_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 161 public 3 %unique admin Admin123 Admin123 2 2 guest Ericsson1 Ericsson1 2 2 operator Ericsson1 Ericsson1 2 2 net_admin Ericsson1 Ericsson1 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName xrpc_snmp_ssh_http_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName 0 162 2";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
       }
     elsif ( $_ =~ m/ML6352_PORT$/){
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName xrpc_snmp_ssh_http_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 161 public 2|3 %unique authPrivSHA1DES ericsson ericsson 3 2 ericsson authpassword privpassword 2 2 admin authpassword privpassword 3 2 guest authpassword privpassword 3 3 operator authpassword privpassword 2 1 net_admin authpassword privpassword 3 1 net_operator authpassword privpassword 2 3 admin_user authpassword privpassword 2 2 control_user authpassword privpassword 3 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName xrpc_snmp_ssh_http_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName 0 162 2";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
       }
     elsif ( $_ =~ m/ML6352_PORT_SNMPV2$/){
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName xrpc_snmp_ssh_http_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 161 public 2 %unique authPrivSHA1DES ericsson ericsson 3 2 ericsson authpassword privpassword 2 2 admin authpassword privpassword 3 2 guest authpassword privpassword 3 3 operator authpassword privpassword 2 1 net_admin authpassword privpassword 3 1 net_operator authpassword privpassword 2 3 admin_user authpassword privpassword 2 2 control_user authpassword privpassword 3 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName xrpc_snmp_ssh_http_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName 0 162 2";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
       }
     elsif ( $_ =~ m/ML6352_PORT_SNMPV3$/){
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName xrpc_snmp_ssh_http_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 161 public 3|2 %unique authPrivSHA1DES ericsson ericsson 3 2 ericsson authpassword privpassword 2 2 admin authpassword privpassword 3 2 guest authpassword privpassword 3 3 operator authpassword privpassword 2 1 net_admin authpassword privpassword 3 1 net_operator authpassword privpassword 2 3 admin_user authpassword privpassword 2 2 control_user authpassword privpassword 3 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName xrpc_snmp_ssh_http_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName 0 162 2";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
       }
    elsif ( $_ =~ m/APG_TELNET_APGTCP$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName apgtcp $hostName";
        $lineConfigPort =
          ".config port address $portName $dummyPortAddrIpv4 5002 5022 23";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName apgtcp";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestination 50000 50010";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( $_ =~ m/APG_APGTCP$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName apgtcp $hostName";
        $lineConfigPort =
          ".config port address $portName $dummyPortAddrIpv4 5000 5022 23";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName apgtcp";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestination 50000 50010";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( $_ =~ m/APG_NETCONF_HTTP_HTTPS_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName apgtcp_netconf_https_http_prot $hostName";
        $lineConfigPort =
          ".config port address $portName $dummyPortAddrIpv4 161 public 1 %unique 3 5001 5000 52023 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName apgtcp_netconf_https_http_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestination 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
        elsif ( $_ =~ m/APG_NETCONF_HTTP_HTTPS_TLS_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName apgtcp_netconf_https_http_prot $hostName";
        $lineConfigPort =
          ".config port address $portName $dummyPortAddrIpv4 161 public 1 %unique 2 5001 5000 52002 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName apgtcp_netconf_https_http_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestination 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( $_ =~ m/APG43L_APGTCP$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName apgtcp $hostName";
        $lineConfigPort =
          ".config port address $portName $dummyPortAddrIpv4 5000 5022 23";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName apgtcp";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestination 65505 65510";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( $_ =~ m/MSC_S_CP$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $createPort msc-s_cp_prot $hostName";
        $lineConfigPort = ".config port address force_no_value $createPort";
        &buildPort( $lineAddPort, $lineConfigPort, $createPort );
    }
    elsif ( $_ =~ m/STN_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName snmp_ssh_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 161 public 2 %unique %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName snmp_ssh_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestination 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( $_ =~ m/LANSWITCH_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort =
          ".config add port $createPort https_http_snmp_ssh $hostName";
        $lineConfigPort =
".config port address $createPort $dummyPortAddrIpv4 161 public 2 %unique %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $createPort );
        $lineAddPortDd =
".config add external $createDefaultDestinationName https_http_snmp_ssh";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestination 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( $_ =~ m/LANSWITCH_PROT_SNMPV3$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort =
          ".config add port $createPort https_http_snmp_ssh $hostName";
        $lineConfigPort =
".config port address $createPort $dummyPortAddrIpv4 161 public 3|2 %unique %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $createPort );
        $lineAddPortDd =
".config add external $createDefaultDestinationName https_http_snmp_ssh";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestination 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( $_ =~ m/TSP_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $createPort tsp_prot $hostName";
        $lineConfigPort =
".config port address $createPort $dummyPortAddrIpv4 1161 public 2 %unique 7423 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $createPort );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName tsp_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestination 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
    elsif ( $_ =~ m/TSP_SSH_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $createPort tsp_ssh_prot $hostName";
        $lineConfigPort =
".config port address $createPort $dummyPortAddrIpv4 1161 public 2 %unique 7423 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $createPort );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName tsp_ssh_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestination 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
    elsif ( $_ =~ m/HTTP_HTTPS_PORT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $createPort http_https_port $hostName";
        $lineConfigPort =
".config port address $createPort $dummyPortAddrIpv4 1161 public 2 %unique %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $createPort );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName http_https_port";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestination 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
    elsif ( $_ =~ m/NETCONF_HTTP_HTTPS_TLS_PORT$/ ) {
         my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_https_http_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 161 public 3|2|1 %unique 2 mediation authpass privpass 1 1";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_https_http_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
   elsif ( $_ =~ m/NETCONF_HTTP_HTTPS_SSH_PORT$/ ) {
         my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_https_http_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 161 public 3|2|1 %unique 3 mediation authpass privpass 1 1";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_https_http_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
   elsif ( $_ =~ m/NETCONF_HTTP_HTTPS_SSH_FRONTHAUL_PORT$/ ) {
         my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_https_http_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 161 public 2 %unique 3 mediation authpass privpass 1 1";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_https_http_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( $_ =~ m/NETCONF_HTTP_HTTPS_TLS_SNMPV3_FRONTHAUL_PORT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_https_http_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 161 public 2|3 %unique 2 mediation authpass privpass 1 1 ENM-user ericsson ericsson 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_https_http_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
   elsif ( $_ =~ m/MSC_BC_IS_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName apgtcp_netconf_https_http_prot $hostName";
        $lineConfigPort =
          ".config port address $portName $dummyPortAddrIpv4 161 public 2 %unique 3 5001 5000 52023 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName apgtcp_netconf_https_http_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestination 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
   elsif ( $_ =~ m/MSC_BC_IS_TLS_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName apgtcp_netconf_https_http_prot $hostName";
        $lineConfigPort =
          ".config port address $portName $dummyPortAddrIpv4 161 public 2 %unique 2 5001 5000 52023 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName apgtcp_netconf_https_http_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestination 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( ( $_ =~ m/IS_PROT$/ ) &&  ( $_ !~ m/SNMPV3_IS_PROT$/ ) ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_https_http_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 161 public 2 %unique 1 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_https_http_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName 0.0.0.0 10163 2";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
    elsif ( $_ =~ m/SNMPV3_IS_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_https_http_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv4 161 public 3 %unique 1 %simname_%nename authpass privpass 2 2 SNMPV3USER authpassword privpassword 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_https_http_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName 0.0.0.0 10163 2";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
   elsif( $_=~m/O1_PORT$/) {
     my$createDefaultDestinationName="$createPort";
      $lineAddPort=".config add port $portName yang_prot $hostName";
      $lineConfigPort=
".config port address $portName $dummyPortAddrIpv4 161 public 2 %unique 2 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
         ".config add external $createDefaultDestinationName yang_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $hostName 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
}
}

#----------------------------------------------------------------------------------
#Subroutine to create ports IPV6
#----------------------------------------------------------------------------------
sub createPortsIpv6 {
    ( my $createPort ) = @_;
    $_ = $createPort;
    my $portName = "$createPort";

    if ( $_ =~ m/IIOP_PROT_IPV6/ ) {
        $lineAddPort = ".config add port $portName iiop_prot $hostName";
        $lineConfigPort =
".config port address $portName nehttpd $dummyPortAddrIpv6 56834 56836 no_value";

        &buildPort( $lineAddPort, $lineConfigPort, $portName );
    }
    elsif ( $_ =~ m/NETCONF_PROT_IPV6$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 1161 public 2 %unique 1 mediation authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestinationIpv6 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
	}
    elsif ( $_ =~ m/NETCONF_PROT_TLS_IPV6$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 161 public 3|2|1 %unique 2 mediation authpass privpass 1 1";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
    elsif ( $_ =~ m/NETCONF_PROT_TLS_SNMPV3_IPV6$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 161 public 3|2|1 %unique 2 AuthPrivMD5DES ericsson ericsson 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
    elsif ( $_ =~ m/NETCONF_PROT_SSH_IPV6$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 1161 public 2 %unique 3 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestinationIpv6 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
    elsif ( $_ =~ m/YANG_SNMP_SSH_IPV6_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName yang_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 1161 public 2 %unique 3 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
 ".config add external $createDefaultDestinationName yang_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestinationIpv6 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
    elsif ( $_ =~ m/YANG_SNMP_TLS_IPV6_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName yang_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 1161 public 1|2|3 %unique 2 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
".config add external $createDefaultDestinationName yang_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestinationIpv6 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
    elsif ( $_ =~ m/YANG_SNMP_SSH_EPG_IPV6_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName yang_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 1161 public 1|2|3 %unique 3 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName yang_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }
  elsif ( $_ =~ m/YANG_SNMP_SSH_WMG_IPV6_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName yang_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 1161 public 3|2|1  %unique 3 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName yang_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }

   elsif ( $_ =~ m/YANG_SNMP_SSH_SMSF_IPV6_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName yang_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 1161 public 3|2|1  %unique 3 %simname_%nename authpass privpass 2 2 authPrivSHA1DES ericsson ericsson 3 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName yang_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );

    }

     elsif ( $_ =~ m/NETCONF_PROT_SSH_MTAS_IPV6$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 161 public 2 %unique 3 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
".config add external $createDefaultDestinationName netconf_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestinationIpv6 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
        $createDefaultDestinationName, $hostName );
     }
    elsif ( $_ =~ m/NETCONF_HTTP_HTTPS_TLS_IPV6_PORT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_https_http_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 161 public 3|2|1 %unique 2 mediation authpass privpass 1 1";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_https_http_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
    elsif ( $_ =~ m/NETCONF_HTTP_HTTPS_SSH_IPV6_PORT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_https_http_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 161 public 3|2|1 %unique 3 mediation authpass privpass 1 1";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_https_http_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
    elsif ( $_ =~ m/NETCONF_HTTP_HTTPS_SSH_FRONTHAUL_IPV6_PORT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_https_http_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 161 public 2 %unique 3 mediation authpass privpass 1 1";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_https_http_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
    elsif ( $_ =~ m/NETCONF_HTTP_HTTPS_TLS_SNMPV3_FRONTHAUL_IPV6_PORT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_https_http_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 161 public 2|3 %unique 2 mediation authpass privpass 1 1 ENM-user ericsson ericsson 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
        ".config add external $createDefaultDestinationName netconf_https_http_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
    elsif ( $_ =~ m/LANSWITCH_PROT_SNMPV3_IPV6_PORT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort =
          ".config add port $createPort https_http_snmp_ssh $hostName";
        $lineConfigPort =
".config port address $createPort $dummyPortAddrIpv6 161 public 3|2 %unique %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $createPort );
        $lineAddPortDd =
".config add external $createDefaultDestinationName https_http_snmp_ssh";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestinationIpv6 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
    elsif ( $_ =~ m/SNMP_SSH_PROT_IPV6_PORT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName snmp_ssh_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 161 public 1|2 %unique %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName snmp_ssh_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestinationIpv6 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
    elsif ( $_ =~ m/TSP_SSH_PROT_IPV6_PORT$/){
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName tsp_ssh_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 161 public 1 %unique 7423 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName tsp_ssh_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestinationIpv6 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
    elsif ( $_ =~ m/ML6352_PORT_IPV6_PORT$/){
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName xrpc_snmp_ssh_http_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 161 public 2|3 %unique authPrivSHA1DES ericsson ericsson 3 2 ericsson authpassword privpassword 2 2 admin authpassword privpassword 3 2 guest authpassword privpassword 3 3 operator authpassword privpassword 2 1 net_admin authpassword privpassword 3 1 net_operator authpassword privpassword 2 3 admin_user authpassword privpassword 2 2 control_user authpassword privpassword 3 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName xrpc_snmp_ssh_http_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestinationIpv6 162 2";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
         elsif ( $_ =~ m/ML6352_PORT_SNMPv2_IPV6_PORT$/){
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName xrpc_snmp_ssh_http_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 161 public 2 %unique authPrivSHA1DES ericsson ericsson 3 2 ericsson authpassword privpassword 2 2 admin authpassword privpassword 3 2 guest authpassword privpassword 3 3 operator authpassword privpassword 2 1 net_admin authpassword privpassword 3 1 net_operator authpassword privpassword 2 3 admin_user authpassword privpassword 2 2 control_user authpassword privpassword 3 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName xrpc_snmp_ssh_http_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestinationIpv6 162 2";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
         elsif ( $_ =~ m/ML6352_PORT_SNMPv3_IPV6_PORT$/){
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName xrpc_snmp_ssh_http_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 161 public 3|2 %unique authPrivSHA1DES ericsson ericsson 3 2 ericsson authpassword privpassword 2 2 admin authpassword privpassword 3 2 guest authpassword privpassword 3 3 operator authpassword privpassword 2 1 net_admin authpassword privpassword 3 1 net_operator authpassword privpassword 2 3 admin_user authpassword privpassword 2 2 control_user authpassword privpassword 3 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName xrpc_snmp_ssh_http_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestinationIpv6 162 2";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
    elsif ( $_ =~ m/SNMP_TELNET_PROT_IPV6_PORT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName snmp_telnet_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 161 public,private,trap 1|2|3 %unique no_value authPrivSHA1DES ericsson ericsson 3 2 admin_user ericsson no_value 2 1 authPrivMD5DES ericsson ericsson 2 2 oper_user ericsson ericsson 2 1 view_user ericsson ericsson 2 1 control_user ericsson ericsson 2 1 authNoPrivMD5None ericsson no_value 2 1 authNoPrivSHA1None ericsson ericsson 3 1 noAuthNoPriv ericsson ericsson 1 1";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName snmp_telnet_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
elsif ( $_ =~ m/SNMP_TELNET_IC8855_PROT_IPV6_PORT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName snmp_telnet_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 161 public,private,trap 1|2|3 %unique 1 authPrivSHA1DES ericsson ericsson 3 2 admin_user ericsson no_value 2 1 authPrivMD5DES ericsson ericsson 2 2 oper_user ericsson ericsson 2 1 view_user ericsson ericsson 2 1 control_user ericsson ericsson 2 1 authNoPrivMD5None ericsson no_value 2 1 authNoPrivSHA1None ericsson ericsson 3 1 noAuthNoPriv ericsson ericsson 1 1";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName snmp_telnet_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }

    elsif ( $_ =~ m/SNMP_TELNET_SECURE_PROT_IPV6_PORT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName snmp_telnet_https_http_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 161 public,private,trap 1|2|3 %unique no_value authPrivSHA1DES ericsson ericsson 3 2 admin_user ericsson no_value 2 1 authPrivMD5DES ericsson ericsson 2 2 oper_user ericsson ericsson 2 1 view_user ericsson ericsson 2 1 control_user ericsson ericsson 2 1 authNoPrivMD5None ericsson no_value 2 1 authNoPrivSHA1None ericsson ericsson 3 1 noAuthNoPriv ericsson ericsson 1 1";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName snmp_telnet_https_http_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
    elsif ( $_ =~ m/NETCONF_PROT_SSH_FRONTHAUL6080_IPV6$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 161 public 2 %unique 3 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestinationIpv6 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
    elsif ( $_ =~ m/NETCONF_PROT_SSH_FRONTHAUL6020_IPV6$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 161 public 2 %unique 3 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestinationIpv6 161 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
    elsif ( $_ =~ m/LANSWITCH_SNMP_SSH_TELNET_IPV6_PORT$/ ) {
       my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName snmp_ssh_telnet_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 161 public 1|2|3"
          . " %unique NoAuthNoPriv no_value no_value 1 1 AuthNoPriv_MD5_None ericsson no_value 2 1"
          . " AuthNoPriv_SHA1_None ericsson no_value 3 1 AuthPriv_MD5_DES ericsson ericsson 2 2"
          . " AuthPriv_SHA1_DES ericsson ericsson 3 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName snmp_ssh_telnet_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestinationIpv6 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
    elsif ( $_ =~ m/SNMP_SSH_TELNET_IPV6_PROT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName snmp_ssh_telnet_prot $hostName";
         $lineConfigPort = ".config port address $portName $dummyPortAddrIpv4 161 public 1|2|3"
          . " %unique NoAuthNoPriv no_value no_value 1 1 AuthNoPriv_MD5_None ericsson no_value 2 1"
          . " AuthNoPriv_SHA1_None ericsson no_value 3 1 AuthPriv_MD5_DES ericsson ericsson 2 2"
          . " AuthPriv_SHA1_DES ericsson ericsson 3 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName snmp_ssh_telnet_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }

    elsif ( $_ =~ m/NETCONF_PROT_SSH_IPV6_PORT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort = ".config add port $portName netconf_prot $hostName";
        $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 1161 public 2 %unique 3 %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $portName );
        $lineAddPortDd =
          ".config add external $createDefaultDestinationName netconf_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestinationIpv6 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
    }
    elsif ( $_ =~ m/LANSWITCH_PROT_IPV6_PORT$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort =
          ".config add port $createPort https_http_snmp_ssh $hostName";
        $lineConfigPort =
".config port address $createPort $dummyPortAddrIpv6 161 public 2 %unique %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $createPort );
        $lineAddPortDd =
".config add external $createDefaultDestinationName https_http_snmp_ssh";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestination 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
   }
    elsif ( $_ =~ m/STN_PROT_IPV6$/ ) {
        my $createDefaultDestinationName = "$createPort";
        $lineAddPort =
          ".config add port $createPort snmp_ssh_prot $hostName";
        $lineConfigPort =
".config port address $createPort $dummyPortAddrIpv6 161 public 2 %unique %simname_%nename authpass privpass 2 2";
        &buildPort( $lineAddPort, $lineConfigPort, $createPort );
        $lineAddPortDd =
".config add external $createDefaultDestinationName snmp_ssh_prot";
        $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestinationIpv6 162 1";
        &buildDD( $lineAddPortDd, $lineConfigPortDd,
            $createDefaultDestinationName, $hostName );
   }
   elsif ( $_ =~ m/HTTP_HTTPS_IPV6_PORT$/ ) {
          my $createDefaultDestinationName = "$createPort";
          $lineAddPort = ".config add port $createPort http_https_port $hostName";
          $lineConfigPort =
                  ".config port address $createPort $dummyPortAddrIpv6 1161 public 2 %unique %simname_%nename authpass privpass 2 2";
          &buildPort( $lineAddPort, $lineConfigPort, $createPort );
          $lineAddPortDd =
                   ".config add external $createDefaultDestinationName http_https_port";
          $lineConfigPortDd =
                   ".config external address $createDefaultDestinationName $createDefaultDestinationIpv6 162 1";
          &buildDD( $lineAddPortDd, $lineConfigPortDd,
               $createDefaultDestinationName, $hostName );
   }
   elsif ( $_ =~ m/NETCONF_PROT_IS_TLS_IPV6$/ ) {
       my $createDefaultDestinationName = "$createPort";
       $lineAddPort = ".config add port $portName netconf_prot $hostName";
       $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 161 public 1 %unique 2 %simname_%nename authpass privpass 2 2";
       &buildPort( $lineAddPort, $lineConfigPort, $portName );
       $lineAddPortDd =
".config add external $createDefaultDestinationName netconf_prot";
       $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestinationIpv6 10163 2";
       &buildDD( $lineAddPortDd, $lineConfigPortDd,
           $createDefaultDestinationName, $hostName );
   }
   elsif ( $_ =~ m/APG_NETCONF_HTTP_HTTPS_TLS_IPV6_PROT$/ ) {
       my $createDefaultDestinationName = "$createPort";
       $lineAddPort = ".config add port $portName apgtcp_netconf_https_http_prot $hostName";
       $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 161 public 1 %unique 2 5001 5000 52002 %simname_%nename authpass privpass 2 2";
       &buildPort( $lineAddPort, $lineConfigPort, $portName );
       $lineAddPortDd =
".config add external $createDefaultDestinationName apgtcp_netconf_https_http_prot";
       $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestinationIpv6 162 1";
       &buildDD( $lineAddPortDd, $lineConfigPortDd,
           $createDefaultDestinationName, $hostName );
   }
   elsif ( $_ =~ m/MSC_BC_IS_TLS_IPV6_PROT$/ ) {
       my $createDefaultDestinationName = "$createPort";
       $lineAddPort = ".config add port $portName apgtcp_netconf_https_http_prot $hostName";
       $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 161 public 2 %unique 2 5001 5000 52023 %simname_%nename authpass privpass 2 2";
       &buildPort( $lineAddPort, $lineConfigPort, $portName );
       $lineAddPortDd =
".config add external $createDefaultDestinationName apgtcp_netconf_https_http_prot";
       $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestinationIpv6 162 1";
       &buildDD( $lineAddPortDd, $lineConfigPortDd,
           $createDefaultDestinationName, $hostName );
   }
   elsif ( $_ =~ m/APG43L_APGTCP_IPV6$/ ) {
       my $createDefaultDestinationName = "$createPort";
       $lineAddPort = ".config add port $portName apgtcp $hostName";
       $lineConfigPort =
".config port address $portName $dummyPortAddrIpv6 5000 5022 23";
       &buildPort( $lineAddPort, $lineConfigPort, $portName );
       $lineAddPortDd =
".config add external $createDefaultDestinationName apgtcp";
       $lineConfigPortDd =
".config external address $createDefaultDestinationName $createDefaultDestinationIpv6 65505 65510";
       &buildDD( $lineAddPortDd, $lineConfigPortDd,
           $createDefaultDestinationName, $hostName );
   }
}



#----------------------------------------------------------------------------------
#Define NETSim MO file and Open file in append mode
#----------------------------------------------------------------------------------
$MML_MML = "MML.mml";
open MML, "+>>$MML_MML";

if ( $docker =~ m/yes/i )
{
print MML ".select configuration\n";
print MML ".config newserver netsim 1\n";
print MML ".config save\n";
}
#----------------------------------------------------------------------------------
#Call to create all kinds of ipv4 ports
#----------------------------------------------------------------------------------
&createPorts("IIOP_PROT");
&createPorts("NETCONF_PROT");
&createPorts("NETCONF_PROT_TLS");
&createPorts("SGSN");
&createPorts("STN_PROT");
&createPorts("SGSN_PROT");
&createPorts("SNMP_SSH_PROT");
&createPorts("SNMP");
&createPorts("SNMP_TELNET_PROT");
&createPorts("SNMP_TELNET_IC8855_PROT");
&createPorts("SNMP_TELNET_SECURE_PROT");
&createPorts("SNMP_SSH_TELNET_PROT");
&createPorts("APG_APGTCP");
&createPorts("MSC_S_CP");
&createPorts("NETCONF_PROT_SSH");
&createPorts("YANG_SNMP_SSH_PROT");
&createPorts("YANG_SNMP_TLS_PROT");
&createPorts("YANG_SNMP_SSH_EPG_PROT");
&createPorts("YANG_SNMP_SSH_WMG_PROT");
&createPorts("YANG_SNMP_SSH_SMSF_PROT");
&createPorts("NETCONF_PROT_SSH_MTAS");
&createPorts("NETCONF_PROT_SSH_FRONTHAUL6020");
&createPorts("NETCONF_PROT_SSH_FRONTHAUL6080");
&createPorts("NETCONF_PROT_SSH_MME");
&createPorts("NETCONF_PROT_EPG");
&createPorts("NETCONF_PROT_SSH_MME_ECIM");
&createPorts("LANSWITCH_PROT");
&createPorts("LANSWITCH_PROT_SNMPV3");
&createPorts("APG43L_APGTCP");
&createPorts("TSP_PROT");
&createPorts("TSP_SSH_PROT");
&createPorts("HTTP_HTTPS_PORT");
&createPorts("APG_TELNET_APGTCP");
&createPorts("NETCONF_PROT_SSH_SPITFIRE");
&createPorts("NETCONF_PROT_IS");
&createPorts("NETCONF_PROT_IS_TLS");
&createPorts("NETCONF_PROT_SSH_DG2");
&createPorts("MLPT_PORT");
&createPorts("ML6352_PORT");
&createPorts("ML6352_PORT_SNMPV2");
&createPorts("ML6352_PORT_SNMPV3");
&createPorts("NETCONF_HTTP_HTTPS_TLS_PORT");
&createPorts("NETCONF_HTTP_HTTPS_SSH_PORT");
&createPorts("NETCONF_HTTP_HTTPS_SSH_FRONTHAUL_PORT");
&createPorts("NETCONF_HTTP_HTTPS_TLS_SNMPV3_FRONTHAUL_PORT");
&createPorts("LANSWITCH_SNMP_SSH_TELNET_PORT");
&createPorts("APG_NETCONF_HTTP_HTTPS_PROT");
&createPorts("APG_NETCONF_HTTP_HTTPS_TLS_PROT");
&createPorts("NETCONF_PROT_TLS_SNMPV3");
&createPorts("MSC_BC_IS_PROT");
&createPorts("MSC_BC_IS_TLS_PROT");
&createPorts("IS_PROT");
&createPorts("SNMPV3_IS_PROT");
&createPorts("O1_PORT");
#----------------------------------------------------------------------------------
#Call to create all kinds of ipv6 ports
#----------------------------------------------------------------------------------
&createPortsIpv6("IIOP_PROT_IPV6");
&createPortsIpv6("STN_PROT_IPV6");
&createPortsIpv6("NETCONF_PROT_TLS_IPV6");
&createPortsIpv6("NETCONF_PROT_SSH_IPV6");
&createPortsIpv6("YANG_SNMP_SSH_IPV6_PROT");
&createPortsIpv6("YANG_SNMP_TLS_IPV6_PROT");
&createPortsIpv6("YANG_SNMP_SSH_EPG_IPV6_PROT");
&createPortsIpv6("YANG_SNMP_SSH_WMG_IPV6_PROT");
&createPortsIpv6("YANG_SNMP_SSH_SMSF_IPV6_PROT");
&createPortsIpv6("NETCONF_PROT_SSH_MTAS_IPV6");
&createPortsIpv6("NETCONF_HTTP_HTTPS_TLS_IPV6_PORT");
&createPortsIpv6("LANSWITCH_PROT_SNMPV3_IPV6_PORT");
&createPortsIpv6("NETCONF_HTTP_HTTPS_SSH_IPV6_PORT");
&createPortsIpv6("NETCONF_HTTP_HTTPS_SSH_FRONTHAUL_IPV6_PORT");
&createPortsIpv6("NETCONF_HTTP_HTTPS_TLS_SNMPV3_FRONTHAUL_IPV6_PORT");
&createPortsIpv6("SNMP_TELNET_PROT_IPV6_PORT");
&createPortsIpv6("SNMP_TELNET_IC8855_PROT_IPV6_PORT");
&createPortsIpv6("SNMP_TELNET_SECURE_PROT_IPV6_PORT");
&createPortsIpv6("SNMP_SSH_PROT_IPV6_PORT");
&createPortsIpv6("TSP_SSH_PROT_IPV6_PORT");
&createPortsIpv6("ML6352_PORT_IPV6_PORT");
&createPortsIpv6("ML6352_PORT_SNMPv2_IPV6_PORT");
&createPortsIpv6("ML6352_PORT_SNMPv3_IPV6_PORT");
&createPortsIpv6("NETCONF_PROT_SSH_FRONTHAUL6020_IPV6");
&createPortsIpv6("NETCONF_PROT_SSH_FRONTHAUL6080_IPV6");
&createPortsIpv6("LANSWITCH_SNMP_SSH_TELNET_IPV6_PORT");
&createPortsIpv6("LANSWITCH_PROT_IPV6_PORT");
&createPortsIpv6("NETCONF_PROT_SSH_IPV6_PORT");
&createPortsIpv6("NETCONF_PROT_IPV6");
&createPortsIpv6("NETCONF_PROT_TLS_SNMPV3_IPV6");
&createPortsIpv6("HTTP_HTTPS_IPV6_PORT");
&createPortsIpv6("APG_NETCONF_HTTP_HTTPS_TLS_IPV6_PROT");
&createPortsIpv6("NETCONF_PROT_IS_TLS_IPV6");
&createPortsIpv6("MSC_BC_IS_TLS_IPV6_PROT");
&createPortsIpv6("APG43L_APGTCP_IPV6");
&createPortsIpv6("SNMP_SSH_TELNET_IPV6_PROT");
#
system("$NETSIM_INSTALL_SHELL < $MML_MML");
if ($? != 0)
{
    print "ERROR: Failed to execute system command ($NETSIM_INSTALL_SHELL < $MML_MML)\n";
    exit(207);
}
close MML;
