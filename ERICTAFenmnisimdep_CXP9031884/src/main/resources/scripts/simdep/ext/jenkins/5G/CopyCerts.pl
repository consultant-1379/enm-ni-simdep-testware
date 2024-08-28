#!/usr/bin/perl -w
use Expect;
use Config::Tiny;
use Net::OpenSSH;


my $simdepPath = "/netsim/zchaill";
my $certsPath = "/tmp/Security/TLS/";
my $masterPath = "/opt/ericsson/enmutils/bin/";

my $master =  "$ARGV[0]";
my $netsimName = "$ARGV[1]";
my $serverType = "$ARGV[2]";
my $Nodename = "$ARGV[3]";

my $timeout = 90;
my $masterServer = "0.0.0.0";

if ( lc $serverType eq lc "VAPP" ) {
    $masterServer = "cloud-ms-1";
    $netsimName = "netsim";
} else {
    $masterServer = $master;
}

 #Creating SSH object
 my $hostMaster      = "$masterServer";
 my $userMaster      = "root";
 my $passwdMaster    = "12shroot";
 my $sshMaster       = Net::OpenSSH->new(
     $hostMaster,
     user        => $userMaster,
     password    => $passwdMaster,
     master_opts => [ -o => "StrictHostKeyChecking=no" ]
 );

 #Creating SSH object
 my $hostNetsim   = "$netsimName";
 my $userNetsim   = "root";
 my $passwdNetsim = "shroot";
 my $sshNetsim    = Net::OpenSSH->new(
     $hostNetsim,
     user        => $userNetsim,
     password    => $passwdNetsim,
     master_opts => [ -o => "StrictHostKeyChecking=no" ]
 );

my $gatewayDatMasterPath = "$ARGV[4]";
#LogFiles "INFO: Copying file:End-Entity.xml from $hostNetsim:$gatewayDatMasterPath to $hostMaster:$dirSimNetDeployer \n";
#LogFiles "INFO: Running cmd: scp $gatewayDatMasterPath/End-Entity.xml $userMaster\@$hostMaster:$dirSimNetDeployer \n";
my $cmd =
  "scp $gatewayDatMasterPath/$ARGV[3].xml $userMaster\@$hostMaster:$masterPath";
#print "$cmd";
( my $pty, my $pid ) = $sshNetsim->open2pty($cmd);
#print "copied successfully";
if($sshNetsim->error){
 #  LogFiles "ERROR: unable to run remote command $cmd" . $sshNetsim->error . "\n";
   exit(204);
}
my $expect = Expect->init($pty);
$expect->raw_pty(1);
#$expect->log_file( "$workingPath/logs/expect-copyXmlToMS.pm_log", "w" );

# or multi-match on several spawned commands with callbacks,
# just like the Tcl version
$expect->expect(
    $timeout,
    [
        qr/\(yes\/no\)/ => sub {
            my $expect = shift;
            $expect->send("yes\n");
            exp_continue;
        }
    ],
    [
        qr/[Pp]assword/ => sub {
            my $expect = shift;
            $expect->send("12shroot\n");
            exp_continue;
        }
    ]

    #'-re', qr'[#>:] $' #' wait for shell prompt, then exit expect
);
$expect->soft_close();

 $cmd =
  "cd $masterPath; ./cli_app 'pkiadm etm -c -xf file:$Nodename.xml' $masterPath/$Nodename.xml";
print "$cmd\n";
( $pty, $pid ) = $sshMaster->open2pty($cmd);
if($sshMaster->error){
 #  LogFiles "ERROR: unable to run remote command $cmd" . $sshMaster->error . "\n";
   exit(204);
}
$expect = Expect->init($pty);
$expect->raw_pty(1);
#$expect->log_file( "$workingPath/logs/expect-generateEntityLog", "w" );
# or multi-match on several spawned commands with callbacks,
# just like the Tcl version
$expect->expect(
    $timeout,
    [
        qr/Username/ => sub {
            my $expect = shift;
            $expect->send("Administrator\r");
            exp_continue;
        }
    ],
    [
        qr/[Pp]assword/ => sub {
            my $expect = shift;
            $expect->send("TestPassw0rd\r");
            exp_continue;
            }
    ],
    '-re', qr'[~]# ]', #' wait for shell prompt, then exit expect
);
$expect->soft_close();


$cmd =
  "cd $masterPath; ./cli_app 'pkiadm ctm EECert -gen -nocsr -en $Nodename -f P12 --password eric123' --outfile=$masterPath/G2RBS_21.p12";
print "$cmd\n";
( $pty, $pid ) = $sshMaster->open2pty($cmd);
if($sshMaster->error){
 #  LogFiles "ERROR: unable to run remote command $cmd" . $sshMaster->error . "\n";
   exit(204);
}
$expect = Expect->init($pty);
$expect->raw_pty(1);
#$expect->log_file( "$workingPath/logs/expect-generateP12Cert_log", "w" );


# or multi-match on several spawned commands with callbacks,
# just like the Tcl version
$expect->expect(
    $timeout,
    [
        qr/Username/ => sub {
            my $expect = shift;
            $expect->send("Administrator\r");
            exp_continue;
        }
    ],
    [
        qr/[Pp]assword/ => sub {
            my $expect = shift;
            $expect->send("TestPassw0rd\r");
            exp_continue;
            }
    ],
    '-re', qr'[~]# ]', #' wait for shell prompt, then exit expect
);
$expect->soft_close();


