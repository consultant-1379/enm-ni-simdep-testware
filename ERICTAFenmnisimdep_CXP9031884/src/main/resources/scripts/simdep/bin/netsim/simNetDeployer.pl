#!/usr/bin/perl -w
use strict;
use Config::Tiny;
use Cwd qw(abs_path);
use File::Basename;
###################################################################################
#
#     File Name : simNetDeployer.pl
#
#     Version : 5.00
#
#     Author : Jigar Shah
#
#     Description : Rolls out FT Simulations
#
#     Date Created : 09 Feburary 2014
#
#     Syntax : ./simNetDeployer.pl <StoragePath> <ossMasterIP> <PATH> <caasIP>
#
#     Parameters : <StoragePath> The path on the Storage Server where the simulaitons are present.
#          <ossMasterIP> The IP of Master Server.
#          <caasIP> The IP of caas server.
#
#     Example :  ./simNetDeployer.pl /sims/CORE/xjigash/simNetDeployer/simlation 10.10.10.10 /tmp/LTE/simNetDeployer/ 10.10.10.15
#
#     Dependencies :
#
#     NOTE: 1. The file should be executed under /var/tmp/simnet/simNetDeployer/bin
#
#     Return Values : 1 - Not a netsim user.
#             2 - Usage of the script is not right
#
###################################################################################
#
#----------------------------------------------------------------------------------
#Check if the script is executed as netsim user
#----------------------------------------------------------------------------------
#
my $netsim = 'netsim';
my $user   = `whoami`;
chomp($user);
if ( $user ne $netsim ) {
    print("ERROR: Not netsim user. Please execute the script as netsim user\n");
    exit(201);
}

#
#----------------------------------------------------------------------------------
#Check if the script usage is right
#----------------------------------------------------------------------------------
my $USAGE =<<USAGE;
    Usage:
        $0 <storagePath> <defaultDestination> <serverType> <release> <securityStatusTLS> <sim>
        where:
            <storagePath>        : The path on the Storage Server where the simulations are present.
            <defaultDestination> : Specifies default destination.
            <dirSimNetDeployer>  : Specifies the working path directory.
            <serverType>         : Specifies if server type is vapp or vm.
            <release>            : Specifies the release version of the simulations.
            <securityStatusTLS>  : Specifies if the TLS is on/off.
            <ipv6Per>            : Specifies the whether ipv6 nodes needed or not
	    <switchToRvConf>     : Specifies Whether the rollout performed is for RV or MT yes/no
            <sim>                : Specifies the sim names to be fetched from Storage Server ( This is optional).
        usage examples:
             $0 /sims/O16/ENM/16.2/mediumDeployment/LTE/5KLTE/ 192.168.0.12 /tmp/LTE/simNetDeployer/16.2/ VAPP 16.2 ON yes LTE07
             $0 /sims/O16/ENM/16.2/mediumDeployment/LTE/5KLTE/ 192.168.0.12 /tmp/LTE/simNetDeployer/16.2/ VAPP 16.2 ON yes
        dependencies:
              1. Should be able to access storage device - FTP server.
        Return Values: 201 -> Not a netsim user
                       202 -> Usage is incorrect
                       203 -> Could not update log file.
                       206 -> File Does not exist.
USAGE

if ( @ARGV > 9 ) {
    print("$USAGE");
    exit(202);
}
print "RUNNING: $0 @ARGV \n";

my $dirSimNetDeployer = $ARGV[2];
chdir("$dirSimNetDeployer/bin");

#----------------------------------------------------------------------------------
#Variables
#----------------------------------------------------------------------------------
my $errorStatus = 0;
my $SLEEP_TIME=60;

my $PWD = dirname(abs_path($0));
print "PWD:$PWD \n";
chomp($PWD);

#
#----------------------------------------------------------------------------------
# Set up log file
#----------------------------------------------------------------------------------
my $dateVar = `date +%F`;
chomp($dateVar);
my $timeVar = `date +%T`;
chomp($timeVar);
if (! open LOGFILEHANDLER, "+>>", "../logs/simNetDeployerLogs_$dateVar\_$timeVar.log") {
    print "ERROR: Could not open log file.\n";
    exit(203);
}
LogFiles(
"INFO: You can find real time execution logs of this script at ../logs/simNetDeployerLogs_$dateVar\_$timeVar.log\n"
);

#----------------------------------------------------------------------------------
#
#----------------------------------------------------------------------------------
#Environmnet variables
#----------------------------------------------------------------------------------
my $storagePath        = "$ARGV[0]";
my $defaultDestination = "$ARGV[1]";
my $serverType         = "$ARGV[3]";
my $release            = "$ARGV[4]";
my $securityStatusTLS  = "$ARGV[5]";
my $ipv6Per            = "$ARGV[6]";
my $switchToRvConf     = "$ARGV[7]";
my $sim                = $ARGV[8];

$sim = "" if not defined $sim;

#
#------------------------------------------
# Config file params
#------------------------------------------
my $CONFIG_FILE  = "conf.txt";
my $CONFIG_FILE_PATH ="$PWD/../conf/$CONFIG_FILE";
my $Config = Config::Tiny->new;
$Config = Config::Tiny->read($CONFIG_FILE_PATH);

# Reading properties
my $fetchSimsMethod = $Config->{servers}->{FETCH_SIMS_METHOD};
#print "INFO: FETCH_SIMS_FROM_LOCAL_FOLDER:$fetchSimsMethod \n";

my $securityStatusSL2 = $Config->{_}->{SETUP_SECURITY_SL2};
#print "securityStatusSL2:$securityStatusSL2 \n";

my $deploymentType = $Config->{_}->{DEPLOYMENT_TYPE};
print "INFO: DEPLOYMENT_TYPE: $deploymentType \n";

my $docker = $Config->{_}->{SWITCH_TO_DOCKER};
print "INFO: SWITCH_TO_DOCKER: ". uc($docker) . "\n";


#
#----------------------------------------------------------------------------
#SubRoutine to read config file
#----------------------------------------------------------------------------
#
sub readConfig {
    #my $path = $_[0];
    ( my $path, my $simNameCount, my $totalNumOfSim ) = @_;
    my @arneFileGenerationEdit;
    LogFiles("INFO: ($simNameCount\/$totalNumOfSim) Reading config file from $path \n");
    open CONF, "$path" or die "Can't open path:$path $!\n";
    my @conf = <CONF>;
    close(CONF);
    foreach (@conf) {
        next if /^#/;
        if ( $_ =~ "ARNE_FILE_GENERATION" ) {
            @arneFileGenerationEdit = split( /=/, $_ );
           }
    }
    chomp( $arneFileGenerationEdit[1] );
    my $arneFileGenerationVar = $arneFileGenerationEdit[1];
    return ($arneFileGenerationVar);
}

