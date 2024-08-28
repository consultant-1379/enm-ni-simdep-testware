#!/usr/bin/perl -w
use strict;
use Expect;
use Getopt::Long();
use Net::OpenSSH;
use Cwd qw(abs_path);
use File::Basename;
use Config::Tiny;

###################################################################################
#     File Name    : setupSecurityMSTLS.pl
#     Author       : Sneha Srivatsav Arra and Fatih Onur
#     Description  : See usage below.
#     Date Created : 31 Mar 2016
###################################################################################
#
#----------------------------------------------------------------------------------
# Check if the scrip is executed as root user
#----------------------------------------------------------------------------------
my $user = `whoami`;
chomp($user);
my $expectedUser = 'root';
if ( $user ne $expectedUser ) {
    print "ERROR: Not $expectedUser user. Please execute the script as $expectedUser user\n";
    exit(201);
}

#----------------------------------------------------------------------------------
# Check if the script usage is right
#----------------------------------------------------------------------------------
my $USAGE =<<USAGE;
Descr: Set up TLS security on Radio Nodes.
    Usage:
        $0 <serverType> <master> <masterUser> <masterPass> <netsimName> <netsimUser> <netsimPass> <workingPath> <switchToEnm> <reApplyCerts>
        where:
            <serverType>  : Specifies the server type. Possible values: VM/VAPP.
            <master>      : Specifies the IP address of master server.
            <masterUser>  : Specifies the user name to login to master server.
            <masterPass>  : Specifies the password to login to master server.
            <netsimName>  : Specifies the IP address of netsim server.
            <netsimUser>  : Specifies the user name to login to netsim server.
            <netsimPass>  : Specifies the password to login to netsim server.
            <workingPath> : Specifies the working directory.
            <switchToEnm> : Specifies if the ENM is enabled or not. Possible values: yes/no.
            <reApplyCerts>: Jenkins parameter which specifies if re applying certs is yes/no. (Default Values is no).
        usage examples:
             $0 VAPP cloud-ms-1 root 12shroot netsim root shroot /tmp/LTE/simNetDeployer/16.2/ yes no
             $0 VAPP cloud-ms-1 root 12shroot netsim root shroot /tmp/LTE/simNetDeployer/16.2/ no yes
        dependencies:
              1. Should be able to access master server.
        Return Values:  202 -> Usage is incorrect
                        203 -> Could not open log file.
                        204 -> Failed to connect to a server via ssh.
                        206 -> File name does not exist.

USAGE

if ( @ARGV < 8 or @ARGV > 10 ) {
    print "ERROR: Invalid command line options. \n$USAGE";
    exit(202);
}
print "RUNNING: $0 @ARGV \n";

#
#----------------------------------------------------------------------------------
# Parameters and env variables
#----------------------------------------------------------------------------------
my $serverType        = "$ARGV[0]";
my $master            = "$ARGV[1]";
my $masterUser        = "$ARGV[2]";
my $masterPass        = "$ARGV[3]";
my $netsimName        = "$ARGV[4]";
my $netsimUser        = "$ARGV[5]";
my $netsimPass        = "$ARGV[6]";
my $workingPath       = "$ARGV[7]";
my $switchToEnm       = $ARGV[8];
my $reApplyCerts      = $ARGV[9];

$switchToEnm = "yes" if not defined $switchToEnm;
$reApplyCerts = "no" if not defined $reApplyCerts;

my $PWD = dirname(abs_path($0));
print "PWD:$PWD \n";
chomp($PWD);
my $SLEEP_TIME = 30;

my $CONFIG_FILE  = "conf.txt";
my $CONFIG_FILE_PATH ="$PWD/../conf/$CONFIG_FILE";
my $Config = Config::Tiny->new;
$Config = Config::Tiny->read($CONFIG_FILE_PATH);
# Reading properties
my $securitySL2 = $Config->{_}->{SETUP_SECURITY_SL2};
my $securityTLS = $Config->{_}->{SETUP_SECURITY_TLS};
#print "securitySL2:$securitySL2 \n";

#
#----------------------------------------------------------------------------------
# Set up log file
#----------------------------------------------------------------------------------
my $dateVar = `date +%F`;
chomp($dateVar);
my $timeVar = `date +%T`;
chomp($timeVar);
if (! open LOGFILEHANDLER, "+>>", "$workingPath/logs/setUpSecurityTLSLogs_$dateVar\_$timeVar.log") {
    print "ERROR: Could not open log file.\n";
    exit(203);
}
LogFiles(
"INFO: You can find real time execution logs of this script at $workingPath/logs/setUpSecurityTLSLogs_$dateVar\_$timeVar.log\n"
);

