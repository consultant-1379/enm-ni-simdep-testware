#!/usr/bin/perl -w
use strict;

###################################################################################
#     File Name   : setupSecutiy.pl
#     Author      : Fatih Onur, Sneha
#     Description : See usage below.
###################################################################################
#
#----------------------------------------------------------------------------------
#Check if the scrip is executed as netsim user
#----------------------------------------------------------------------------------
#
my $user = `whoami`;
chomp($user);
my $expectedUser = 'netsim';
if ( $user ne $expectedUser ) {
    print "ERROR: Not $expectedUser user. Please execute the script as $expectedUser user\n";
    exit(201);
}

#
#----------------------------------------------------------------------------------
#Check if the script usage is right
#----------------------------------------------------------------------------------

my $USAGE =<<USAGE;
Descr: Sets up TLS / SL2 / SL3 security.
    Usage:
        $0 <workingPath> <switchToEnm> <serverType> <reApplyCerts> <simName> <neType>

        where:
            <workingPath>         : Specifies working directory
            <switchToEnm>         : Specifies if the ENM is enabled or not. Possible values: yes/no
            <serverType>          : Specifies if the server type. Possible values: vapp/vm.
            <reApplyCerts>        : Jenkins parameter which specifies if re applying certs is yes/no. (Default Values is no).
            <simName>             : Specifies simName for which TLS has to be set up.
            <neType>              : Specifies neType of the sim.

        usage examples:
             $0 /tmp/LTE/simNetDeployer/ yes vapp no LTE15B-V13x80_16A-V17x80-5K-DG2-FDD-LTE08 MSRBS-V2
             $0 /tmp/LTE/simNetDeployer/ yes vm yes LTE15B-V13x80_16A-V17x80-5K-DG2-FDD-LTE08 MSRBS-V2

        dependencies:
              1. Simulations must be already rolled in the netsim server.

        Return Values: 201 -> Not a netsim user.
                       202 -> Usage is incorrect.
                       207 -> Failed to execute system command.
USAGE
if ( @ARGV < 5 or @ARGV > 7 ) {
    print "$USAGE";
    exit(202);
}
print "RUNNING: $0 @ARGV \n";

#
#----------------------------------------------------------------------------------
#Variables
#----------------------------------------------------------------------------------
my $NETSIM_INSTALL_SHELL = "/netsim/inst/netsim_pipe";
my $dirSimNetDeployer    = "$ARGV[0]";
my $switchToEnm          = "$ARGV[1]";
my $serverType           = "$ARGV[2]";
my $reApplyCerts         = $ARGV[3];
my $simName              = $ARGV[4];
my $neType               = $ARGV[5];

my @neType = split(/:/, $neType);
$neType = join(' ', @neType);

chomp($reApplyCerts);
$reApplyCerts = "no" if not defined $reApplyCerts;
#print "reApplyCerts: $reApplyCerts \n";


#
#----------------------------------------------------------------------------------
#Set up TLS security.
#----------------------------------------------------------------------------------
sub setupSecurityTLS {
    ( my $dirSimNetDeployer, my $simName ) = @_;

    &createTLS( $dirSimNetDeployer, $simName );

    print MML <<"END";
.open $simName
.selectnocallback network
.stop -parallel
.set ssliop yes TLS
.set save
END
}

#
#----------------------------------------------------------------------------------
#Set up TLS security for LTE nodes
#----------------------------------------------------------------------------------
sub setupSecurityTLSForLte {
    ( my $dirSimNetDeployer, my $simName ) = @_;

    &createTLS( $dirSimNetDeployer, $simName );

    print MML <<"END";
.open $simName
.selectnocallback network
.stop -parallel
.set ssliop yes TLS
.set save
.start -parallel
setmoattribute:mo="ManagedElement=1,SystemFunctions=1,Security=1", attributes="requestedSecurityLevel=2";
setmoattribute:mo="ManagedElement=1,SystemFunctions=1,Security=1", attributes="operationalSecurityLevel=2";
END
}

#-------------------------------------------------------------------------------------
#Set up TLS Security for WRAN PICO nodes
#-------------------------------------------------------------------------------------
sub setupSecurityTLSForPico {
    ( my $dirSimNetDeployer, my $simName ) = @_;

    my $hasPico =
      `echo ".selectnetype PRBS*" | /netsim/inst/netsim_pipe -sim $simName`;
    if ( $hasPico =~ "OK" ) {
        &createTLS( $dirSimNetDeployer, $simName );
            print MML <<"END";
.open $simName
.selectnetype PRBS*
.stop -parallel
.set ssliop yes TLS
.set save
.start -parallel
END
    }
}