#
#----------------------------------------------------------------------------------
#SubRoutine to fetchFiles
#----------------------------------------------------------------------------------
sub fetchFiles {
    my $fetchSimsMethod = $_[0];
    my $path            = $_[1];
    my $sim             = $_[2];
    my $errorStatus = 0;
    if ( defined $sim ) {
         LogFiles("INFO: Fetching files from $path on $fetchSimsMethod server and storing under /netsim/netsimdir on netsim for $sim\n");
         LogFiles("INFO: Running $PWD/../utils/fetchFiles.pl $fetchSimsMethod $path $sim \n");
         `($PWD/../utils/fetchFiles.pl $fetchSimsMethod $path $sim 2>&1) | tee ../logs/runtimLogFetchFiles.txt`;
    }
    else {
         LogFiles("INFO: Fetching files from $path on $fetchSimsMethod server and storing under /netsim/netsimdir on netsim\n");
         LogFiles("INFO: Running $PWD/../utils/fetchFiles.pl $fetchSimsMethod $path \n");
         `($PWD/../utils/fetchFiles.pl $fetchSimsMethod $path 2>&1) | tee ../logs/runtimLogFetchFiles.txt`;
    }

    my $errorHandler =
      `$PWD/../utils/checkForError.sh ERROR ../logs/runtimLogFetchFiles.txt`;
    if ( $errorHandler != 0 ) {
        LogFiles(
            "ERROR: Could not fetch files from $fetchSimsMethod server location $path\n");
        LogFiles("##########################################\n");
        $errorStatus = 1;
    }
    else {
        if (! -e "$PWD/../dat/listSimulation.txt") {
            print "ERROR: File $PWD/../dat/listSimulation.txt doesn't exist.\n";
            exit(206);
        }
        if (! open listSim, "<", "$PWD/../dat/listSimulation.txt") {
            print "ERROR: Could not open file $PWD/../dat/listSimulation.txt.\n";
            exit(203);
        }
        my @simNamesArray = <listSim>;
        close listSim;
        my $sizeSimNamesArray = @simNamesArray;

        foreach (@simNamesArray) {
            LogFiles("INFO: $_");
        }

        if ($sizeSimNamesArray le 0) {
           LogFiles("ERROR: There are no Simulations in specifed criteria or path");
           } else {
            LogFiles(
"INFO: Successfully fetched sims from $path on $fetchSimsMethod server and stored under /netsim/netsimdir on netsim.\n"
            );
        }

#        system("rm ../logs/runtimLogFetchFiles.txt");
#        if ($? != 0)
#        {
#             LogFiles("INFO: Failed to execute system command (rm ../logs/runtimLogFetchFiles.txt)\n");
#        }
    }
    return $errorStatus;
}

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
#----------------------------------------------------------------------------------
#SubRoutine to read simulation data
#----------------------------------------------------------------------------------
sub readSimData {
    ( my $simName, my $simNameCount, my $totalNumOfSim ) = @_;
    my $errorStatus = 0;
    LogFiles("INFO: ($simNameCount\/$totalNumOfSim) Reading data NE names and NE Types for simulation $simName\n");
    `$PWD/readSimData.pl $simName $docker > ../logs/runtimeLogReadSimData$simName.txt`;
    my $errorHandler = `$PWD/../utils/checkForError.sh ERROR ../logs/runtimeLogReadSimData$simName.txt`;
    if ( $errorHandler == 1 ) {
        `cat ../logs/runtimeLogReadSimData$simName.txt >> ../logs/simNetDeployerLogs.txt`;
        foreach my $i (1..3) {
        if (-e "../logs/failedLogReadSimData$simName.txt")
        {
        system("rm ../logs/failedLogReadSimData$simName.txt");
        }
        LogFiles("INFO: Could not read from the simulations. Retrying again ($i/3). \n");
        `$PWD/readSimData.pl $simName $docker > ../logs/failedLogReadSimData$simName.txt`;
        my $errorHandler = `$PWD/../utils/checkForError.sh ERROR ../logs/failedLogReadSimData$simName.txt`;
        if ( $errorHandler == 1 ) {
            `cat ../logs/failedLogReadSimData$simName.txt >> ../logs/simNetDeployerLogs.txt`;
            if ( $i != 3)
            {
                 LogFiles("INFO: Could not read from the simulation. Please see ../logs/runtimeLogReadSimData$simName.txt for more details \n");
            }
            if ($i == 3 )
            {
                LogFiles("ERROR: Could not read from the simulation. Please see ../logs/runtimeLogReadSimData$simName.txt for more details \n");
                LogFiles("##########################################\n");
            }
                $errorStatus = 1;
        }
        else {
            `cat ../logs/failedLogReadSimData$simName.txt >> ../logs/simNetDeployerLogs.txt`;
            system("rm ../logs/failedLogReadSimData$simName.txt");
            if ($? != 0)
            {
                LogFiles("INFO: Failed to execute system command (rm ../logs/failedLogReadSimData$simName.txt)\n");
            }
            LogFiles("INFO: ($simNameCount\/$totalNumOfSim) Successful read data for $simName and stored at ../dat/dumpNeName.txt and ../dat/dumpNeType.txt \n");
            $errorStatus = 0;
            last;
        }
    }
    }
    else {
        `cat ../logs/runtimeLogReadSimData$simName.txt >> ../logs/simNetDeployerLogs.txt`;
        system("rm ../logs/runtimeLogReadSimData$simName.txt");
        if ($? != 0)
        {
            LogFiles("INFO: Failed to execute system command (rm ../logs/runtimeLogReadSimData$simName.txt)\n");
        }
        LogFiles("INFO: ($simNameCount\/$totalNumOfSim) Successful read data for $simName and stored at ../dat/dumpNeName.txt and ../dat/dumpNeType.txt \n");
        $errorStatus = 0;
    }
    return $errorStatus;
}

#
#----------------------------------------------------------------------------------
#SubRoutine to open simulation
#----------------------------------------------------------------------------------

