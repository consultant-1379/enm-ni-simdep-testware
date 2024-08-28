#!/usr/bin/perl -w
use strict;

###################################################################################
#     File Name   : setupSecutiyOSS.pl
#     Version     : 2016.04.23
#     Author      : Fatih Onur, Sneha
#     Description : Sets up TLS / SL2 / SL3 security for OSS
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
    Usage:
        $0 <workingPath> <switchToEnm> <serverType>

        where:
            <workingPath>         : Specifies working directory
            <switchToEnm>         : Specifies if the mode is ENM or OSSRC. Possible values: ON/OFF.
            <serverType>          : Specifies if the server type. Possible values: vapp/vm.

        usage examples:
             $0 /tmp/LTE/simNetDeployer/ on vapp
             $0 /tmp/LTE/simNetDeployer/ off vm

        dependencies:
              1. Simulations must be already rolled in the netsim server.

        Return Values: 201 -> Not a netsim user.
                       202 -> Usage is incorrect.
                       207 -> Failed to execute system command.
USAGE

if ( @ARGV < 3 or @ARGV > 4 ) {
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

#
#----------------------------------------------------------------------------------
#Set up TLS security.
#----------------------------------------------------------------------------------
sub setupSecurityTLS {
    ( my $dirSimNetDeployer, my $simName ) = @_;

    &createTLS( $dirSimNetDeployer, $simName );

    print MML <<"END"
.open $simName
.selectnocallback network
.stop -parallel
.set ssliop yes TLS
.set save
.start -parallel
END
}

#
#----------------------------------------------------------------------------------
#Set up TLS security for LTE nodes
#----------------------------------------------------------------------------------
sub setupSecurityTLSForLte {
    ( my $dirSimNetDeployer, my $simName ) = @_;

    &createTLS( $dirSimNetDeployer, $simName );

    print MML <<"END"
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
#Set up TLS Security for PICO nodes
#-------------------------------------------------------------------------------------
sub setupSecurityTLSForPico {
    ( my $dirSimNetDeployer, my $simName ) = @_;

    my $hasPico =
      `echo ".selectnetype PRBS*" | /netsim/inst/netsim_pipe -sim $simName`;
    if ( $hasPico =~ "OK" ) {
        &createTLS( $dirSimNetDeployer, $simName );
            print MML <<"END"
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
#Set up TLS Security for WRAN DG2 nodes
#-------------------------------------------------------------------------------------
sub setupSecurityTLSForDG2 {
    ( my $dirSimNetDeployer, my $simName, my $serverType ) = @_;

    my $hasDG2 =
      `echo ".selectnetype MSRBS-V2*" | /netsim/inst/netsim_pipe -sim $simName`;
    if ( $hasDG2 =~ "OK" ) {
        &createTLS( $dirSimNetDeployer, $simName );
        print MML <<END
.open $simName
.selectnetype MSRBS-V2*
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
    print MML <<END
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


#
#--------------------------------------------------------------------------------------
#Main
#--------------------------------------------------------------------------------------
#
#Define NETSim MO file and Open file in append mode
#----------------------------------------------------------------------------------
my $MML_MML = "MML.mml";
open MML, "+>>$dirSimNetDeployer/dat/$MML_MML";

#----------------------------------------------------------------------------------
#
open listSim, "$dirSimNetDeployer/dat/listSimulation.txt" or die;
my @simNamesArray = <listSim>;
close listSim;

#
#
open listNeType, "$dirSimNetDeployer/dat/listNeType.txt" or die;
my @simNeType = <listNeType>;
close listNeType;

my %mapSimToNeType;
@mapSimToNeType{@simNamesArray} = @simNeType;


#---------------------------------------------------
#Start of Rollout functionality to individual sims
#---------------------------------------------------
foreach my $sim (@simNamesArray) {
    my $neType = $mapSimToNeType{$sim};
    chomp($neType);
    chomp($sim);
    my @tempSimName = split( '\.zip', $sim );
    my $simName = $tempSimName[0];
    if(lc "$switchToEnm" eq lc "YES") {
        if ( $neType =~ m/MSRBS/i ) {
            print "INFO: Creating TLS for LTE nodes\n";
            &setupSecurityTLSForDG2( $dirSimNetDeployer, $simName );
            &startNodes( $dirSimNetDeployer, $simName, $serverType );
        }
    }
    else {
        if (   $neType =~ m/^WPP SGSN/i
            || $neType =~ /H2S/i
            || $neType =~ /MTAS/i
            || $neType =~ /cscf/i
            || $neType =~ /esapv/i
            || $neType =~ /prbs/i
            || $neType =~ /TCU03/i
            || $neType =~ /msrbs/i )
        {
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
}


system("$NETSIM_INSTALL_SHELL < $dirSimNetDeployer/dat/$MML_MML");
if ($? != 0)
{
    print "ERROR: Failed to execute system command ($NETSIM_INSTALL_SHELL < $dirSimNetDeployer/dat/$MML_MML)\n";
    exit(207);
}
close MML;
system("rm $dirSimNetDeployer/dat/$MML_MML");
if ($? != 0)
{
    print "INFO: Failed to execute system command (rm $dirSimNetDeployer/dat/$MML_MML)\n";
}

