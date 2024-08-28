#!/usr/bin/perl -w
use strict;
use Expect;
use Getopt::Long();
use Net::OpenSSH;
use Cwd qw(abs_path);
use File::Basename;
use Config::Tiny;

###################################################################################
#     File Name    : invokeSecurity.pl
#     Author       : Sneha Srivatsav Arra
#     Description  : See usage below.
#     Date Created : 14 Mar 2017
###################################################################################
#
#----------------------------------------------------------------------------------
# Check if the script is executed as root user
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
        $0 <serverType> <netsimName> <netsimUser> <netsimPass> <workingPath> <securityTLS> <securitySL2> <switchToRv>
        where:
            <serverType>  : Specifies the server type. Possible values: VM/VAPP.
            <netsimName>  : Specifies the IP address of netsim server.
            <netsimUser>  : Specifies the user name to login to netsim server.
            <netsimPass>  : Specifies the password to login to netsim server.
            <workingPath> : Specifies the working directory.
            <securityTLS> : Specifies TLS security required or not
            <securitySL2> : Specifies SL2 security required or not
            <switchToRv>  : Specifies RV or not
        usage examples:
             $0 VAPP netsim root shroot /tmp/LTE/simNetDeployer/16.2/
             $0 VAPP netsim root shroot /tmp/LTE/simNetDeployer/16.2/
        dependencies:
              1. Sim must be already be rolled on the netsim server.
        Return Values:  202 -> Usage is incorrect
                        203 -> Could not open log file.
                        204 -> Failed to connect to a server via ssh.
                        206 -> File name does not exist.

USAGE

if ( @ARGV < 8 or @ARGV > 9 ) {
    print "ERROR: Invalid command line options. \n$USAGE";
    exit(202);
}
print "RUNNING: $0 @ARGV \n";

#
#----------------------------------------------------------------------------------
# Parameters and env variables
#----------------------------------------------------------------------------------
my $serverType        = "$ARGV[0]";
my $netsimName        = "$ARGV[1]";
my $netsimUser        = "$ARGV[2]";
my $netsimPass        = "$ARGV[3]";
my $workingPath       = "$ARGV[4]";
my $securityTLS       = "$ARGV[5]";
my $securitySL2       = "$ARGV[6]";
my $switchToRv        = "$ARGV[7]";

my $PWD = dirname(abs_path($0));
print "PWD:$PWD \n";
chomp($PWD);
my $SLEEP_TIME = 30;