sub openSimulation {
( my $simName, my $simNameCount, my $totalNumOfSim ) = @_;
    my $errorStatus = 0;
    my $clearlock = "no";
    LogFiles("INFO: ($simNameCount\/$totalNumOfSim) Checking is there any enough space.\n");
    my $diskSpaceError = system("df -h | awk -F' ' '{print \$5}' | sed '2q;d' | sed 's/%//' | perl -lne 'exit(-1) if \$_>98'");
    if ( $diskSpaceError != 0 ) {
        LogFiles("ERROR: There is not enough disk space. More than %98 of disk is full. Exiting from rollout\n");
        exit(213);
    }

    LogFiles("INFO: ($simNameCount\/$totalNumOfSim) $simName being opened\n");
    `$PWD/openSimulation.pl $simName $clearlock > ../logs/runtimeLogOpenSimulation$simName.txt`;
    my $errorHandlerFailed = `$PWD/../utils/checkForError.sh failed ../logs/runtimeLogOpenSimulation$simName.txt`;
    my $errorHandlerNeConflict = `$PWD/../utils/checkForError.sh "Conflicts with already installed files" ../logs/runtimeLogOpenSimulation$simName.txt`;
    my $errorHandler = `$PWD/../utils/checkForError.sh ERROR ../logs/runtimeLogOpenSimulation$simName.txt`;
    if ( ( $errorHandler == 1 ) || ( $errorHandlerFailed == 1 ) || ( $errorHandlerNeConflict == 1 ) ) {
        `cat ../logs/runtimeLogOpenSimulation$simName.txt >> ../logs/simNetDeployerLogs.txt`;
        if ( $errorHandlerNeConflict == 1 ){
            $clearlock = "yes";
        }
        my $sleepTime = 300;
        foreach my $i (1..3) {
            LogFiles("INFO: Could not open the simulation. Retrying again ($i/3). Sleeping time: $sleepTime\n");
            `$PWD/openSimulation.pl $simName $clearlock > ../logs/failedLogOpenSimulation$simName.txt`;
            my $errorHandlerFailed = `$PWD/../utils/checkForError.sh failed ../logs/failedLogOpenSimulation$simName.txt`;
            my $errorHandlerNeConflict = `$PWD/../utils/checkForError.sh "Conflicts with already installed files" ../logs/runtimeLogOpenSimulation$simName.txt`;
            my $errorHandler = `$PWD/../utils/checkForError.sh ERROR ../logs/failedLogOpenSimulation$simName.txt`;
            if ( ( $errorHandler == 1 ) || ( $errorHandlerFailed == 1 ) || ( $errorHandlerNeConflict == 1 ) ) {
                 `cat ../logs/failedLogOpenSimulation$simName.txt >> ../logs/simNetDeployerLogs.txt`;
                  if ( $errorHandlerNeConflict == 1 ){
                     $clearlock = "yes";
                 }
                 if ( $i != 3) {
                     LogFiles("INFO: Could not open the simulation ($i/3). Please see ../logs/failedLogOpenSimulation$simName.txt for more details \n");
                 }
                 if ($i == 3 ) {
                      LogFiles("ERROR: Could not open the simulation ($i/3). Please see ../logs/failedLogOpenSimulation$simName.txt for more details \n");
                      LogFiles("##########################################\n");
                 }
                 $errorStatus = 1;
            } else {
                `cat ../logs/failedLogOpenSimulation$simName.txt >> ../logs/simNetDeployerLogs.txt`;
                LogFiles("INFO: ($simNameCount\/$totalNumOfSim) Successfuly opened $simName simulation \n");
                $errorStatus = 0;
                last;
            }
            sleep($sleepTime);
            $sleepTime = $sleepTime + 5;
        }
    } else {
        `cat ../logs/runtimeLogOpenSimulation$simName.txt >> ../logs/simNetDeployerLogs.txt`;
        system("rm ../logs/runtimeLogOpenSimulation$simName.txt");
        if ($? != 0) {
             LogFiles("INFO: Failed to execute system command (rm ../logs/runtimeLogOpenSimulation$simName.txt)\n");
        }
        LogFiles("INFO: ($simNameCount\/$totalNumOfSim) Successfuly opened $simName simulation \n");
        $errorStatus = 0;
    }

    if( $errorStatus == 1 ) {  # 1: error exist, 0: no erors
        Logfiles ("ERROR: Exiting from rollout due to sim can not be open! \n");
        exit(213);
    }

    return $errorStatus;
}

#
#----------------------------------------------------------------------------------
#SubRoutine - Decision Making module
#----------------------------------------------------------------------------------
sub decisionModule {
    ( my $NeTypeName, my $simName, my $simNameCount, my $totalNumOfSim, my $release, my $securityStatusTLS, my $ipv6Per ) = @_;
    my $errorStatus = 0;
    chomp($NeTypeName);
    LogFiles(
"INFO: ($simNameCount\/$totalNumOfSim) Now deciding on the following parameters\n"
    );
    LogFiles(
"INFO: ($simNameCount\/$totalNumOfSim) Port Name, Port Protocol and # of IP per Node for $simName \n"
    );
    `$PWD/decisionModule.pl $simName '$NeTypeName' $release $securityStatusTLS $ipv6Per > ../logs/runtimeLogDecisionModule$simName.txt`;
    my $errorHandler =
`$PWD/../utils/checkForError.sh ERROR ../logs/runtimeLogDecisionModule$simName.txt`;
    if ( $errorHandler == 1 ) {
        `cat ../logs/runtimeLogDecisionModule$simName.txt >> ../logs/simNetDeployerLogs.txt`;
        LogFiles(
"ERROR: Could not fetch decision variables for the simulation. Please see ../logs/runtimeLogDecisionModule$simName.txt for more details \n"
        );
        LogFiles("INFO: ##########################################\n");
        $errorStatus = 1;
    }
    else {
        `cat ../logs/runtimeLogDecisionModule$simName.txt >> ../logs/simNetDeployerLogs.txt`;
        system("rm ../logs/runtimeLogDecisionModule$simName.txt");
        if ($? != 0)
        {
             LogFiles("INFO: Failed to execute system command (rm ../logs/runtimeLogDecisionModule$simName.txt)\n");
        }
    }
    return $errorStatus;
}

#
#------------------------------------------------------------------------------------------
#SubRoutine to create Port
#------------------------------------------------------------------------------------------

sub checkNetsim {
   my $errorStatus = 0;
    LogFiles("INFO: Starting checking NETsim status\n");
    `echo ".show simulations" | /netsim/inst/netsim_shell > ../logs/runtimeLogCheckNetsim.txt`;
    my $errorHandler = `$PWD/../utils/checkForError.sh "restart_netsim|start_netsim" ../logs/runtimeLogCheckNetsim.txt`;

    if ( $errorHandler == 1 ) {
        `cat ../logs/runtimeLogCheckNetsim.txt > ../logs/failedSimNetDeployerLogs.txt`;
        LogFiles("ERROR: NETsim in stopped state. Please see ../logs/runtimeLogCheckNetsim.txt for more details \n");
        LogFiles("INFO: ##########################################\n");
        $errorStatus = 1;
    } else {
        `cat ../logs/runtimeLogCheckNetsim.txt > ../logs/simNetDeployerLogs.txt`;
    }
    return $errorStatus;
}

#
#------------------------------------------------------------------------------------
#SubRoutine to fetch free IPs
#-----------------------------------------------------------------------------------
sub fetchFreeIps {
    ( my $numOfIpv4s, my $numOfIpv6s, my $simNameCount, my $totalNumOfSim ) =
      @_;
    my $errorStatus = 0;
    #chomp($numOfIpv4s, $numOfIpv6s);
    LogFiles(
"INFO: ($simNameCount\/$totalNumOfSim) Now fetching ipv4=$numOfIpv4s, ipv6=$numOfIpv6s free IPs \n"
    );
`$PWD/../utils/fetchFreeIps.pl --ipv4=$numOfIpv4s --ipv6=$numOfIpv6s > ../logs/runtTimeLogFetchFreeIps.txt`;
    my $errorHandler =
`$PWD/../utils/checkForError.sh ERROR ../logs/runtTimeLogFetchFreeIps.txt`;
    if ( $errorHandler == 1 ) {
        LogFiles(
"ERROR: Could not fetch free IPV4|IPv6 addresses. Please see ../logs/runtTimeLogFetchFreeIps.txt for more details \n"
        );
        LogFiles("##########################################\n");
        $errorStatus = 1;
    }
    else {
        system("rm ../logs/runtTimeLogFetchFreeIps.txt");
        if ($? != 0)
        {
             LogFiles("INFO: Failed to execute system command (rm ../logs/runtTimeLogFetchFreeIps.txt)\n");
        }
        LogFiles(
"INFO: ($simNameCount\/$totalNumOfSim) Successfuly fetched ipv4=$numOfIpv4s, ipv6=$numOfIpv6s IPs \n"
        );
    }
    return $errorStatus;
}