#-------------------------------------------------------------------------------------
#Set up TLS Security for WRAN|LTE DG2 and LTE PICO (MSRBS) Nodes
#-------------------------------------------------------------------------------------
sub setupSecurityTLSForDg2AndLtePico {
    ( my $dirSimNetDeployer, my $simName, my $serverType ) = @_;
    my $hasDG2 = `echo ".selectnetype MSRBS-V*" | /netsim/inst/netsim_pipe -sim $simName`;
    if ( $hasDG2 =~ "OK" ) {
        &createTLS( $dirSimNetDeployer, $simName );
        print MML <<END;
.open $simName
.selectnetype MSRBS-V*
.stop -parallel
.set ssliop yes TLS
.set save
END
    }
}
#---------------------------------------------------------------------------------------
#Create TLS Security
#---------------------------------------------------------------------------------------
sub createTLS {

    ( my $dirSimNetDeployer, my $simName ) = @_;
    print "INFO: Setting up TLS security\n";
    my $certPem   = "$dirSimNetDeployer/Security/TLS/cert_single.pem";
    my $caCertPem = "$dirSimNetDeployer/Security/TLS/CombinedCertCA.pem";
    my $kepPem    = "$dirSimNetDeployer/Security/TLS/keys.pem";
print MML <<"END";
.open $simName
.setssliop createormodify TLS
.setssliop description TLS
.setssliop clientcertfile $certPem
.setssliop clientcacertfile $caCertPem
.setssliop clientkeyfile $kepPem
.setssliop clientpassword eric123
.setssliop clientverify 0
.setssliop clientdepth 1
.setssliop servercertfile $certPem
.setssliop servercacertfile $caCertPem
.setssliop serverkeyfile $kepPem
.setssliop serverpassword eric123
.setssliop serververify 0
.setssliop serverdepth 1
.setssliop protocol_version tlsv1|tlsv1.1|tlsv1.2
.setssliop save force
END
}

#---------------------------------------------------------------------------------------
#Create SL2 Security Definition
#---------------------------------------------------------------------------------------
sub createSL2 {

    ( my $dirSimNetDeployer, my $simName ) = @_;
    print "INFO: Setting up TLS security\n";
    my $certPem   = "$dirSimNetDeployer/Security/SL2/cert_single.pem";
    my $caCertPem = "$dirSimNetDeployer/Security/SL2/CombinedCertCA.pem";
    my $kepPem    = "$dirSimNetDeployer/Security/SL2/keys.pem";
    print MML << "END";
.open $simName
.setssliop createormodify SL2
.setssliop description SL2
.setssliop clientcertfile $certPem
.setssliop clientcacertfile $caCertPem
.setssliop clientkeyfile $kepPem
.setssliop clientpassword secmgmt
.setssliop clientverify 0
.setssliop clientdepth 1
.setssliop servercertfile $certPem
.setssliop servercacertfile $caCertPem
.setssliop serverkeyfile $kepPem
.setssliop serverpassword secmgmt
.setssliop serververify 0
.setssliop serverdepth 1
.setssliop protocol_version tlsv1|tlsv1.1|tlsv1.2
.setssliop save force
END
}

#---------------------------------------------------------------------------------------
#Set corba security
#---------------------------------------------------------------------------------------
sub setCorba {
        ( my $simName ) = @_;
       print MML << "END";
.open $simName
.selectnocallback network
.stop -parallel
.set ssliop no->yes SL2
.set save
END
}

#
#----------------------------------------------------------------------------------
#Set up SL2 security for LTE and MGw nodes
#----------------------------------------------------------------------------------
sub setupSecuritySL2ForLteAndMgw {
    ( my $dirSimNetDeployer, my $simName, my $serverType ) = @_;

    &createSL2( $dirSimNetDeployer, $simName );
    &setCorba($simName);

#    print MML << "END";
#.open $simName
#.selectnocallback network
#.start -parallel 4
#oseshell
#secmode -s
#secmode -l 2
#secmode -s
#END
}

#
#--------------------------------------------------------------------------------------
#Main
#--------------------------------------------------------------------------------------
#
#Define NETSim MO file and Open file in append mode
#----------------------------------------------------------------------------------
my $minimum=1;
my $maximum=100_000_000_000;
my $randomId = $minimum + int(rand($maximum - $minimum));
my $MML_MML = "MML-${randomId}.mml";
open MML, "+>>$dirSimNetDeployer/dat/$MML_MML";

