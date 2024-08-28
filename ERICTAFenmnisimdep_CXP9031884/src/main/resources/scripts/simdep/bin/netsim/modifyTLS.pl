#!/usr/bin/perl -w

my $simName = $ARGV[0];
my $Nodename = $ARGV[1];


sub setupSecurityTLS {
    ( my $dirSimNetDeployer, my $simName , my $Nodename ) = @_;

    &createTLS( $dirSimNetDeployer, $simName , $Nodename );

    print MML <<"END";
.open $simName
.select $Nodename
.stop
.set ssliop yes $Nodename
.set save
END
}
# -----------------------------------------------------------------------
# Creating TLS Certs on NETSim
# -----------------------------------------------------------------------
sub createTLS {

     ( my $dirSimNetDeployer, my $simName , my $Nodename ) = @_;
     print "INFO: Setting up TLS security\n";
     my $certPem   = "$dirSimNetDeployer/cert_single.pem";
     my $caCertPem = "$dirSimNetDeployer/s_cacert.pem";
     my $kepPem    = "$dirSimNetDeployer/keys.pem";
 print MML <<"END";
 .open $simName
 .setssliop createormodify $Nodename
 .setssliop description $Nodename
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


my $dirSimNetDeployer = "$ARGV[2]";

$RAN_MML="RAN.mml";
open MML, "+>> $dirSimNetDeployer/$RAN_MML";


&setupSecurityTLS ( $dirSimNetDeployer , $simName , $Nodename );

system("/netsim/inst/netsim_shell < $dirSimNetDeployer/$RAN_MML");
system("rm $dirSimNetDeployer/$RAN_MML");