#------------------------------------------------------------------------------------------
#SubRoutine to fetch the first free IP
#------------------------------------------------------------------------------------------
sub fetchFirstFreeIp {
    my $errorStatus = 0;
    my $numberOfIps = 1;
`$PWD/../utils/fetchFreeIps.pl --ipv4=$numberOfIps > ../logs/runtTimeLogFetchFreeIps.txt`;
    my $errorHandler =
`$PWD/../utils/checkForError.sh ERROR ../logs/runtTimeLogFetchFreeIps.txt`;
    if ( $errorHandler == 1 ) {
        LogFiles(
"ERROR: Could not fetch free IPV4 address. Please see ../logs/runtTimeLogFetchFreeIps.txt for more details \n"
        );
    }
    else {
        system("rm ../logs/runtTimeLogFetchFreeIps.txt");
        if ($? != 0)
        {
             LogFiles("INFO: Failed to execute system command (rm ../logs/runtTimeLogFetchFreeIps.txt)\n");
        }
    }

    # As a future improvement IPV6 check should be switched on|off from config
`$PWD/../utils/fetchFreeIps.pl --ipv6=$numberOfIps > ../logs/runtTimeLogFetchFreeIps.txt`;
    $errorHandler =
`$PWD/../utils/checkForError.sh ERROR ../logs/runtTimeLogFetchFreeIps.txt`;
    if ( $errorHandler == 1 ) {
        LogFiles(
"ERROR: Could not fetch free IPV6 address. Please see ../logs/runtTimeLogFetchFreeIps.txt for more details \n"
        );
        LogFiles("INFO: ##########################################\n");
        $errorStatus = 0;
    }
    else {
        system("rm ../logs/runtTimeLogFetchFreeIps.txt");
        if ($? != 0)
        {
             LogFiles("INFO: Failed to execute system command (rm ../logs/runtTimeLogFetchFreeIps.txt)\n");
        }
    }

    return $errorStatus;
}
#
#------------------------------------------------------------------------------------------
#SubRoutine to create Port
#------------------------------------------------------------------------------------------

sub createPort {
    ( my $defaultDestination ) = @_;
    my $errorStatus = 0;
    chomp($defaultDestination);
    `$PWD/createPort.pl $defaultDestination > ../logs/simNetDeployerLogs.txt`;

    my $errorHandler = `$PWD/../utils/checkForError.sh ERROR ../logs/simNetDeployerLogs.txt`;
    if ( $errorHandler == 1 ) {

        foreach my $i (1..3) {
            LogFiles "INFO: Minumum wating time is set to $SLEEP_TIME seconds to create a port\n";
            sleep ($SLEEP_TIME);
            LogFiles("INFO: Could not create port. Retrying again ($i/3). \n");
            `$PWD/createPort.pl $defaultDestination >> ../logs/failedsimNetDeployerLogs.txt`;
            my $errorHandler = `$PWD/../utils/checkForError.sh ERROR ../logs/failedsimNetDeployerLogs.txt`;
            if ( $errorHandler == 1 ) {
               if ( $i != 3)
                {
                     LogFiles("INFO: Could not create Port. Please see ../logs/simNetDeployerLogs.txt` for more details \n");
                }
                if ($i == 3 )
                {
                     LogFiles("ERROR: Could not create Port. Please see ../logs/simNetDeployerLogs.txt` for more details \n");
                     LogFiles("##########################################\n");
                }
              $errorStatus = 1;
            } else {
                LogFiles("INFO: Ports are created successfully. \n");
                $errorStatus = 0;
                last;
            }
        }
    }
    else {
         LogFiles("INFO: Ports are created successfully. \n");
         $errorStatus = 0;
    }
   return $errorStatus;
}

#
#---------------------------------------------------------------------------------------------
#SubRoutine to assign Port
#---------------------------------------------------------------------------------------------
sub assignPort {
    (
        my $simName, my $simPort,
        my $simPortName,
        my $ddAddress,
        my $simNameCount,
        my $totalNumOfSim
    ) = @_;
    my $errorStatus = 0;
    chomp($simPort);
    chomp($simName);
    LogFiles("INFO: ($simNameCount\/$totalNumOfSim) Assigning $simPortName Port to NEs\n");
    `$PWD/assignPort.pl $simName $simPort $simPortName $ddAddress $securityStatusTLS $switchToRvConf $ipv6Per > ../logs/runtimeLogAssignPort$simName.txt`;
    my $errorHandler = `$PWD/../utils/checkForError.sh ERROR ../logs/runtimeLogAssignPort$simName.txt`;
    if ( $errorHandler == 1 ) {
        `cat ../logs/runtimeLogAssignPort$simName.txt >> ../logs/simNetDeployerLogs.txt`;
        foreach my $i (1..3) {
        if (-e "../logs/failedLogAssignPort$simName.txt")
        {
        system("rm ../logs/failedLogAssignPort$simName.txt");
        }
        LogFiles "INFO: Minumum wating time is set to $SLEEP_TIME seconds to assign port data\n";
        sleep ($SLEEP_TIME);
        LogFiles("INFO: Could not assign port. Retrying $i time \n");
        `$PWD/assignPort.pl $simName $simPort $simPortName $ddAddress $securityStatusTLS $switchToRvConf >> ../logs/failedLogAssignPort$simName.txt`;
        my $errorHandler =
        `$PWD/../utils/checkForError.sh ERROR ../logs/failedLogAssignPort$simName.txt`;
        if ( $errorHandler == 1 ) {
             `cat ../logs/failedLogAssignPort$simName.txt >> ../logs/simNetDeployerLogs.txt`;
             if ( $i != 3)
             {
                 LogFiles("INFO: Could not assign Port. Please see ../logs/failedLogAssignPort$simName.txt for more details \n");
             }
             if ($i == 3 )
             {
                 LogFiles( "ERROR: Could not assign Port. Please see ../logs/failedLogAssignPort$simName.txt for more details \n" );
                 LogFiles("##########################################\n");
             }
             $errorStatus = 1;
        }
        else {
            `cat ../logs/failedLogAssignPort$simName.txt >> ../logs/simNetDeployerLogs.txt`;
            system("rm ../logs/failedLogAssignPort$simName.txt");
            if ($? != 0)
            {
                LogFiles("INFO: Failed to execute system command (rm ../logs/failedLogAssignPort$simName.txt)\n");
            }
            LogFiles("INFO: ($simNameCount\/$totalNumOfSim) $simPortName port assigned successfully\n");
            $errorStatus = 0;
            last;
        }
    }
    }
    else {
        `cat ../logs/runtimeLogAssignPort$simName.txt >> ../logs/simNetDeployerLogs.txt`;
        system("rm ../logs/runtimeLogAssignPort$simName.txt");
        if ($? != 0)
        {
            LogFiles("INFO: Failed to execute system command (rm ../logs/runtimeLogAssignPort$simName.txt)\n");
        }
        LogFiles("INFO: ($simNameCount\/$totalNumOfSim) $simPortName port assigned successfully\n");
        $errorStatus = 0;
    }
    return $errorStatus;
}