$cmd =
  "cd $masterPath; openssl pkcs12 -nokeys -clcerts -passin pass:'eric123' -in G2RBS_21.p12 -out cert_single.pem";
print "$cmd\n";

( $pty, $pid ) = $sshMaster->open2pty($cmd);
if($sshMaster->error){
 #  LogFiles "ERROR: unable to run remote command $cmd" . $sshMaster->error . "\n";
   exit(204);
}
$expect = Expect->init($pty);
$expect->raw_pty(1);
#$expect->log_file( "$workingPath/logs/expect-setupTLS_Cert_log", "w" );

# or multi-match on several spawned commands with callbacks,
# just like the Tcl version
$expect->expect(
    $timeout,
    [
        qr/Username/ => sub {
            my $expect = shift;
            $expect->send("Administrator\r");
            exp_continue;
        }
    ],
    [
        qr/[Pp]assword/ => sub {
            my $expect = shift;
            $expect->send("TestPassw0rd\r");
            exp_continue;
            }
    ],
    '-re', qr'[~]# ]', #' wait for shell prompt, then exit expect

);
$expect->soft_close();


$cmd =
  "cd $masterPath; openssl pkcs12 -in G2RBS_21.p12  -nocerts -nodes -passin pass:'eric123' | openssl rsa -out keys.pem";
print "$cmd\n";
( $pty, $pid ) = $sshMaster->open2pty($cmd);
if($sshMaster->error){
 #  LogFiles "ERROR: unable to run remote command $cmd" . $sshMaster->error . "\n";
   exit(204);
}
$expect = Expect->init($pty);
$expect->raw_pty(1);
#$expect->log_file( "$workingPath/logs/expect-setupTLS_keys_log", "w" );

# or multi-match on several spawned commands with callbacks,
# just like the Tcl version
$expect->expect(
    $timeout,
    [
        qr/Username/ => sub {
            my $expect = shift;
            $expect->send("Administrator\r");
            exp_continue;
        }
    ],
    [
        qr/[Pp]assword/ => sub {
            my $expect = shift;
            $expect->send("TestPassw0rd\r");
            exp_continue;
            }
    ],
    '-re', qr'[~]# ]', #' wait for shell prompt, then exit expect

);
$expect->soft_close();


$cmd =
  "scp $userMaster\@$hostMaster:$masterPath/keys.pem  $gatewayDatMasterPath";
print "$cmd";
( $pty, $pid ) = $sshNetsim->open2pty($cmd);
if($sshNetsim->error){
 #  LogFiles "ERROR: unable to run remote command $cmd" . $sshNetsim->error . "\n";
   exit(204);
}
$expect = Expect->init($pty);
$expect->raw_pty(1);
#$expect->log_file( "$workingPath/logs/expect-copyXmlToMS.pm_log", "w" );

# or multi-match on several spawned commands with callbacks,
# just like the Tcl version
$expect->expect(
    $timeout,
    [
        qr/\(yes\/no\)/ => sub {
            $expect = shift;
            $expect->send("yes\n");
            exp_continue;
        }
    ],
    [
        qr/[Pp]assword/ => sub {
            $expect = shift;
            $expect->send("12shroot\n");
            exp_continue;
        }
    ]

    #'-re', qr'[#>:] $' #' wait for shell prompt, then exit expect
);
$expect->soft_close();

$cmd =
  "scp $userMaster\@$hostMaster:$masterPath/cert_single.pem  $gatewayDatMasterPath/";
print "$cmd";
( $pty, $pid ) = $sshNetsim->open2pty($cmd);
if($sshNetsim->error){
 #  LogFiles "ERROR: unable to run remote command $cmd" . $sshNetsim->error . "\n";
   exit(204);
}
$expect = Expect->init($pty);
$expect->raw_pty(1);
#$expect->log_file( "$workingPath/logs/expect-copyXmlToMS.pm_log", "w" );

# or multi-match on several spawned commands with callbacks,
# just like the Tcl version
$expect->expect(
    $timeout,
    [
        qr/\(yes\/no\)/ => sub {
            $expect = shift;
            $expect->send("yes\n");
            exp_continue;
        }
    ],
    [
        qr/[Pp]assword/ => sub {
            $expect = shift;
            $expect->send("12shroot\n");
            exp_continue;
        }
    ]

    #'-re', qr'[#>:] $' #' wait for shell prompt, then exit expect
);
$expect->soft_close();

$cmd =
  "cd $masterPath; rm -f $Nodename.xml; rm -f cert_single.pem; rm -f keys.pem; rm -f G2RBS_21.p12";
( $pty, $pid ) = $sshMaster->open2pty($cmd);
if($sshMaster->error){
  # LogFiles "ERROR: unable to run remote command $cmd" . $sshMaster->error . "\n";
   exit(204);
}
$expect = Expect->init($pty);
$expect->raw_pty(1);
#$expect->log_file( "$workingPath/logs/expect-generateEntityLog", "w" );

# or multi-match on several spawned commands with callbacks,
# just like the Tcl version
$expect->expect(
    $timeout,
    [
        qr/Username/ => sub {
            my $expect = shift;
            $expect->send("root\r");
            exp_continue;
        }
    ],
    [
        qr/[Pp]assword/ => sub {
            my $expect = shift;
            $expect->send("12shroot\r");
            exp_continue;
            }
    ],
    '-re', qr'[~]# ]', #' wait for shell prompt, then exit expect
);
$expect->soft_close();