if(lc $reApplyCerts eq lc "NO") {
    #---------------------------------------------------
    #Start of Rollout functionality to individual sims
    #---------------------------------------------------
    if(lc "$switchToEnm" eq lc "YES") {
        if ( $neType =~ m/MSRBS-V/i
            || $neType =~ m/WCDMA PRBS/i
            || $neType =~ m/ESAPC/i
            || $neType =~ m/EPG-SSR/i
            || $neType =~ m/EPG-EVR/i
            || $neType =~ m/TCU03/i
            || $neType=~  m/TCU04/i
            ||( $neType =~ m/WCDMA RNC/i && $simName =~ m/MSRBS/i )
            || $neType =~ m/C608/i
            || $neType =~ m/ECM/i
            || $neType =~ m/vRM/i
            || $neType =~ m/vRSM/i
            || $neType =~ m/RAN-VNFM/i
            || $neType =~ m/EVNFM/i
            || $neType =~ m/VNF-LCM/i
            ||($neType =~ m/RNNODE/i && $simName =~ m/TLS/i)
            ||($neType =~ m/vPP/i && $simName =~ m/TLS/i)
            ||($neType =~ m/vRC/i && $simName =~ m/TLS/i)) {
            print "INFO: Creating TLS for LTE MSRBS-v(Inc. WRAN sims)|WCDMA PRBS|CORE ESAPC|CORE EPG-SSR|CORE EPG-EVR|GSM TCU|CORE-C608|CORE-ECM"
                 ."|LTE RNNNODE|LTE VPP|LTE VRC nodes |LTE EVNFM|LTE VNF-LCM |LTE VNFM nodes \n";
            &setupSecurityTLS( $dirSimNetDeployer, $simName );
        } elsif ( $neType =~ /^LTE ERBS/i
              ||  $neType =~ /MGW/i
              || ($neType =~ /WCDMA RNC/i
                  && $simName =~ /-RBS/i)
              || ($neType =~ /WCDMA RNC/i
                  && $simName =~ /-UPGIND/i) ) {
            print "INFO: Creating SL2 for CPP LTE|MGW|RNC|RBS|RNC UPGIND nodes \n";
            &setupSecuritySL2ForLteAndMgw( $dirSimNetDeployer, $simName, $serverType );
        }
    } else {
        if (   $neType =~ m/^WPP SGSN/i
            || $neType =~ /H2S/i
            || $neType =~ /MTAS/i
            || $neType =~ /cscf/i
            || $neType =~ /esapv/i
            || $neType =~ /prbs/i
            || $neType =~ /TCU03/i
            || $neType =~ /msrbs/i ) {
                &setupSecurityTLS( $dirSimNetDeployer, $simName );
        }
        #------------------------------------------------
        #Handling for RNC
        #------------------------------------------------
        elsif ( $neType =~ /RNC/i ) {
            print "INFO: Creating TLS for PICO and WRAN DG2 nodes";
            &setupSecurityTLSForPico( $dirSimNetDeployer, $simName );
            &setupSecurityTLSForDG2( $dirSimNetDeployer, $simName );
        }
        #------------------------------------------------
        #Handling for LTE
        #------------------------------------------------
        elsif ( $neType =~ /LTE/i ) {
            print "INFO: Creating TLS for LTE nodes";
            &setupSecurityTLSForLte( $dirSimNetDeployer, $simName );
        }
    }
} else {
    if(lc "$switchToEnm" eq lc "YES") {
        if ( $simName =~ m/DG2/i
            || $simName =~ m/LTE.*PICO/i
            || $simName =~ m/ESAPC/i
            || $simName =~ m/MSRBS/i
            || $simName =~ m/EPG/i
            || $simName =~ m/TCU03/i
            || $simName =~ m/TCU04/i
            || $simName =~ m/C608/i
            || $simName =~ m/ECM/i
            || $simName =~ m/RAN-VNFM/i
            || $simName =~ m/EVNFM/i
            || $simName =~ m/VNF-LCM/i
            || $simName =~ m/TLS/i ) {
            print "INFO: Creating TLS for LTE MSRBS-v(Inc. WRAN sims)|WCDMA PRBS|CORE ESAPC|CORE EPG-SSR|CORE EPG-EVR|GSM TCU|CORE C608|CORE ECM"
                 ."LTE RNNODE|LTE VPP|LTE VRC|LTE EVNFM|LTE VNF-LCM|LTE VNFM  nodes \n";
            &setupSecurityTLS( $dirSimNetDeployer, $simName );
        }
        elsif ( $simName =~ /^LTE/i ||  $simName =~ /MGW/i || $simName =~ /-RBS/i || $simName =~ /^RNC.*UPGIND/i) {
            if ( $simName =~ /^((?!PICO).)*$/i
                && $simName =~ /^((?!RNNODE).)*$/i
                && $simName =~ /^((?!VPP).)*$/i
                && $simName =~ /^((?!VRC).)*$/i
                && $simName =~ /^((?!VTFRadioNode).)*$/i
                && $simName =~ /^((?!5GRadioNode).)*$/i
                && $simName =~ /^((?!VTIF).)*$/i ) {    # regular-expression-to-match-string-not-containing-a-word
                print "INFO: Creating SL2 for CPP LTE|MGW|RNC|RBS|RNC UPGIND nodes \n";
                &setupSecuritySL2ForLteAndMgw( $dirSimNetDeployer, $simName, $serverType );
            }
        }
    }
}

system("$NETSIM_INSTALL_SHELL < $dirSimNetDeployer/dat/$MML_MML");
if ($? != 0) {
    print "ERROR: Failed to execute system command ($NETSIM_INSTALL_SHELL < $dirSimNetDeployer/dat/$MML_MML)\n";
    exit(207);
}
close MML;

system("rm $dirSimNetDeployer/dat/$MML_MML");
if ($? != 0) {
    print "INFO: Failed to execute system command (rm $dirSimNetDeployer/dat/$MML_MML)\n";
}