#
#----------------------------------------------------------------------------------
#SubRoutine - Set tmpfs for sims
#----------------------------------------------------------------------------------
sub setTmpFs {
    ( my $simName, my $simNameCount, my $totalNumOfSim) = @_;
    my $errorStatus = 0;
    chomp($simName);
    my @simNameFields = split/.zip/, $simName;
    $simName = $simNameFields[0];
    LogFiles(
"INFO: ($simNameCount\/$totalNumOfSim) Now setting tmpfs for the sim: $simName\n"
    );
    `$PWD/../utils/set_tmpfs.sh $simName > ../logs/runtimeSetTmpFsModule$simName.txt`;
    my $errorHandler =
`$PWD/../utils/checkForError.sh ERROR ../logs/runtimeSetTmpFsModule$simName.txt`;
    if ( $errorHandler == 1 ) {
        `cat ../logs/runtimeSetTmpFsModule$simName.txt >> ../logs/simNetDeployerLogs.txt`;
        LogFiles(
"ERROR: Could not set tmpfs for the simulation. Please see ../logs/runtimeSetTmpFsModule$simName.txt for more details \n"
        );
        LogFiles("INFO: ##########################################\n");
        $errorStatus = 1;
    }
    else {
        `cat ../logs/runtimeSetTmpFsModule$simName.txt >> ../logs/simNetDeployerLogs.txt`;
        system("rm ../logs/runtimeSetTmpFsModule$simName.txt");
        if ($? != 0)
        {
             LogFiles("INFO: Failed to execute system command (rm ../logs/runtimeSetTmpFsModule$simName.txt)\n");
        }
    }
    return $errorStatus;
}

#
#-----------------------------------------------------------------------------------------------
#Remove duplicate array elements and return unique elementes array
#-----------------------------------------------------------------------------------------------
sub uniq {
  my %seen;
  return grep { !$seen{$_}++ } @_;
}

#
#-----------------------------------------------------------------------------------------------
#SubRoutine to start Nodes
#-----------------------------------------------------------------------------------------------
sub startNodes {
    (  my $NeTypeName, my $simName, my $simNameCount, my $totalNumOfSim, my $numOfNodes, my $all, my $deploymentType, my $numOfIpv6Nes ) = @_;

    my $errorStatus = 0; # 1 fail 0 pass

    my $msg1 = 'NEs';
    my $msg2 = 'start the nodes';
    my $msg3 = 'started the all nodes';
    if ($numOfNodes == 0 && $all eq '') {
        $msg1 = 'setting load balancing';
        $msg2 = 'set the loadbalancing';
        $msg3 = $msg2;
    }

    LogFiles("INFO: ($simNameCount\/$totalNumOfSim) Starting $msg1 for simulation $simName\n" );
    my $errorHandler = 0;
    my $errorHandlerOverRide =
    `$PWD/../utils/checkForError.sh "No security definition has been configured for this NE" ../logs/runtimeLogStartNodes$simName.txt`;
    if ( $errorHandlerOverRide == 1 ) {
        LogFiles("INFO: ($simNameCount\/$totalNumOfSim) Overriding error handler for security error (1)\n" );
    }
    if ( $errorHandler == 1 ) {
        `cat ../logs/runtimeLogStartNodes$simName.txt >> ../logs/simNetDeployerLogs.txt`;
        foreach my $i (1..3) {
            LogFiles "INFO: Minumum waiting time is set to $SLEEP_TIME seconds to $msg2\n";
            sleep ($SLEEP_TIME);
            LogFiles( "INFO: Could not start nodes on $simName. Retrying again ($i/3).\n");
            my $errorHandlerOverRide =
           `$PWD/../utils/checkForError.sh "No security definition has been configured for this NE" ../logs/failedLogStartNodes$simName.txt`;
            if ( $errorHandlerOverRide == 1 ) {
                $errorHandler = 0;
                 LogFiles("INFO: ($simNameCount\/$totalNumOfSim) Overriding error handler for security error (2)\n" );
            }

            if ($errorHandler == 1 ) {
                `cat ../logs/failedLogStartNodes$simName.txt >> ../logs/simNetDeployerLogs.txt`;
                if ( $i != 3) {
                     LogFiles( "INFO: Could not $msg2 on $simName. Please see ../logs/failedLogStartNodes$simName.txt for more details \n" );
                }
                if ($i == 3 ) {
                     LogFiles( "ERROR: Could not $msg2 on $simName. Please see ../logs/failedLogStartNodes$simName.txt for more details \n" );
                     LogFiles("##########################################\n");
                }
                $errorStatus = 1;
            } else {
              `cat ../logs/failedLogStartNodes$simName.txt >> ../logs/simNetDeployerLogs.txt`;
              LogFiles("INFO: ($simNameCount\/$totalNumOfSim) Successfuly $msg3 for $simName\n");
              $errorStatus = 0;
              last;
            }
        }
    }
    else {
         `cat ../logs/runtimeLogStartNodes$simName.txt >> ../logs/simNetDeployerLogs.txt`;
         LogFiles("INFO: ($simNameCount\/$totalNumOfSim) Successfully $msg3 for $simName\n");
         $errorStatus = 0;
    }

    if( $errorStatus == 1 ) {  # 1: error exist, 0: no erors
        LogFiles ("ERROR: Exiting from rollout due to starting nodes error! \n");
        exit(212);
    }
    return $errorStatus;
}

#
#-----------------------------------------------------------------------------------------------
#SubRoutine to create ARNE XML and UNIX User
#-----------------------------------------------------------------------------------------------
sub createArneUnix {
    ( my $simName, my $NeTypeName, my $simNameCount, my $totalNumOfSim ) = @_;
    my $errorStatus = 0;
    LogFiles(
"INFO: ($simNameCount\/$totalNumOfSim) Now creating ARNE XML and UNIX users for $simName \n"
    );
`$PWD/createArneUnix.pl $simName $NeTypeName > ../logs/runtimeLogCreateArneUnix$simName.txt`;
    my $errorHandler =
`$PWD/../utils/checkForError.sh ERROR ../logs/runtimeLogCreateArneUnix$simName.txt`;
    if ( $errorHandler == 1 ) {
`cat ../logs/runtimeLogCreateArneUnix$simName.txt >> ../logs/simNetDeployerLogs.txt`;
        LogFiles(
"ERROR: Error while creating ARNE XML or UNIX user. Please see ../logs/runtimeLogCreateArneUnix$simName.txt for more details \n"
        );
        LogFiles("##########################################\n");
        $errorStatus = 1;
    }
    else {
`cat ../logs/runtimeLogCreateArneUnix$simName.txt >> ../logs/simNetDeployerLogs.txt`;
        system("rm ../logs/runtimeLogCreateArneUnix$simName.txt");
        if ($? != 0)
        {
             LogFiles("INFO: Failed to execute system command (rm ../logs/runtimeLogCreateArneUnix$simName.txt)\n");
        }
        LogFiles(
"INFO: ($simNameCount\/$totalNumOfSim) Successfuly created ARNE XML and Unix User for $simName\n"
        );
    }
    return $errorStatus;
}

