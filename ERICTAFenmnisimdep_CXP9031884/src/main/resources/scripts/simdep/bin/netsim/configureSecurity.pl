#!/usr/bin/perl -w
use strict;

###################################################################################
#     File Name   : configureSecurity.pl
#     Author      : Sneha Srivatsav
#     Description : See usage below.
###################################################################################
#
#----------------------------------------------------------------------------------
#Check if the script is executed as netsim user
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
        $0 <workingPath> <secType> <simName> <neType>

        where:
            <workingPath>         : Specifies working directory
            <secType>             : Specifies type of Security (TLS/SL2)
            <simName>             : Specifies simName for which TLS has to be set up.
            <neType>              : Specifies neType of the sim.

        usage examples:
             $0 /tmp/LTE/simNetDeployer/ TLS yes no LTE15B-V13x80_16A-V17x80-5K-DG2-FDD-LTE08 MSRBS-V2
             $0 /tmp/LTE/simNetDeployer/ SL2 yes yes LTE15B-V13x80_16A-V17x80-5K-DG2-FDD-LTE08 MSRBS-V2

        dependencies:
              1. Simulations must be already rolled in the netsim server.

        Return Values: 201 -> Not a netsim user.
                       202 -> Usage is incorrect.
                       207 -> Failed to execute system command.
USAGE
if ( @ARGV < 4 or @ARGV > 5 ) {
    print "$USAGE";
    exit(202);
}
print "RUNNING: $0 @ARGV \n";

#
#----------------------------------------------------------------------------------
#Variables
#----------------------------------------------------------------------------------
my $NETSIM_INSTALL_SHELL = "/netsim/inst/netsim_pipe";
my $netsimDir            = "/netsim/netsimdir";
my $dirSimNetDeployer    = "$ARGV[0]";
my $secType              = "$ARGV[1]";
my $simName              = $ARGV[2];
my $neType               = $ARGV[3];


my @neType = split(/:/, $neType);
$neType = join(' ', @neType);
my $secDef = $simName;
$secDef =~ s/[^a-zA-Z0-9,]//g;