#
#----------------------------------------------------------------------------------
#SubRoutine to capture Logs
#----------------------------------------------------------------------------------
sub LogFiles {
    my $dateVar = `date +%F`;
    chomp($dateVar);
    my $timeVar = `date +%T`;
    chomp($timeVar);
    my $hostName = `hostname`;
    chomp($hostName);
    my $LogVar = $_[0];
    chomp($LogVar);
    my $substring = "ERROR:";
    if (index("$LogVar", $substring) != -1) {
        print LOGFILEHANDLER "$timeVar:<$hostName>: $LogVar in module $0 \n";
        print "$timeVar:<$hostName>: $LogVar in module $0 \n";
    }
    else {
        print LOGFILEHANDLER "$timeVar:<$hostName>: $LogVar\n";
        print "$timeVar:<$hostName>: $LogVar\n";
    }
}
#
#---------------------------------------------------------------------------------
#SubRoutine to set up TLS security in ENM mode
#---------------------------------------------------------------------------------
#
sub getTLSCertsFromEnmMs {
    LogFiles("INFO: Starting creation of security certs\n");
    my $masterServer = $_[0];

    my $false = 0; # false, 1 is true
    my $true  = 1;
    my $timeout = 90;

    #Creating SSH object
    my $hostMaster      = "$masterServer";
    my $userMaster      = "$masterUser";
    my $passwdMaster    = "$masterPass";
    my $sshMaster       = Net::OpenSSH->new(
        $hostMaster,
        user        => $userMaster,
        password    => $passwdMaster,
        master_opts => [ -o => "StrictHostKeyChecking=no" ]
    );

    #Creating SSH object
    my $hostNetsim   = "$netsimName";
    my $userNetsim   = "$netsimUser";
    my $passwdNetsim = "$netsimPass";
    my $sshNetsim    = Net::OpenSSH->new(
        $hostNetsim,
        user        => $userNetsim,
        password    => $passwdNetsim,
        master_opts => [ -o => "StrictHostKeyChecking=no" ]
    );

    #Variable declarations
    my $dirSimNetDeployer = "/tmp/$hostNetsim/Security/TLS/";
    my $cliAppScriptPath = '/opt/ericsson/enmutils/bin';

    my @cmdArrayMaster = "
rm -rf $dirSimNetDeployer;
mkdir -p $dirSimNetDeployer";
    ( my $outputMaster,my  $errputMaster ) =
      $sshMaster->capture2( { timeout => $timeout }, "@cmdArrayMaster" );
    if($sshMaster->error){
        LogFiles "ERROR: ssh create folder failed: " . $sshMaster->error . "\n";
        if ("$errputMaster") {
            LogFiles("$errputMaster");
        }
        exit(204);
    }
    my $gatewayDatMasterPath = "$workingPath/dat";
    LogFiles "INFO: Copying file:End-Entity.xml from $hostNetsim:$gatewayDatMasterPath to $hostMaster:$dirSimNetDeployer \n";
    LogFiles "INFO: Running cmd: scp $gatewayDatMasterPath/End-Entity.xml $userMaster\@$hostMaster:$dirSimNetDeployer \n";
    my $cmd =
      "scp $gatewayDatMasterPath/End-Entity.xml $userMaster\@$hostMaster:$dirSimNetDeployer";
    ( my $pty, my $pid ) = $sshNetsim->open2pty($cmd);
    if($sshNetsim->error){
       LogFiles "ERROR: unable to run remote command $cmd" . $sshNetsim->error . "\n";
       exit(204);
    }
    my $expect = Expect->init($pty);
    $expect->raw_pty(1);
    $expect->log_file( "$workingPath/logs/expect-copyXmlToMS.pm_log", "w" );

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
    my $fileName = "$workingPath/logs/expect-copyXmlToMS.pm_log";
    &append($fileName);

    LogFiles("INFO: Generating Entity on management server\n");
    LogFiles("INFO: Running cmd: cd $cliAppScriptPath; ./cli_app 'pkiadm etm -c -xf file:End-Entity.xml' $dirSimNetDeployer/End-Entity.xml\n");

    $cmd =
      "cd $cliAppScriptPath; ./cli_app 'pkiadm etm -c -xf file:End-Entity.xml' $dirSimNetDeployer/End-Entity.xml";
    ( $pty, $pid ) = $sshMaster->open2pty($cmd);
    if($sshMaster->error){
       LogFiles "ERROR: unable to run remote command $cmd" . $sshMaster->error . "\n";
       exit(204);
    }
    $expect = Expect->init($pty);
    $expect->raw_pty(1);
    $expect->log_file( "$workingPath/logs/expect-generateEntityLog", "w" );

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
    $fileName = "$workingPath/logs/expect-generateEntityLog";
    &append($fileName);
    sleep(5);

    LogFiles("INFO: Entity Certificate Generation in .P12 format with NO CSR\n");
    LogFiles("INFO: Running cmd: cd $cliAppScriptPath; ./cli_app 'pkiadm ctm EECert -gen -nocsr -en G2RBS_21 -f P12' --outfile=/$dirSimNetDeployer/G2RBS_21.p12 \n");
    $cmd =
      "cd $cliAppScriptPath; ./cli_app 'pkiadm ctm EECert -gen -nocsr -en G2RBS_21 -f P12' --outfile=/$dirSimNetDeployer/G2RBS_21.p12";
    ( $pty, $pid ) = $sshMaster->open2pty($cmd);
    if($sshMaster->error){
       LogFiles "ERROR: unable to run remote command $cmd" . $sshMaster->error . "\n";
       exit(204);
    }
    $expect = Expect->init($pty);
    $expect->raw_pty(1);
    $expect->log_file( "$workingPath/logs/expect-generateP12Cert_log", "w" );


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
    $fileName = "$workingPath/logs/expect-generateP12Cert_log";
    &append($fileName);

    LogFiles("INFO: Retrieve Entity Certificate in .pem format\n");
    LogFiles("INFO: Running cmd: cd $dirSimNetDeployer; openssl pkcs12 -nokeys -clcerts -passin pass:'' -in G2RBS_21.p12 -out cert_single.pem \n");
    $cmd =
      "cd $dirSimNetDeployer; openssl pkcs12 -nokeys -clcerts -passin pass:'' -in G2RBS_21.p12 -out cert_single.pem";
    ( $pty, $pid ) = $sshMaster->open2pty($cmd);
    if($sshMaster->error){
       LogFiles "ERROR: unable to run remote command $cmd" . $sshMaster->error . "\n";
       exit(204);
    }
    $expect = Expect->init($pty);
    $expect->raw_pty(1);
    $expect->log_file( "$workingPath/logs/expect-setupTLS_Cert_log", "w" );

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
    $fileName = "$workingPath/logs/expect-setupTLS_Cert_log";
    &append($fileName);

    my $errorHandler =`$PWD/../utils/checkForError.sh ERROR $fileName`; # 0 is error exist code and means success
    if ( $errorHandler != 0 ) {
        LogFiles(
            "WARNING: Could not retrieve Entity Certificiate in pem format due to above error.\n");
        LogFiles("##########################################\n");
        return $false;
    }


    LogFiles("INFO: Retrieve Entity Private Key in .pem format\n");
    LogFiles("INFO: Running cmd: cd $dirSimNetDeployer; openssl pkcs12 -in G2RBS_21.p12  -nocerts -nodes -passin pass:'' | openssl rsa -out keys.pem \n");
    $cmd =
      "cd $dirSimNetDeployer; openssl pkcs12 -in G2RBS_21.p12  -nocerts -nodes -passin pass:'' | openssl rsa -out keys.pem";
    ( $pty, $pid ) = $sshMaster->open2pty($cmd);
    if($sshMaster->error){
       LogFiles "ERROR: unable to run remote command $cmd" . $sshMaster->error . "\n";
       exit(204);
    }
    $expect = Expect->init($pty);
    $expect->raw_pty(1);
    $expect->log_file( "$workingPath/logs/expect-setupTLS_keys_log", "w" );

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
    $fileName = "$workingPath/logs/expect-setupTLS_keys_log";
    &append($fileName);

    my $pemCombinedCertCA = "$dirSimNetDeployer/CombinedCertCA.pem";
    LogFiles("INFO: CA Certificate generation in .PEM format\n");
    LogFiles("INFO: Running cmd: ./cli_app 'pkiadm ctm CACert -expcert -en  NE_OAM_CA -f PEM' --outfile=$pemCombinedCertCA \n");
    $cmd =
      "cd $cliAppScriptPath; ./cli_app 'pkiadm ctm CACert -expcert -en  NE_OAM_CA -f PEM' --outfile=$pemCombinedCertCA";
    (  $pty, $pid ) = $sshMaster->open2pty($cmd);
    if($sshMaster->error){
       LogFiles "ERROR: unable to run remote command $cmd" . $sshMaster->error . "\n";
       exit(204);
    }
    $expect = Expect->init($pty);
    $expect->raw_pty(1);
    $expect->log_file( "$workingPath/logs/expect-setupTLS_CA_log", "w" );

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
    $fileName = "$workingPath/logs/expect-setupTLS_CA_log";
    &append($fileName);
    LogFiles("INFO: Delete the host:$hostNetsim ssh-key from host:$hostMaster ssh's known_hosts file\n");
    LogFiles("INFO: Transferring pem to netsim Server under /netsim/netsimdir/Security/TLS folder \n");
    LogFiles("INFO: Transferring pem to netsim Server under /netsim/netsimdir/Security/SL2 folder \n");
    LogFiles("INFO: Running cmd: scp $dirSimNetDeployer/*pem root\@$netsimName:\/netsim\/netsimdir\/Security\/TLS \n");
    LogFiles("INFO: Running cmd: scp $dirSimNetDeployer/*pem root\@$netsimName:\/netsim\/netsimdir\/Security\/SL2 \n");

    $cmd ="
ssh-keygen -R $hostNetsim;
scp $dirSimNetDeployer/*pem root\@$netsimName:\/netsim\/netsimdir\/Security\/TLS;
scp $dirSimNetDeployer/*pem root\@$netsimName:\/netsim\/netsimdir\/Security\/SL2;
";

    ( $pty, $pid ) = $sshMaster->open2pty($cmd);
    if($sshMaster->error){
       LogFiles "ERROR: unable to run remote command $cmd" . $sshMaster->error . "\n";
       exit(204);
    }
    $expect = Expect->init($pty);
    $expect->raw_pty(1);
    $expect->log_file( "$workingPath/logs/expect-copyPemFromMS.pm_log", "w" );

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
                $expect->send("shroot\n");
                exp_continue;
            }
        ]
        #'-re', qr'[#>:] $' #' wait for shell prompt, then exit expect
    );
    $expect->soft_close();
    $fileName = "$workingPath/logs/expect-copyPemFromMS.pm_log";
    &append($fileName);


    return $true;
}
#---------------------------------------------------------------------------------
#Function call to append files.
#---------------------------------------------------------------------------------
sub append {
    my $fileName = $_[0];
    if (! -e $fileName) {
        LogFiles "ERROR: File $fileName doesn't exist. \n";
        exit(206);
    }
    if(! open APPENDFH, '<', "$fileName") {
        LogFiles "Error: Could not open $fileName\n";
        exit(203);
    }
    my @lines = <APPENDFH>;
    foreach (@lines) {

        #LogFiles("$_");
        print LOGFILEHANDLER "$_";
        print "$_";
    }
}

#---------------------------------------------------------------------------------
#Function call to copy pem files.
#---------------------------------------------------------------------------------
sub copyPem {
    my $dirSimNetDeployer = $_[0];
    my $timeout = 90;


    #Creating SSH object
    my $hostNetsim   = "$netsimName";
    my $userNetsim   = "$netsimUser";
    my $passwdNetsim = "$netsimPass";
    my $sshNetsim    = Net::OpenSSH->new(
        $hostNetsim,
        user        => $userNetsim,
        password    => $passwdNetsim,
        master_opts => [ -o => "StrictHostKeyChecking=no" ]
    );

    my $fromPathTLS = '/netsim/netsimdir/Security/TLS/';
    my $toPathTLS = "$dirSimNetDeployer" . '/Security/TLS/';
    my $cmd1 = "cp -v $fromPathTLS* $toPathTLS";

    my $fromPathSL2 = '/netsim/netsimdir/Security/SL2/';
    my $toPathSL2 = "$dirSimNetDeployer" . '/Security/SL2/';
    my $cmd2 = "cp -v $fromPathSL2* $toPathSL2";

    LogFiles("INFO: Copying security files from $fromPathTLS to $toPathTLS\n");
    LogFiles("INFO: Copying security files from $fromPathSL2 to $toPathSL2\n");
    LogFiles "INFO: Running cmd: $cmd1; $cmd2 \n";

    my ( $out, $err ) = $sshNetsim->capture( { timeout => $timeout }, "$cmd1;$cmd2" );
    if($sshNetsim->error){
        LogFiles "ERROR: ssh failed: " . $sshNetsim->error . "\n";
        if (defined $err) {
            LogFiles("ERROR: ssh failure ($err)");
        }
        exit(204);
    }
    print LOGFILEHANDLER "$out";
    print "$out";
}

#
#---------------------------------------------------------------------------------
#Function call to validate  pem files.
#---------------------------------------------------------------------------------
sub validatePem {
    my $workingPath = $_[0];
    my $timeout = 90;

    LogFiles("INFO: Validating Pem Files\n");

    #Creating SSH object
    my $hostNetsim   = "$netsimName";
    my $userNetsim   = "$netsimUser";
    my $passwdNetsim = "$netsimPass";
    my $sshNetsim    = Net::OpenSSH->new(
    $hostNetsim,
        user        => $userNetsim,
        password    => $passwdNetsim,
        master_opts => [ -o => "StrictHostKeyChecking=no" ]
    );

    my $filePath = '/netsim/netsimdir/Security/TLS/*';
    my $cmd = "du -sk $filePath";
    my ( @out, $err ) = $sshNetsim->capture( { timeout => $timeout }, "$cmd" );
    if($sshNetsim->error){
        LogFiles "ERROR: ssh failed: " . $sshNetsim->error . "\n";
        if ("$err") {
            LogFiles("$err");
        }
        exit(204);
    } else {
        LogFiles "INFO: Validate Pem Files Output is:\n @out \n";
    }

    my $boolean = 1;
    my $numOfPemFiles = @out;
    LogFiles("INFO: Number of pem files generated is $numOfPemFiles \n");
    if ($numOfPemFiles == 3){
        foreach (@out) {
            my @pathList = split('/', $_ );
            $pathList[0] =~ s/^\s+//;
            $pathList[0] =~ s/\s+$//;
            if($pathList[0] == 0) {
                chomp($pathList[$#pathList]);
                LogFiles("ERROR: Pem file $pathList[$#pathList] is not valid (FileSize=$pathList[0]K)\n");
                $boolean =  0; # Pem file is not valid
            }
        }
    } else {
        LogFiles("ERROR: Pem Files are missing !!! \n");
        $boolean = 0; # Pem File is not valid
    }
    return $boolean;
}

#---------------------------------------------------------------------------------
#SubRoutine to set up security on netsim
#---------------------------------------------------------------------------------
sub setupSecurityNetsim {
    my $workingPath = $_[0];
    my $switchToEnm = $_[1];
    my $serverType  = $_[2];
    my $reApplyCerts= $_[3];
    my $simName     = $_[4];
    my $neType      = $_[5];
    my $secType     = $_[6];

    my $timeout = 900;

    #Creating SSH object
    my $hostNetsim   = "$netsimName";
    my $userNetsim   = "$netsimUser";
    my $passwdNetsim = "$netsimPass";
    my $sshNetsim    = Net::OpenSSH->new(
        $hostNetsim,
        user        => $userNetsim,
        password    => $passwdNetsim,
        master_opts => [ -o => "StrictHostKeyChecking=no" ]
    );

    LogFiles("INFO: Setting up $secType Security on nodes\n");
    my @cmdArrayNetsim = "
sudo su -l netsim -c '$workingPath/bin/setupSecurity.pl $workingPath $switchToEnm $serverType $reApplyCerts $simName \"$neType\"'";
    my ( $outputNetsimN, $errputNetsimN ) =
      $sshNetsim->capture2( { timeout => $timeout }, "@cmdArrayNetsim" );

    print LOGFILEHANDLER "$outputNetsimN";
    print "$outputNetsimN";

    if($sshNetsim->error){
        LogFiles "ERROR: ssh failed: " . $sshNetsim->error . "\n";
        if (defined $errputNetsimN) {
            LogFiles("ERROR: ssh failure ($errputNetsimN) \n");
        }
        exit(204);
    }
}

#
#---------------------------------------------------------------------------
#Start only five nodes if a server Type is a vapp and all nodes if its VM
#---------------------------------------------------------------------------
#
sub startNodes {
    ( my $dirSimNetDeployer, my $simName, my $serverType, my $secType ) = @_;
    my @cmdArrayNetsim = '';
    my $timeout = 750;

    #Creating SSH object
    my $hostNetsim   = "$netsimName";
    my $userNetsim   = "$netsimUser";
    my $passwdNetsim = "$netsimPass";
    my $sshNetsim    = Net::OpenSSH->new(
        $hostNetsim,
        user        => $userNetsim,
        password    => $passwdNetsim,
        master_opts => [ -o => "StrictHostKeyChecking=no" ]
    );

    my $sleepingTime = 0; # changed due to SL1 enabled
    if (lc $secType eq lc "SL2") {
        LogFiles "INFO: Sleeping for $secType sim:$simName for $sleepingTime seconds before start the nodes \n";
        sleep($sleepingTime);
    }

    if (lc $serverType eq lc "VAPP" ) {
        @cmdArrayNetsim ="
sudo su -l netsim -c 'echo -e \".open $simName \n.select network \n.stop -parallel\" | /netsim/inst/netsim_pipe';
sudo su -l netsim -c '$workingPath/utils/startNes.pl -simName $simName -numOfNes 5 -numOfIpv6Nes 1'";
    } else {
          chdir("/netsim/simdepContents/");
          my $pwd =`pwd`;
          chomp($pwd);
          opendir(DIR, "$pwd");
          my $file= grep(/^Simnet_5K_CXP*.*\.content/,readdir(DIR));
          closedir(DIR);
          chdir($PWD);
          if ("$file") {
                @cmdArrayNetsim ="
sudo su -l netsim -c 'echo -e \".open $simName \n.select network \n.stop -parallel\" | /netsim/inst/netsim_pipe';
sudo su -l netsim -c '$workingPath/utils/startNes.pl -simName $simName -numOfNes 5 -numOfIpv6Nes 1'";

          }
          else {
               @cmdArrayNetsim = "
sudo su -l netsim -c '$workingPath/utils/startNes.pl -simName $simName -all'";
        }
    }
    my $errorStatus = 0; # 0 fail, 1 pass
    $sleepingTime = 0;
    my $numOfTry = 3;
    for (my $i=1; $i<=$numOfTry; $i++) {
        LogFiles "INFO: Attempting to start nodes of $simName ($i/$numOfTry), sleepingTime:$sleepingTime \n";
        sleep($sleepingTime);
        my ( $outputNetsimN, $errputNetsimN ) =
        $sshNetsim->capture2( { timeout => $timeout }, "@cmdArrayNetsim" );

        print LOGFILEHANDLER "$outputNetsimN";
        print "$outputNetsimN";

       if($sshNetsim->error){
            LogFiles "ERROR: ssh failed at startNodes subrotine ($i/$numOfTry): " . $sshNetsim->error . "\n";
            if (defined $errputNetsimN) {
                LogFiles("ERROR: ssh failure ($i/$numOfTry): ($errputNetsimN) \n");
            }
            LogFiles ("Simdep will try to start nodes again ($i/$numOfTry)\n") unless $i == 3;
            @cmdArrayNetsim = "sudo su -l netsim -c '$workingPath/utils/startNes.pl -simName $simName -all -one'";
        } else {
            if (index($outputNetsimN, "Error") != -1) {
                LogFiles("ERROR: Nodes are not started properly ($i/$numOfTry)\n");
                LogFiles ("Simdep will try to start nodes again ($i/$numOfTry)\n") unless $i == 3;
                @cmdArrayNetsim = "sudo su -l netsim -c '$workingPath/utils/startNes.pl -simName $simName -all -one'";
            }  elsif (index($outputNetsimN, "[Re]start NETSim by doing") != -1) {
                LogFiles("ERROR: Nodes are not started properly ($i/$numOfTry)\n");
                LogFiles("ERROR: Also NETsim has stopped or crashed ($i/$numOfTry)\n");
                LogFiles ("Exiting from simdep...");
                last;
            } elsif (index($outputNetsimN, "Terminating") != -1) {
                LogFiles("ERROR: Fatal erorr. Netsim crashed!");
                last;
            } else {
                my $sim = $simName . ".zip";
                print FH "$sim\n";
                $errorStatus = 1;
                last;
            }
        }
        $sleepingTime =  60 + ($i*$i) * 10;
    }
    if ($errorStatus != 1){
        exit(212);
    }
}

#
#---------------------------------------------------------------------------
#Removes a particular host key from SSH's known_hosts
#---------------------------------------------------------------------------
#
sub removeKnownHosts {
    my $host = $_[0];

    LogFiles "INFO: Delete the host:$host ssh-key from ssh's known_hosts file\n";
    system("ssh-keygen -R $host >/dev/null 2>&1");
    if($? != 0)
    {
        LogFiles "INFO: Failed to execute system command (ssh-keygen -R $host) \n";
    }
}


######################################################################
#MAIN
######################################################################
my $masterServer = "";
my $dirSimNetDeployer = $workingPath;
my $neType = '';

if ( lc $serverType eq lc "VAPP" ) {
    $masterServer = "cloud-ms-1";
} else {
    $masterServer = $master;
}
if (! open FH, "+>>", "$dirSimNetDeployer/dat/listSimulationPass.txt") {
        print "ERROR: Could not open file $dirSimNetDeployer/dat/listSimulationPass.txt.\n";
        exit(203);
}

#-----------------------------
if(lc $reApplyCerts eq lc "NO") {

    open listSim, "$dirSimNetDeployer/dat/listSimulation.txt" or die "Can't open $dirSimNetDeployer/dat/listSimulation.txt: $!\n" ;
    my @simNamesArray = <listSim>;
    chomp(@simNamesArray);
    close listSim;

    open listNeType, "$dirSimNetDeployer/dat/listNeType.txt" or die "Can't open $dirSimNetDeployer/dat/listNeType.txt: $!\n";
    my @simNeType = <listNeType>;
    chomp(@simNeType);
    close listNeType;

    my %mapSimToNeType;
    @mapSimToNeType{@simNamesArray} = @simNeType;

    my @tlsSimNamesArray =  grep {/DG2/ || /PICO/ || /ESAPC/ || /MSRBS/ || /EPG/ || /TCU/ || /C608/ || /ECM/ || /RNNODE/ || /VPP/ || /VRC/ || /RAN-VNFM/ || /EVNFM/ || /VNF-LCM/ } @simNamesArray;
    my @sl2SimNamesArray =  grep {!/DG2/ && !/PICO/ && !/VTFRadioNode/ && !/5GRadioNode/ && (/LTE/ || /MGW/i || /-RBS/i || /RNC.*UPGIND/i)} @simNamesArray;
    my $tlsSimNamesArraySize = @tlsSimNamesArray;
    my $sl2SimNamesArraySize = @sl2SimNamesArray;

    LogFiles("INFO: ALL sims: @simNamesArray \n");

    my $createSecurityCerts =  0;
    if (lc $securitySL2 eq lc "ON" ) {
        $createSecurityCerts += $sl2SimNamesArraySize;
    }
    if (lc $securityTLS eq lc "ON" ) {
        $createSecurityCerts += $tlsSimNamesArraySize;
    }

    if ($createSecurityCerts > 0) {

        @simNamesArray = ();
        if (lc $securityTLS eq lc "ON" ) {
            LogFiles("INFO: DG2:MSRBS-V2(TLS)|LTE-PICO:MSRBS-V3(TLS)|CORE-vSAPC:ESAPC(TLS)|"
                    . "CORE-EPG:EPG-SSR(TLS)|CORE-vEPG:EPG-SSR(TLS)|CORE-vEPG:EPG-EVR(TLS)|"
                    . "GSM-TCU03:TCU03(TLS)|GSM-TCU04:TCU04(TLS)|WRAN PICO:WCDMA PRBS(TLS)|"
                    . "CORE-C608:C608(TLS)|CORE-ECM:ECM(TLS)|LTE-RNNODE:RNNODE(TLS)|LTE-VPP:VPP(TLS)|LTE-VRC:VRC(TLS)|LTE-EVNFM:EVNFM(TLS)|LTE-VNFM:VNFM(TLS)|LTE-VNF:VNF-LCM(TLS) sims: @tlsSimNamesArray \n");
            push (@simNamesArray, @tlsSimNamesArray );
        }
        if (lc $securitySL2 eq lc "ON" ) {
            LogFiles("INFO: CPP:ERBS|MGw|RNC|RBS(SL2)|RNC UPGIND sims: @sl2SimNamesArray \n");
            push (@simNamesArray, @sl2SimNamesArray);
        }

        &removeKnownHosts($masterServer);
        if (! &getTLSCertsFromEnmMs($masterServer) ) {
            my $SLEEPING_TIME=120;
            LogFiles "INFO: Retrying one more time tls cert generation due to errors, sleepingTime=${SLEEPING_TIME}seconds \n";
            sleep($SLEEPING_TIME);
            &getTLSCertsFromEnmMs($masterServer);
        }

        #Validate pem files
        if ( &validatePem() ) {
            #Copy pem files under relevant folder within netsim
            &copyPem($workingPath);

            foreach my $sim (@simNamesArray) {

                $neType = $mapSimToNeType{$sim};
                chomp($neType);
                print "neType:$neType & simName:$sim\n";

                my @tempSimName = split( '\.zip', $sim );
                my $simName = $tempSimName[0];
                chomp($simName);
                if ( $neType =~ m/MSRBS-V/i
                    || $neType =~ m/ESAPC/i
                    || $neType =~ m/WCDMA PRBS/i
                    || ($neType =~ m/WCDMA RNC/i && $simName =~ m/MSRBS/i)
                    || $neType =~ m/EPG-SSR/i
                    || $neType =~ m/EPG-EVR/i
                    || $neType =~ m/TCU03/i
                    || $neType =~ m/C608/i
                    || $neType =~ m/TCU04/i
                    || $neType =~ m/ECM/i
                    || $neType =~ m/RAN-VNFM/i
                    || $neType =~ m/EVNFM/i
                    || $neType =~ m/VNF-LCM/i
                    || ($neType =~ m/RNNODE/i && $simName =~ m/TLS/i)
                    || ($neType =~ m/vPP/i && $simName =~ m/TLS/i)
                    || ($neType =~ m/vRC/i && $simName =~ m/TLS/i)  ) {
                    my $secType = "TLS";
                    LogFiles "DG2|LTE PICO|CORE-vSAPC|CORE EPG-SSR|CORE EPG-EVR|"
                             . "GSM-TCU|WRAN PICO|CORE-C608|CORE-ECM|LTE RNNODE|LTE VPP|LTE VRC|LTE EVNFM|LTE VNFM|LTE VNF-LCM"
                             . " sim is found:$simName. Applying TLS security.\n";
                    #Set up security on netsim
                    &setupSecurityNetsim($workingPath, $switchToEnm, $serverType, $reApplyCerts, $simName, $neType, $secType);
                    LogFiles("INFO: Starting Nodes after TLS is set up\n");
                    &startNodes( $dirSimNetDeployer, $simName, $serverType );
                }
                elsif ( lc $securitySL2 eq lc "ON"
                    && $neType =~ /^LTE ERBS/i
                    || $neType =~/mgw/i
                    || ($neType =~ /WCDMA RNC/i
                        && $simName =~ /-RBS/i)
                    || ($neType =~ /WCDMA RNC/i
                        && $simName =~ /-UPGIND/i)) {
                    my $secType = "SL2";
                    LogFiles "CPP ERBS|MGw|RNC|RBS|RNC UPGIND) sim is found:$simName. Applying SL2 security.\n";
                    #Set up security on netsim
                    &setupSecurityNetsim($workingPath, $switchToEnm, $serverType, $reApplyCerts, $simName, $neType, $secType);
                    LogFiles("INFO: Starting Nodes after SL2 is set up\n");
                    &startNodes( $dirSimNetDeployer, $simName, $serverType, $secType );
                }
            }
        } else {
            LogFiles "ERROR: Due to pem file errors security is not applied!\n";
        }

    } else {
         LogFiles "INFO: No security requried sims found OR security mode is OFF. Hence no security configuration has been applied.";
    }

} else {

    my $netsimDir = "/netsim/netsimdir";
    my $filePath = $netsimDir;
    opendir  (DIR, $filePath) || die "Can't open directory $filePath: $!";
    my @simNamesArray =  grep {!/mml/ || !/PICO/} grep {/CORE/ || /LTE/ || /MSRBS/ || /TCU/ || /RNC/ || /C608/ || /ECM/ || /RAN-VNFM/ || /EVNFM/ || /VNF-LCM/} grep {!/\.zip$/} grep { "$filePath/$_" } readdir(DIR);
    closedir DIR;
    chomp(@simNamesArray);
    my @tlsSimNamesArray =  grep {/DG2/ || /PICO/ || /ESAPC/ || /MSRBS/ || /EPG/ || /TCU/ || /C608/ || /ECM/ || /RNNODE/ || /VPP/ || /VRC/ || /RAN-VNFM/ || /EVNFM/ || /VNF-LCM/} @simNamesArray;
    my @sl2SimNamesArray =  grep {!/DG2/ && !/PICO/ && !/RNNODE/ && !/VPP/ && !/VRC/ && !/VTFRadioNode/ && !/5GRadioNode/ && !/RAN-VNFM/ && !/EVNFM/ && !/VNF-LCM/ && (/LTE/ || /MGW/i || /-RBS/i || /RNC.*UPGIND/i)} @simNamesArray;
    my $tlsSimNamesArraySize = @tlsSimNamesArray;
    my $sl2SimNamesArraySize = @sl2SimNamesArray;

    LogFiles("INFO: ALL sims: @simNamesArray \n");

    my $createSecurityCerts =  0;
    if (lc $securitySL2 eq lc "ON" ) {
        $createSecurityCerts += $sl2SimNamesArraySize;
    }
    if (lc $securityTLS eq lc "ON" ) {
        $createSecurityCerts += $tlsSimNamesArraySize;
    }

    if ($createSecurityCerts > 0) {

        @simNamesArray = ();
        if (lc $securityTLS eq lc "ON" ) {
            LogFiles("INFO: DG2:MSRBS-V2(TLS)|LTE-PICO:MSRBS-V3(TLS)|CORE-vSAPC:ESAPC(TLS)|CORE-EPG:EPG-SSR(TLS)|"
                    . "CORE-vEPG:EPG-SSR(TLS)|CORE-vEPG:EPG-EVR(TLS)|GSM-TCU03:TCU03(TLS)|GSM-TCU04:TCU04(TLS)|"
                    . " WRAN PICO:WCDMA PRBS(TLS)|CORE-C608:C608(TLS)|CORE-ECM:ECM(TLS)|LTE-RNNODE:RNNODE(TLS)|LTE-VPP:VPP(TLS)|LTE-VRC:VRC(TLS)|LTE-EVNFM:EVNFM(TLS)|LTE-VNFM:VNFM(TLS)|LTE-VNF:VNF-LCM(TLS) sims: @tlsSimNamesArray \n");
            push (@simNamesArray, @tlsSimNamesArray );
        }
        if (lc $securitySL2 eq lc "ON" ) {
            LogFiles("INFO: CPP:ERBS|MGw|RNC-UPGIND|RBS(SL2) sims: @sl2SimNamesArray \n");
            push (@simNamesArray, @sl2SimNamesArray);
        }

        &removeKnownHosts($masterServer);
        if (! &getTLSCertsFromEnmMs($masterServer) ){
            my $SLEEPING_TIME=120;
            LogFiles "INFO: Retrying one more time tls cert generation due to errors, sleepingTime=${SLEEPING_TIME}seconds \n";
            sleep($SLEEPING_TIME);
            &getTLSCertsFromEnmMs($masterServer);
        }

        #Validate Pem Files
        if ( &validatePem() ) {
            #Copy pem files under relevant folder within netsim
            &copyPem($workingPath);
            foreach my $sim (@simNamesArray) {
                #Set up security on netsim
                my @tempSimName = split( '\.zip', $sim );
                my $simName = $tempSimName[0];
                chomp($simName);
                if ( $simName =~ m/DG2/i
                    || $simName =~ /LTE.*PICO/
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
                    my $secType = "TLS";
                    LogFiles "DG2|LTE PICO|CORE-vSAPC|CORE EPG-SSR|CORE EPG-EVR|"
                             . "GSM-TCU|WRAN PICO|CORE-C608|CORE-ECM|LTE RNNODE|LTE VPP|LTE VRC|LTE EVNFM|LTE VNFM|LTE VNF-LCM "
                             ." sim is found:$simName. Applying TLS security.\n";
                    #Set up security on netsim
                    # print "neType:$neType \n";
                    &setupSecurityNetsim($workingPath, $switchToEnm, $serverType, $reApplyCerts, $simName, $neType, $secType);
                    LogFiles("INFO: Starting Nodes after TLS is set up\n");
                    &startNodes( $dirSimNetDeployer, $simName, $serverType );
                }
                elsif ( $simName =~ /^LTE/i || $simName =~/mgw/i || $simName =~ /-RBS/i || $simName =~ /^RNC.*UPGIND/i ) {
                     if ( $simName =~ /^((?!PICO).)*$/i
                         && $simName =~ /^((?!RNNODE).)*$/i
                         && $simName =~ /^((?!VPP).)*$/i
                         && $simName =~ /^((?!VRC).)*$/i
                         && $simName =~ /^((?!VTFRadioNode).)*$/i
                         && $simName =~ /^((?!5GRadioNode).)*$/i ) { #
                        my $secType = "SL2";
                        LogFiles "CPP ERBS|MGw|RNC|RBS|RNC UPGIND sim is found:$simName. Applying SL2 security.\n";
                        #Set up security on netsim
                        # print "neType:$neType \n";
                        &setupSecurityNetsim($workingPath, $switchToEnm, $serverType, $reApplyCerts, $simName, $neType, $secType);
                        LogFiles("INFO: Starting Nodes after SL2 is set up\n");
                        &startNodes( $dirSimNetDeployer, $simName, $serverType, $secType );
                     }
                }
            }
        }
    } else {
        LogFiles "INFO: No security requried sims found OR security mode is OFF. Hence no security configuration has been applied.";
    }
}

close FH;