#
#---------------------------------------------------------------------------------------------------
#SubRoutine to apply ANRE XML workaround
#---------------------------------------------------------------------------------------------------
sub workAroundXML {
    ( my $simName, my $simNameCount, my $totalNumOfSim ) = @_;
    my $errorStatus = 0;
    LogFiles(
"INFO: ($simNameCount\/$totalNumOfSim) Applying Workaround to the XML created for $simName\n"
    );
`$PWD/../utils/workAroundXML.pl $simName > ../logs/runtimeLogWorkAroundXML$simName.txt`;
    my $errorHandler =
`$PWD/../utils/checkForError.sh ERROR ../logs/runtimeLogWorkAroundXML$simName.txt`;
    if ( $errorHandler == 1 ) {
`cat ../logs/runtimeLogWorkAroundXML$simName.txt >> ../logs/simNetDeployerLogs.txt`;
        LogFiles(
"ERROR: Error while applying workaround for ARNE XML. Please see $PWD/../logs/runtimeLogWorkAroundXML$simName.txt for more details \n"
        );
        LogFiles("##########################################\n");
        $errorStatus = 1;
    }
    else {
`cat ../logs/runtimeLogWorkAroundXML$simName.txt >> ../logs/simNetDeployerLogs.txt`;
        system("rm ../logs/runtimeLogWorkAroundXML$simName.txt");
        if ($? != 0)
        {
             LogFiles("INFO: Failed to execute system command (rm ../logs/runtimeLogWorkAroundXML$simName.txt)\n");
        }
        LogFiles(
"INFO: ($simNameCount\/$totalNumOfSim) ARNE XML for $simName is ready for import\n"
        );
    }
    return $errorStatus;
}

#---------------------------------------------------------
#Subroutine to set Element Manager user cmds to ERBS nodes
#---------------------------------------------------------
sub setEmForErbs {
    my ( $simNameCount, $totalNumOfSim, $simName, $servertype, $numOfVappNes, $vmStartNe, $vmEndNe, $contentFile1_8K ) = @_;
    substr $simName, index($simName, ".zip"), 4,"" if "$simName" =~ /\.zip/;
    if ("$contentFile1_8K") {
        $servertype = "1.8K" ;
    }
    `./setElementManager.sh $simName $vmStartNe $vmEndNe $numOfVappNes $servertype > ../logs/setElementManager$simName.txt`;
    my $errorHandler = `$PWD/../utils/checkForError.sh ERROR ../logs/setElementManager$simName.txt`;
    if ( $errorHandler == 1 ) {
        `cat ../logs/setElementManager$simName.txt >> ../logs/simNetDeployerLogs.txt`;
         LogFiles("ERROR: Could not set Element Manager support for the simulation. Please see ../logs/setElementManager$simName.txt for more details \n");
         LogFiles("INFO: ##########################################\n");
         $errorStatus = 1;
    }
    else {
        `cat ../logs/setElementManager$simName.txt >> ../logs/simNetDeployerLogs.txt`;
        system("rm ../logs/setElementManager$simName.txt");
        if ($? != 0) {
            LogFiles("INFO: Failed to execute system command (rm ../logs/setElementManager$simName.txt)\n");
        }
    }
    return $errorStatus;
}
#--------------------------------------------------------------
#Check if the LTE simulation is having CPP ERBS nodes
#--------------------------------------------------------------
sub isLteCppErbsSim {
    ( my $simName, my $neType, my $simNameCount, my $totalNumOfSim ) = @_;
    substr $simName, index($simName, ".zip"), 4,"" if "$simName" =~ /\.zip/;
    if ( "$simName" =~ m/LTE/i ) {
        if ( "$neType" =~ m/ERBS/i ) {
            LogFiles "INFO: ($simNameCount\/$totalNumOfSim) Setting EM support for the simulation $simName\n";
            return 0;
        }
        else {
            LogFiles "INFO: ($simNameCount\/$totalNumOfSim) EM support will not be applied to the simulation $simName\n";
            return -1;
        }
     }
     else {
         LogFiles "INFO: ($simNameCount\/$totalNumOfSim) Not an LTE simulation. Hence no EM support will be applied\n";
         return -1;
     }
}
#--------------------------------------------------------------
#Check if the simulations are of 1.8K network
#--------------------------------------------------------------
sub sims1_8KContent {
    chdir("/netsim/simdepContents/");
    my $pwd =`pwd`;
    chomp($pwd);
    opendir(DIR, "$pwd");
    my $file= grep(/RFA/ || /^Simnet_1_8K_CXP*.*\.content/,readdir(DIR));
    closedir(DIR);
    chdir($PWD);
    return $file ;
}
#
####################################################################################################r
#Main
#####################################################################################################

#---------------------------------------------------
# Check whether sims are succesfully fetched or not
#---------------------------------------------------
if ( defined $sim and $sim ne "") {
    my $errorStatusFetchFiles = &fetchFiles($fetchSimsMethod, $storagePath, $sim);
    if ( "$errorStatusFetchFiles" == 1 ) {
        exit (206);
    }
} else {
    my $errorStatusFetchFiles = &fetchFiles($fetchSimsMethod, $storagePath);
    if ( "$errorStatusFetchFiles" == 1 ) {
        exit (206);
    }
}

if (! open listSim, "<", "$PWD/../dat/listSimulation.txt") {
    print "ERROR: Could not open file $PWD/../dat/listSimulation.txt.\n";
    exit(203);
}

my @simNamesArray = <listSim>;
close listSim;

if(!@simNamesArray ){
    LogFiles("ERROR: There are no Simulations in specifed criteria or path\n");
    LogFiles("Retrying to fetch simulation from specifed criteria or path\n");
    if ( defined $sim and $sim ne "") {
    my $errorStatusFetchFiles = &fetchFiles($fetchSimsMethod, $storagePath, $sim);
    if ( "$errorStatusFetchFiles" == 1 ) {
        exit (206);
    }
} else {
    my $errorStatusFetchFiles = &fetchFiles($fetchSimsMethod, $storagePath);
    if ( "$errorStatusFetchFiles" == 1 ) {
        exit (206);
    }
}

if (! open listSim, "<", "$PWD/../dat/listSimulation.txt") {
    print "ERROR: Could not open file $PWD/../dat/listSimulation.txt.\n";
    exit(203);
}

@simNamesArray = <listSim>;
close listSim;
  if(!@simNamesArray ){
     LogFiles("ERROR: There are no Simulations in specifed criteria or path\n");
    exit;
    }
}


foreach (@simNamesArray) {
    LogFiles("INFO: $_");
}
my $totalNumOfSim = @simNamesArray;
my $simNameCount  = 0;
LogFiles("INFO: no of sims in listSimulation.txt are $totalNumOfSim\n");

#--------------------------------------------------------------------
#Check Netsim is usable
#-------------------------------------------------------------------
LogFiles("INFO: Checking whether NETSim is up and running\n");
my $errorStatusCheckNetsim = &checkNetsim();
if ( "$errorStatusCheckNetsim" == 1 ) {
    LogFiles("ERROR: Unable to send command to NETSim\n");
    LogFiles("INFO: Trying to restart NETSim");
    system("/netsim/inst/restart_netsim fast");

    $errorStatusCheckNetsim = &checkNetsim();
    if ( "$errorStatusCheckNetsim" == 1 ) {
        die ("NETSim is NOT running: $! \n");
   }
}
LogFiles("INFO: NETSim is up and running\n");


#--------------------------------------------------------------------
#Check free ips
#-------------------------------------------------------------------
LogFiles("INFO: Checking is there any virtual ipv4 address\n");
my $errorStatusFetchFreeIp = &fetchFirstFreeIp();
if ( "$errorStatusFetchFreeIp" == 1 ) {
    LogFiles("ERROR: Unable to fetch free ips\n");
    die ("Exiting from rollut: $! \n");
}
LogFiles("INFO: There are some virtual ipv4 addresses\n");