#
#----------------------------------------------------------------------------------
#Set up TLS security.
#----------------------------------------------------------------------------------
sub setupSecurityTLS {
    ( my $netsimDir, my $simName ) = @_;

    &createTLS( $netsimDir, $simName );

    print MML <<"END";

.open $simName
.selectnocallback network
.stop -parallel
.set ssliop no->yes $secDef
.set save
END
}
#-----------------------------------------------------------
#Set up security for ECM nodes with MSC combination
#----------------------------------------------------------
#set up security for BSC and DG2 nodes
#-------------------------------------------------------------
sub setupSecurityTLSForGSM {
    ( my $netsimDir, my $simName ) = @_;
 my $hasDG2 =
      `echo ".selectnetype MSRBS-V2*" | /netsim/inst/netsim_pipe -sim $simName`;
 my $hasLTEBSC =
      `echo ".selectnetype LTE BSC*" | /netsim/inst/netsim_pipe -sim $simName`;
 my $hasLTEvBSC =
      `echo ".selectnetype LTE vBSC*" | /netsim/inst/netsim_pipe -sim $simName`;
 my $hasECM =
     `echo ".selectnetype ECM*" | /netsim/inst/netsim_pipe -sim $simName`;
 my $hasLTEMSC =
     `echo ".selectnetype LTE MSC*" | /netsim/inst/netsim_pipe -sim $simName`;
 my $hasLTECTC =
     `echo ".selectnetype LTE CTC*" | /netsim/inst/netsim_pipe -sim $simName`;
 my $hasLTEvMSC =
     `echo ".selectnetype LTE vMSC*" | /netsim/inst/netsim_pipe -sim $simName`;
     if ( $hasECM =~ "OK" || $hasDG2 =~ "OK" || $hasLTEBSC =~ "OK" || $hasLTEMSC =~ "OK" || $hasLTECTC =~ "OK" || $hasLTEvMSC =~ "OK" ) {
    &createTLS( $netsimDir, $simName );
    }
if ( $hasECM =~ "nodedown" ) {
        print "ERROR: Coordinator down, unable to check the ECM nodes\n"; }
    elsif ( $hasECM =~ "OK" ) {
print MML << "END"
.open $simName
.selectnetype ECM*
.stop -parallel
.set ssliop yes $secDef
.set save
.start -parallel
END
}
    if ( $hasLTEBSC =~ "OK" ) {
print MML << "END"
.open $simName
.selectnetype LTE BSC*
.stop -parallel
.set ssliop yes $secDef
.set save
END
    }
    if ( $hasLTEvBSC =~ "OK" ) {
print MML << "END"
.open $simName
.selectnetype LTE vBSC*
.stop -parallel
.set ssliop yes $secDef
.set save
END
    }
    if ( $hasLTEMSC =~ "OK" ) {
print MML << "END"
.open $simName
.selectnetype LTE MSC*
.stop -parallel
.set ssliop yes $secDef
.set save
END
    }
    if ( $hasLTECTC =~ "OK" ) {
    print MML << "END"
.open $simName
.selectnetype LTE CTC*
.stop -parallel
.set ssliop yes $secDef
.set save
END
    }
    if ( $hasLTEvMSC =~ "OK" ) {
       print MML << "END"
.open $simName
.selectnetype LTE vMSC*
.stop -parallel
.set ssliop yes $secDef
.set save
END
    }
    if ( $hasDG2 =~ "OK" ) {
 print MML << "END"
.open $simName
.selectnetype MSRBS-V2*
.stop -parallel
.set ssliop yes $secDef
.set save
END
   }
    else {
        print "INFO: There are no RadioNodes or ECM or BSC nodes in the simulation. So no TLS will be applied\n";
    }
}
#---------------------------------------------------------------------------------------
#set TLS security for HLR
#---------------------------------------------------------------------------------------
sub setUpSecurityTLSForHLR {
    ( my $netsimDir, my $simName ) = @_;
 my $hasHLR =
      `echo ".selectnetype LTE HLR*" | /netsim/inst/netsim_pipe -sim $simName`;
 my $hasvHLR =
      `echo ".selectnetype LTE vHLR*" | /netsim/inst/netsim_pipe -sim $simName`;
      if ( $hasHLR =~ "OK" || $hasvHLR =~ "OK" ) {
    &createTLS( $netsimDir, $simName );
    }
    if ( $hasHLR =~ "OK" ) {
    print MML << "END"
.open $simName
.selectnetype LTE HLR*
.stop -parallel
.set ssliop yes $secDef
.set save
END
    }
    elsif ( $hasvHLR =~ "OK" ) {
        print MML << "END"
.open $simName
.selectnetype LTE vHLR*
.stop -parallel
.set ssliop yes $secDef
.set save
END
    }
    else {
    print "INFO: There are no HLR or vHLR nodes in $simName\n";
    }
}
#---------------------------------------------------------------------------------------
#Create TLS Security
#---------------------------------------------------------------------------------------
sub createTLS {

    ( my $netsimDir, my $simName ) = @_;
    print "INFO: Setting up TLS security\n";
    my $certPem   = "$dirSimNetDeployer/certs/s_cert.pem";
    my $caCertPem = "$dirSimNetDeployer/certs/s_cacert.pem";
    my $kepPem    = "$dirSimNetDeployer/certs/s_key.pem";
print MML <<"END";
.open $simName
.setssliop createormodify $secDef
.setssliop description $secDef
.setssliop clientcertfile $certPem
.setssliop clientcacertfile $caCertPem
.setssliop clientkeyfile $kepPem
.setssliop clientpassword test1234
.setssliop clientverify 0
.setssliop clientdepth 1
.setssliop servercertfile $certPem
.setssliop servercacertfile $caCertPem
.setssliop serverkeyfile $kepPem
.setssliop serverpassword test1234
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

    ( my $netsimDir, my $simName ) = @_;
    print "INFO: Setting up TLS security\n";
    my $certPem   = "$netsimDir/Security/SL2/s_cert.pem";
    my $caCertPem = "$netsimDir/Security/SL2/s_cacert.pem";
    my $kepPem    = "$netsimDir/Security/SL2/s_key.pem";
    print MML << "END";
.open $simName
.setssliop createormodify $secDef
.setssliop description $secDef
.setssliop clientcertfile $certPem
.setssliop clientcacertfile $caCertPem
.setssliop clientkeyfile $kepPem
.setssliop clientpassword test1234
.setssliop clientverify 0
.setssliop clientdepth 1
.setssliop servercertfile $certPem
.setssliop servercacertfile $caCertPem
.setssliop serverkeyfile $kepPem
.setssliop serverpassword test1234
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
.set ssliop no->yes $secDef
.set save
END
}

#
#----------------------------------------------------------------------------------
#Set up SL2 security for LTE and MGw nodes
#----------------------------------------------------------------------------------
sub setupSecuritySL2ForLteAndMgw {
    ( my $netsimDir, my $simName ) = @_;

    &createSL2( $netsimDir, $simName );
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

if ( $secType =~ /TLS/i) {
      print "INFO: Creating TLS for $simName nodes \n";
      if ( $simName =~ m/cell/i || $simName =~ m/BSC/i || $simName =~ m/MSC/i )
      {
       &setupSecurityTLSForGSM( $netsimDir, $simName );
      }
      elsif ( $simName =~ m/HLR/i )
      {
      &setUpSecurityTLSForHLR( $netsimDir, $simName );
      }
      else
      {
       &setupSecurityTLS( $netsimDir, $simName );
      }
   }
 elsif ( $secType =~ /SL2/i) {
        print "INFO: Creating SL2 for $simName nodes \n";
        &setupSecuritySL2ForLteAndMgw( $netsimDir, $simName );
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