#my $CONFIG_FILE  = "conf.txt";
#my $CONFIG_FILE_PATH ="$PWD/../conf/$CONFIG_FILE";
#my $Config = Config::Tiny->new;
#$Config = Config::Tiny->read($CONFIG_FILE_PATH);
# Reading properties
#my $securitySL2 = $Config->{_}->{SETUP_SECURITY_SL2};
#my $securityTLS = $Config->{_}->{SETUP_SECURITY_TLS};
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
#SubRoutine to set up security on netsim
#---------------------------------------------------------------------------------
sub setupSecurityNetsim {
    my $workingPath = $_[0];
    my $simName     = $_[1];
    my $neType      = $_[2];
    my $secType     = $_[3];

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
     my @cmdArrayNetsim = "sudo su -l netsim -c '$workingPath/bin/configureSecurity.pl $workingPath $secType $simName \"$neType\"'";
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


sub setupSecurity5G {
    my $workingPath = $_[0];
    my $simName     = $_[1];
    my $neType      = $_[2];
    my $secType     = $_[3];

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
     my @cmdArrayNetsim = "sudo su -l netsim -c '$workingPath/bin/newCerts.sh $simName $workingPath/bin'";
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
    my $timeout = 600;

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
sudo su -l netsim -c '$workingPath/utils/startNes.pl -simName $simName -numOfNes 0 -numOfIpv6Nes 0'";
    } else {
        chdir("/netsim/simdepContents/");
        my $pwd =`pwd`;
        chomp($pwd);
        opendir(DIR, "$pwd");
        my $file= grep(/^Simnet_1_8K_CXP*.*\.content/,readdir(DIR));
        closedir(DIR);
        chdir($PWD);
        if ("$file") {
            @cmdArrayNetsim ="
sudo su -l netsim -c 'echo -e \".open $simName \n.select network \n.stop -parallel\" | /netsim/inst/netsim_pipe';
sudo su -l netsim -c '$workingPath/utils/startNes.pl -simName $simName -numOfNes 2 -numOfIpv6Nes 1'";
        } else {
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
            #@cmdArrayNetsim = "sudo su -l netsim -c '$workingPath/utils/startNes.pl -simName $simName -all -one'";
        } else {
            if (index($outputNetsimN, "Error") != -1) {
                LogFiles("ERROR: Nodes are not started properly ($i/$numOfTry)\n");
                LogFiles ("Simdep will try to start nodes again ($i/$numOfTry)\n") unless $i == 3;
                #@cmdArrayNetsim = "sudo su -l netsim -c '$workingPath/utils/startNes.pl -simName $simName -all -one'";
            }  elsif (index($outputNetsimN, "[Re]start NETSim by doing") != -1) {
                LogFiles("ERROR: Nodes are not started properly ($i/$numOfTry)\n");
                LogFiles("ERROR: Also NETsim has stopped or crashed ($i/$numOfTry)\n");
                LogFiles ("Exiting from simdep...");
                last;
            } elsif (index($outputNetsimN, "Terminating") != -1) {
                LogFiles("ERROR: Fatal error. Netsim crashed!");
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

my $dirSimNetDeployer = $workingPath;
my $neType = '';

if (! open FH, "+>>", "$dirSimNetDeployer/dat/listSimulationPass.txt") {
        print "ERROR: Could not open file $dirSimNetDeployer/dat/listSimulationPass.txt.\n";
        exit(203);
}
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
my @tlsSimNamesArray =  grep { (/DG2/ || /PICO/ ||  /Yang.*vCU/ || /Yang.*vDU/ || /Yang.*RDM/ || /vDU.*5G134/ || /vDU.*5G116/ || /ESAPC/ || /VSAPC/ || /MSRBS/ || /EPG/ || /TCU/ || /C608/ || /ECM/ || /ECEE/ || /RNNODE/ || /vRM/ || /vRSM/  || /vPP/ || /vRC/ || /RAN-VNFM/ || /EVNFM/ || /VNF-LCM/ || /VTFRadioNode/ || /5GRadioNode/ || /VTIF/ || /vTIF/ || /vSD/ || /SpitFire.*17B/ || /SpitFire.*18A/ || /RNC.*PRBS/ || /Router6274/ || /Router6672/ || /Router6673/ || /Router6675/ || /Router6273/ || /Router6371/ || /Router6471-1/ || /Router6471-2/ || /Router6676/ || /Router6678/ || /Router6671/ || /FrontHaul-6020/ || /FrontHaul-6650/ || /FrontHaul-6000/ || /CONTROLLER6610/ || /MSCv/ || /BSC/ || /gNodeBRadio/ || /HLR/ || /MSC/ || /vCU.*5G130/ || /vCU.*5G131/ || /SCU/ || /CSCF/ || /MTAS/ || /vBGF/ || /O1/ || /ORU/ ) && ! /NRAT-SSH/ && ! /ERS-SN/ || (/ESC/) } @simNamesArray;
my @sl2SimNamesArray =  grep {!/DG2/ && !/PICO/ && !/RNNODE/ && !/vPP/ && !/vRM/ && !/vRSM/  && !/vRC/ && !/RAN-VNFM/ && !/EVNFM/ && !/VNF-LCM/ && !/VTFRadioNode/ && !/5GRadioNode/ && !/VTIF/ && !/vTIF/ && !/vSD/ && !/HP-NFVO/&& !/RNC.*PRBS/&&(/LTE/ || /MGW/i || /MRS/i || /-RBS/i || /RNC.*UPGIND/i)} @simNamesArray;
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
                . "GSM-TCU03:TCU03(TLS)|GSM-TCU04:TCU04(TLS)|WRAN PICO:WCDMA PRBS(TLS)|BSC:LTE BSC(TLS)"
                . "CORE-C608:C608(TLS)|CORE-ECM:ECM(TLS)|LTE-RNNODE:RNNODE(TLS)|LTE-VPP:VPP(TLS)|LTE-VRC:VRC(TLS)|LTE-EVNFM:EVNFM(TLS)|LTE-VNFM:VNFM(TLS)|LTE-VNF:VNF-LCM(TLS)|CORE-SpitFire:SpitFire(TLS) sims: @tlsSimNamesArray \n");
        push (@simNamesArray, @tlsSimNamesArray );
    }
    if (lc $securitySL2 eq lc "ON" ) {
        LogFiles("INFO: CPP:ERBS|MGw|RNC|RBS(SL2)|RNC UPGIND sims: @sl2SimNamesArray \n");
        push (@simNamesArray, @sl2SimNamesArray);
    }
    foreach my $sim (@simNamesArray) {
        $neType = $mapSimToNeType{$sim};
        chomp($neType);
        my $nodeVersion = `echo $neType | cut -d ' ' -f3 | sed 's/[A-Z]//g' | sed 's/-//g'`;
        print "neType:$neType & simName:$sim\n";

        my @tempSimName = split( '\.zip', $sim );
        my $simName = $tempSimName[0];
        chomp($simName);
        if ( ($neType =~ m/MSRBS-V/i && (( $simName !~ m/NRAT-NR01/i || lc "$switchToRv" eq lc "yes") || $nodeVersion < 1932))
            || $neType =~ m/PRBS/i
            || $neType =~ m/MSC/i
            || $neType =~ m/ESAPC/i
	    || $neType =~ m/CONTROLLER6610/i
            || $neType =~ m/VSAPC/i
            || $neType =~ m/WCDMA PRBS/i
            ||( $neType =~ m/WCDMA RNC/i &&  $simName =~ m/PRBS/i)
            || ($neType =~ m/WCDMA RNC/i && $simName =~ m/MSRBS/i)
            || ($neType =~ m/GSM LANSWITCH/i && $simName =~ m/MSC/i)
            || ($neType =~ m/LTE MSC/i && ($simName =~ m/MSC/i || $simName =~ m/BSC/i ))
            || ($neType =~ m/CORE BSP/i && ($simName =~ m/MSC/i || $simName =~ m/BSC/i ))
            || ($neType =~ m/LTE vMSC/i && ($simName =~ m/MSC/i || $simName =~ m/BSC/i ))
            || ($neType =~ m/MRSv/i &&  $simName =~ m/vBGF/i)
	    || ($neType =~ m/CSCF.*CORE/i && $simName =~ m/CSCF/i)
            || ($neType =~ m/MTAS.*CORE/i && $simName =~ m/MTAS/i)
            || $neType =~ m/EPG-SSR/i
            || $neType =~ m/EPG-EVR/i
            || $neType =~ m/TCU03/i
            || $neType =~ m/C608/i
            || $neType =~ m/TCU04/i
            || $neType =~ m/ECM/i
	    || $neType =~ m/ECEE/i
            || $neType =~ m/vRM/i
            || $neType =~ m/vRSM/i
            || ($neType =~ m/RNNODE/i && $simName =~ m/TLS/i)
            || ($neType =~ m/vPP/i && $simName =~ m/TLS/i)
            || ($neType =~ m/vRC/i && $simName =~ m/TLS/i)
            || $neType =~ m/VTFRadioNode/i
            || $neType =~ m/5GRadioNode/i
            || $neType =~ m/VTIF/i
            || $neType =~ m/vSD/i
            || ($neType =~ m/LTE SCU/i && $simName !~ m/ERS-SN/i )
            || ($neType =~ m/LTE ESC/i )
            || ($neType =~ m/LTE vDU/i && $simName =~ m/Yang/i )
	    || ($neType =~ m/RDM/i && $simName =~ m/Yang/i )
            || ($neType =~ m/LTE vCU/i && $simName =~ m/Yang/i )
            || ($neType =~ m/LTE vDU/i && $simName =~ m/5G134/i )
            || ($neType =~ m/LTE vDU/i && $simName =~ m/5G116/i )
            || ($neType =~ m/LTE vCU/i && $simName =~ m/5G130/i )
            || ($neType =~ m/LTE vCU/i && $simName =~ m/5G131/i )
            || ($neType =~ m/O1/i && $simName =~ m/O1/i )
            || ($neType =~ m/oRU/i && $simName =~ m/ORU/i )
            || ($neType =~ m/vDU/i && $simName =~ m/ORU/i )
            || $neType =~ m/SpitFire.*17B/i
            || $neType =~ m/SpitFire.*18A/i
            || $neType =~ m/R6274/i
            || $neType =~ m/R6672/i
            || $neType =~ m/R6673/i
            || $neType =~ m/R6675/i
            || $neType =~ m/R6273/i
            || $neType =~ m/R6371/i
            || $neType =~ m/R6471-1/i
            || $neType =~ m/R6471-2/i
            || $neType =~ m/R6676/i
            || $neType =~ m/R6678/i
            || $neType =~ m/R6671/i
            || ($neType =~ m/FrontHaul-6020/i && $nodeVersion > 2021)
            || ($neType =~ m/FrontHaul-6650/i && $nodeVersion > 2021)
            || ($neType =~ m/FrontHaul-6000/i && $nodeVersion > 2021)
            || $neType =~ m/LTE BSC/i
            || $neType =~ m/LTE vBSC/i
            || $neType =~ m/LTE CTC/i
            || $neType =~ m/LTE HLR/i
            || $neType =~ m/LTE vHLR/i ) {
            my $secType = "TLS";
            LogFiles "DG2|LTE PICO|CORE-vSAPC|CORE EPG-SSR|CORE EPG-EVR|"
                     . "GSM-TCU|WRAN PICO|CORE-C608|CORE-ECM|LTE RNNODE|LTE VPP|LTE VRC|LTE EVNFM|LTE VNFM|LTE VNF-LCM|CORE-SpitFire|R6673|R6274|R6672|R6675|R6273|LTE BSC|CONTROLLER6610|"
                     . " sim is found:$simName. Applying TLS security.\n";
            #Set up security on netsim
            &setupSecurityNetsim($workingPath, $simName, $neType, $secType);
#            LogFiles("INFO: Starting Nodes after TLS is set up\n");
#            &startNodes( $dirSimNetDeployer, $simName, $serverType );
            my $sim = $simName . ".zip";
                print FH "$sim\n";
        }
        elsif ( lc $securitySL2 eq lc "ON"
            && $neType =~ /^LTE ERBS/i
            || $neType =~/mgw/i
            || ($neType =~ /WCDMA RNC/i
                && $simName =~ /-RBS/i)
            || ($neType =~ /WCDMA RNC/i
                && $simName =~ /-UPGIND/i) ) {
            my $secType = "SL2";
            LogFiles "CPP ERBS|MGw|MRS|RNC|RBS|RNC UPGIND) sim is found:$simName. Applying SL2 security.\n";
            #Set up security on netsim
            &setupSecurityNetsim($workingPath, $simName, $neType, $secType);
#            LogFiles("INFO: Starting Nodes after SL2 is set up\n");
#            &startNodes( $dirSimNetDeployer, $simName, $serverType, $secType );
            my $sim = $simName . ".zip";
                print FH "$sim\n";
        }
        elsif ( $neType =~ m/RAN-VNFM/i
               || $neType =~ m/EVNFM/i
               || $neType =~ m/VNF-LCM/i
               || $neType =~ m/MSRBS-V/i) {
                         my $secType = "TLS";
            LogFiles "sim is found:$simName. Applying TLS security.\n";
            #Set up security on netsim
            &setupSecurity5G($workingPath, $simName, $neType, $secType);
#            LogFiles("INFO: Starting Nodes after TLS is set up\n");
#            &startNodes( $dirSimNetDeployer, $simName, $serverType );
            my $sim = $simName . ".zip";
                print FH "$sim\n";
       }
 }
}else {
     LogFiles "INFO: No security requried sims found OR security mode is OFF. Hence no security configuration has been applied.";
}
close FH;