#--------------------------------------------------------------------
#Creating the Ports
#-------------------------------------------------------------------
#LogFiles("INFO: Creating all possible kinds of ports\n");
#my $errorStatusCreatePort = &createPort($defaultDestination);
#if ( "$errorStatusCreatePort" == 1 ) {
#    LogFiles("ERROR: Unable to create ports \n");
#    die ("Exiting from rollut: $! \n");
#}

#---------------------------------------------------
#Start of Rollout functionality to individual sims
#---------------------------------------------------
foreach my $simName (@simNamesArray) {
    LogFiles("INFO: Starting rolling out functionality for individual sims\n");
    $simNameCount++;
    chomp($simName);
    if (! open FH, "+>>", "$PWD/../dat/listSimulationPass.txt") {
        print "ERROR: Could not open file $PWD/../dat/listSimulationPass.txt.\n";
        exit(203);
    }

    #---------------------------------------------------
    #Function call to open simulation
    #---------------------------------------------------
    LogFiles("INFO: ($simNameCount\/$totalNumOfSim) Opening simulation \n");

    #---------------------------------------------------
    #Function call to read simulation data
    #---------------------------------------------------
    #The values read are NE Type and NE Name
    LogFiles("INFO: ($simNameCount\/$totalNumOfSim) Reading simulation data \n");
    my $errorStatusReadSimData = &readSimData( $simName, $simNameCount, $totalNumOfSim );
    if ( "$errorStatusReadSimData" == 1 ) {
        next;
    }
    if (! -e "$PWD/../dat/dumpNeName.txt") {
        print "ERROR: File $PWD/../dat/dumpNeName.txt doesn't exist.\n";
        exit(206);
    }
    if (! open listNeName, "<", "$PWD/../dat/dumpNeName.txt") {
        print "ERROR: Could not open file $PWD/../dat/dumpNeName.txt.\n";
        exit(203);
    }
    if (! -e "$PWD/../dat/dumpNeType.txt") {
        print "ERROR: File $$PWD/../dat/dumpNeType.txt doesn't exist.\n";
        exit(206);
    }
    if (! open listNeType, "<", "$PWD/../dat/dumpNeType.txt") {
        print "ERROR: Could not open file $PWD/../dat/dumpNeType.txt.\n";
        exit(203);
    }
    my @NeNames = <listNeName>;
    my @NeType  = <listNeType>;
    close(listNeName);
    close(listNeType);
   #Appending Netypes array into a variable
   my $neTypes= join(":",  uniq @NeType);
   #---------------------------------------------------
   #Function call to decision Making Module
   #---------------------------------------------------
   #The decision moudle decides and returns the port the needs to be created
   #The Number of IPs we need for the simulation and Security type Sl3 or TLS or
   #nonw
    LogFiles("INFO: ($simNameCount\/$totalNumOfSim) Decision making module is starting \n");
    ( my $errorStatusDecisionModule ) =
      &decisionModule( $NeType[0], $simName, $simNameCount, $totalNumOfSim, $release, $securityStatusTLS, $ipv6Per);
    if ( "$errorStatusDecisionModule" == 1 ) {
        die("ERROR: Terminating rollout due to above error: $! \n");
    }
    if (! -e "$PWD/../dat/dumpDecisionParams.txt") {
        print "ERROR: File $PWD/../dat/dumpDecisionParams.txt doesn't exist.\n";
        exit(206);
    }
    if (! open DUMPDECISIONPARAMS, "<", "$PWD/../dat/dumpDecisionParams.txt") {
        print "ERROR: Could not open file $PWD/../dat/dumpDecisionParams.txt.\n";
        exit(203);
    }
    my @decisionParams = <DUMPDECISIONPARAMS>;
    close DUMPDECISIONPARAMS;

    my $simPort = $decisionParams[0];
    chomp($simPort);
    my $simDDPort = $decisionParams[1];
    chomp($simDDPort);
    my $numOfIpv4Nes = $decisionParams[2];
    chomp($numOfIpv4Nes);
    my $numOfIpv6Nes = $decisionParams[3];
    chomp($numOfIpv6Nes);

    LogFiles
"INFO: ($simNameCount\/$totalNumOfSim) Successfully fetched SIMPORT=$simPort; SIMDDPORT=$simDDPort; IPv4=$numOfIpv4Nes, IPv6=$numOfIpv6Nes for $simName\n";

    #
    #---------------------------------------------------
    #Function call to get an array of required free IPs
    #---------------------------------------------------
    my $errorStatusFetchFreeIps = &fetchFreeIps( $numOfIpv4Nes, $numOfIpv6Nes, $simNameCount, $totalNumOfSim );
    if ( "$errorStatusFetchFreeIps" == 1 ) {
        next;
    }
    open listIps, "$PWD/../dat/free_IpAddr_IPv4.txt";
    my @freeIps = <listIps>;
    close(listIps);

    #
    #--------------------------------------------------
    #Function call to assign Port
    #--------------------------------------------------
    my @slicedIpAddress = split( /\./, $freeIps[0] );
    chomp($simPort);
    my $portName = $simPort;
    my $errorStatusAssignPort = &assignPort( $simName, $simPort, $portName, $defaultDestination,
        $simNameCount, $totalNumOfSim, $securityStatusTLS, $switchToRvConf, $ipv6Per );
    if ( "$errorStatusAssignPort" == 1 ) {
        next;
    }

    #--------------------------------------------------
    #Set /pms_tmpfs
    #--------------------------------------------------
    #if ( $docker !~ m/yes/i ) {
        my $errorStatusSetTmpFs = &setTmpFs($simName, $simNameCount, $totalNumOfSim);
        if ( "$errorStatusSetTmpFs" == 1 ){
            next;
        }
    #} else {
    #    LogFiles"INFO: ($simNameCount\/$totalNumOfSim) Tmpfs setting is not applied! )";
    #}
    #----------------------------------------------------------
    #Function call to set EM support for ERBS nodes
    #----------------------------------------------------------
    my $checkForEm = &isLteCppErbsSim( $simName, $neTypes, $simNameCount, $totalNumOfSim );
    my $numOfVappNes = 5;
    my $vmStartNe = 86;
    my $vmEndNe = 87;
    my $contentFile1_8K = &sims1_8KContent();
    if ($checkForEm == 0) {
       &setEmForErbs( $simNameCount, $totalNumOfSim, $simName, $serverType, $numOfVappNes, $vmStartNe, $vmEndNe, $contentFile1_8K );
    }

    #---------------------------------------------------
    #Function call to start the NEs
    #---------------------------------------------------
    $PWD = `pwd`;
    chomp($PWD);
    my $numOfNodes = 0;
    $numOfIpv6Nes = 0;
    my $all = '';
    my $errorStatusStartFiveNodes = 0;
    if (lc "$securityStatusTLS" eq lc "ON"
        && ($neTypes =~ m/MSRBS-V/i
            || $neTypes =~ m/ESAPC/i
	    || $neTypes =~ m/CONTROLLER6610/i
            || $neTypes =~ m/WCDMA PRBS/i
            || $neTypes =~ m/EPG-SSR/i
            || $neTypes =~ m/EPG-EVR/i
            || $neTypes =~ m/TCU03/i
            || $neTypes =~ m/TCU04/i
            || $neTypes =~ m/C608/i
            || $neTypes =~ m/ECM/i
            || $neTypes =~ m/RAN-VNFM/i
            || $neTypes =~ m/EVNFM/i
            || $neTypes =~ m/VNF-LCM/i
            || ( $neTypes =~ m/RNNODE/i && $simName =~ m/TLS/i)
            || ( $neTypes =~ m/vPP/i && $simName =~ m/TLS/i)
            || ( $neTypes =~ m/vRC/i && $simName =~ m/TLS/i)
            || ($neTypes =~ m/O1/i && $simName=~ m/O1/i )
            || ($neTypes =~ m/oRU/i && $simName=~ m/ORU/i )
            || ($neTypes =~ m/vDU/i && $simName=~ m/ORU/i )
            || ( $neTypes =~ m/MRSv/i &&  $simName =~ m/vBGF/i)
            || ($neTypes =~ m/MTAS.*CORE/i && $simName =~ m/MTAS/i)
            || $neTypes =~ m/VTFRadioNode/i
            || $neTypes =~ m/5GRadioNode/i
            || $neTypes =~ m/VTIF/i
            || $neTypes =~ m/vSD/i
            || $neTypes =~ m/SpitFire.*17B/i
            || $neTypes =~ m/R6274/i
            || $neTypes =~ m/R6273/i
            || $neTypes =~ m/R6672/i
            || $neTypes =~ m/R6673/i
            || $neTypes =~ m/R6675/i
            || $neTypes =~ m/HP_NFVO/i)
            || $neTypes =~ m/R6371/i
            || $neTypes =~ m/R6471-1/i
            || $neTypes =~ m/R6471-2/i 
            || $neTypes =~ m/R6676/i
            || $neTypes =~ m/R6678/i
            || $neTypes =~ m/R6671/i) {
    } elsif (lc "$securityStatusSL2" eq lc "ON"
          && ( $neTypes =~ /^LTE ERBS/i
              || $neTypes =~/MGw/i
              || ($neTypes =~ /WCDMA RNC/i
                  && $simName =~ /-RBS/i ))) {
     } else {
        if (lc "$serverType" eq lc "VAPP") {
            $numOfNodes = 0;
            $numOfIpv6Nes = 0;
        }
        elsif (lc "$serverType" eq lc "VM") {
            my $file = &sims1_8KContent();
            if ("$file") {
                $numOfNodes = 2;
                $numOfIpv6Nes = 1;
           }
           else {
               $all = "-all";
           }
        }
    }
    #
    #-------------------------------------------------------------------------------------------------
    #Function call to create ARNE XML and UNIX users based on the parameter ARNE_FILE_GENERATION
    #---------------------------------------------------------------------------------------------------
     $PWD = `pwd`;
     chomp($PWD);
     my $confPath = "$PWD/../conf/conf.txt";
     (my $arneFileGeneration) = &readConfig($confPath, $simNameCount, $totalNumOfSim );
     if ( $arneFileGeneration eq "ON" ) {
         chomp( $NeType[0] );
         my $NeTypeName = "\"$NeType[0]\"";
         my $errorStautsCreateArneUnix =
         &createArneUnix( $simName, $NeTypeName, $simNameCount, $totalNumOfSim );
            if ( "$errorStautsCreateArneUnix" == 1 ) {
                 next;
            }

            #
            #-----------------------------------------------------
            #Function call to apply ARNE XML workaround
            #-----------------------------------------------------
            my $errorStatusWorkAroundXML =
              &workAroundXML( $simName, $simNameCount, $totalNumOfSim );
            if ( "$errorStatusWorkAroundXML" == 1 ) {
                next;
            }

    } else {
        LogFiles(
            "INFO: ($simNameCount\/$totalNumOfSim) ARNE files are not generated as ARNE_FILE_GENERATION=OFF\n"
        );
    }

#
#-----------------------------------------------------
#To help in making a Brief summary report.
#----------------------------------------------------
#The idea being if the simulation has rolled out with out any erro we can conclude that the simulation is ONLINE
#Replace this with an array and do file handling only once instead of everytime it passes
    if (lc "$securityStatusTLS" eq lc "ON"
        && ( ( $neTypes =~ m/MSRBS-V/i && $simName !~ m/NRAT-SSH/i)
             || $neTypes =~ m/ESAPC/i
	     || $neTypes =~ m/CONTROLLER6610/i
             || $neTypes =~ m/WCDMA PRBS/i
             || $neTypes =~ m/EPG-SSR/i
             || $neTypes =~ m/EPG-EVR/i
             || $neTypes =~ m/TCU03/i
             || $neTypes =~ m/TCU04/i
             || $neTypes =~ m/C608/i
             || $neTypes =~ m/ECM/i
             || $neTypes =~ m/RAN-VNFM/i
             || $neTypes =~ m/EVNFM/i
             || $neTypes =~ m/VNF-LCM/i
             || ( $neTypes =~ m/RNNODE/i && $simName =~ m/TLS/i )
             || ( $neTypes =~ m/vPP/i && $simName =~ m/TLS/i)
             || ( $neTypes =~ m/vRC/i && $simName =~ m/TLS/i)
             || ( $neTypes =~ m/vDU/i && $simName =~ m/5G116/i )
             || ( $neTypes =~ m/LTE SCU/i && $simName !~ m/ERS-SN/i)
             || ($neTypes =~ m/O1/i && $simName=~ m/O1/i )
             || ($neTypes =~ m/oRU/i && $simName=~ m/ORU/i )
             || ($neTypes =~ m/vDU/i && $simName=~ m/ORU/i )
             || ( $neTypes =~ m/MRSv/i &&  $simName =~ m/vBGF/i)
             || ($neTypes =~ m/MTAS.*CORE/i && $simName =~ m/MTAS/i)
             || $neTypes =~ m/VTFRadioNode/i
             || $neTypes =~ m/5GRadioNode/i
             || $neTypes =~ m/VTIF/i
             || $neTypes =~ m/vSD/i
             || $neTypes =~ m/SpitFire.*17B/i
             || $neTypes =~ m/R6274/i
             || $neTypes =~ m/R6273/i
             || $neTypes =~ m/R6672/i
             || $neTypes =~ m/R6673/i
             || $neTypes =~ m/R6675/i)
            || $neTypes =~ m/R6371/i
            || $neTypes =~ m/R6471-1/i
            || $neTypes =~ m/R6471-2/i
            || $neTypes =~ m/R6676/i
            || $neTypes =~ m/R6678/i
            || $neTypes =~ m/R6671/i) {
        LogFiles("INFO: ($simNameCount\/$totalNumOfSim) $simName will be configured for TLS security\n");
    } elsif (lc "$securityStatusSL2" eq lc "ON"
        && ($neTypes =~ /^LTE ERBS/i
             || $neTypes =~/MGw/i
             || ($neTypes =~ /WCDMA RNC/i
                 && $simName =~ /-RBS/i ))) {
        LogFiles("INFO: ($simNameCount\/$totalNumOfSim) $simName will be configured for SL2 security\n");
    } else {
        LogFiles("INFO: ($simNameCount\/$totalNumOfSim) $simName rollout complete without security\n");
        print FH "$simName\n";
    }
    close FH;
}

#------------------------------------------------------
