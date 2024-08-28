#!/usr/bin/perl -w
use Expect;
use Getopt::Long();
use Net::OpenSSH;
use Cwd 'abs_path';
use Config::Tiny;
###################################################################################
#
#     File Name : invokeSimNetDeployer.pl
#
#     Version : 15.00
#
#     Author : Jigar Shah
#
#     Description : This script will rollout the network for Feature Test on a cloud envrionment.
#
#     Date Created : 25 March 2014
#
#     Syntax : ./invokeSimNetDeployer.pl
#
#     Patameters :
#
#     Example :  ./invokeSimNetDeployer.pl
#
#     Dependencies :
#
#     NOTE: 1. You can find real time execution logs of this script at /tmp/invokeSimNetDeployer.txt
#
#     Return Values : 1 - 1.1 - Not a root user
#                       - 1.2 - Script usage incorrect
#                     2 - Stautus - ONLINE / OFFLINE
#
###################################################################################
#
#---------------------------------------------------------------------------------
#variables
#---------------------------------------------------------------------------------
$dateVar = `date +%F`;
chomp($dateVar);
$timeVar = `date +%T`;
chomp($timeVar);
$logFileName = "invokeSimNetDeployerLogs_$dateVar\_$timeVar.log";
if (! open LOGFILEHANDLER, "+>>", "../log/$logFileName") {
    print "ERROR: Could not open log file.\n";
    exit(203);
}
my $simsFetched = 1;
my @networksRolledOut = ();
my $isImportSuccessful = 0;

#
#----------------------------------------------------------------------------------
#SubRoutine to capture Logs
#----------------------------------------------------------------------------------
#
sub LogFiles {
    $dateVar = `date +%F`;
    chomp($dateVar);
    $timeVar = `date +%T`;
    chomp($timeVar);
    my $hostName = `hostname`;
    chomp($hostName);
    $LogVar = $_[0];
    chomp($LogVar);
    $substring = "ERROR:";
    if (index("$LogVar", $substring) != -1) {
        print LOGFILEHANDLER "$timeVar:<$hostName>: $LogVar in module $0\n";
        print "$timeVar:<$hostName>: $LogVar in module $0 \n";
    }
    else {
        print LOGFILEHANDLER "$timeVar:<$hostName>: $LogVar\n";
        print "$timeVar:<$hostName>: $LogVar\n";
    }

}


#
#---------------------------------------------------------------------------------
#Function call to read oss track
#---------------------------------------------------------------------------------
sub readOssTrack {
    LogFiles("INFO: Accessing OSS Master to read oss track\n");

    #Creating SSH object
    my $hostOssmaster   = "$ossmasterName";
    my $userOssmaster   = "$ossmasterUser";
    my $passwdOssmaster = "$ossmasterPass";
    my $sshOssmaster    = Net::OpenSSH->new(
        $hostOssmaster,
        user        => $userOssmaster,
        password    => $passwdOssmaster,
        master_opts => [ -o => "StrictHostKeyChecking=no" ]
    );
    my ( $outputOssmaster, $errputOssmaster ) =
      $sshOssmaster->capture2( { timeout => 1 },
        "cat  /var/opt/ericsson/sck/data/cp.status" );
    if($sshOssmaster->error){
        LogFiles "ERROR: ssh failed: " . $sshOssmaster->error . "\n";
        if ("$errputOssmaster") {
            LogFiles("$errputOssmaster");
        }
        exit(204);
    }


    my @cpStatusDat   = split( / /, $outputOssmaster );
    my @ossTrackField = split( /_/, $cpStatusDat[1] );
    my $ossTrack      = $ossTrackField[4];
    return $ossTrack;
}

#
#---------------------------------------------------------------------------------
#Function call to read config file
#---------------------------------------------------------------------------------
sub readConfig {
    my $path = $_[0];
    if (! -e $path) {
        LogFiles "ERROR: File $path doesn't exist.\n";
        exit(206);
    }
    LogFiles("INFO: Reading config file from $path \n");
    if (! open CONF, "<", "$path") {
        LogFiles "ERROR: Could not open file $path.\n";
        exit(203);
    }
    my @conf = <CONF>;
    close(CONF);
    $numOfUserEnteredPath = 0;
    foreach (@conf) {
        next if /^#/;
        if ( "$_" =~ "FETCH_SIM_FROM_DEFAULT_PATH" ) {
            @fetchSimFromDefaultPath = split( /=/, $_ );
        }
        elsif ( $_ =~ "ROLLOUT_LTE" ) {
            @networkFlagLte = split( /=/, $_ );
        }
        elsif ( $_ =~ "ROLLOUT_WRAN" ) {
            @networkFlagWran = split( /=/, $_ );
        }
        elsif ( $_ =~ "ROLLOUT_GRAN" ) {
            @networkFlagGran = split( /=/, $_ );
        }
        elsif ( $_ =~ "ROLLOUT_CORE" ) {
            @networkFlagCore = split( /=/, $_ );
        }
        elsif ( $_ =~ "ROLLOUT_PICO" ) {
            @networkFlagPico = split( /=/, $_ );
        }
        elsif ( $_ =~ "SETUP_SECURITY_TLS" ) {
            @securityStatusTLSEdit = split( /=/, $_ );
        }
        elsif ( $_ =~ "SETUP_SECURITY_SL3" ) {
            @securityStatusSL3Edit = split( /=/, $_ );
        }
        elsif ( $_ =~ "IMPORT_ARNE_XMLS_ON_TO_OSS" ) {
            @importStatusEdit = split( /=/, $_ );
        }
        elsif ( $_ =~ "COPY_ARNE_TO_DEFAULT_LOCATION" ) {
            @copyArneToDefaultLocationEdit = split( /=/, $_ );
        }
        elsif ( $_ =~ "HOST_FOLDER_TO_COPY_ARNE_XMLS" ) {
            @hostFolderToCopyArneXmlEdit = split( /=/, $_ );
        }
        elsif ( $_ =~ "OSS_MASTER_SERVER" ) {
            @ossmasterNameEdit = split( /=/, $_ );
        }
        elsif ( $_ =~ "OSS_MASTER_USER" ) {
            @ossmasterUserEdit = split( /=/, $_ );
        }
        elsif ( $_ =~ "OSS_MASTER_PASS" ) {
            @ossmasterPassEdit = split( /=/, $_ );
        }
        elsif ( $_ =~ "NETSIM_SERVER" ) {
            @netsimNameEdit = split( /=/, $_ );
        }
        elsif ( $_ =~ "NETSIM_USER" ) {
            @netsimUserEdit = split( /=/, $_ );
        }
        elsif ( $_ =~ "NETSIM_PASS" ) {
            @netsimPassEdit = split( /=/, $_ );
        }
        elsif ( $_ =~ "OMSAS_SERVER" ) {
            @omsasNameEdit = split( /=/, $_ );
        }
        elsif ( $_ =~ "OMSAS_USER" ) {
            @omsasUserEdit = split( /=/, $_ );
        }
        elsif ( $_ =~ "OMSAS_PASS" ) {
            @omsasPassEdit = split( /=/, $_ );
        }
        elsif ( $_ =~ /^FETCH_SIM_FROM_PATH*/ ) {
            @fetchSimFromPath = split( /=/, $_ );
            chomp( $fetchSimFromPath[1] );
            $listOfSimPath[ $numOfUserEnteredPath++ ] = $fetchSimFromPath[1];
        }
        elsif ( $_ =~ "FETCH_FROM_FTP" ) {
            @fetchfromftpEdit = split( /=/, $_ );
        }
        elsif ( $_ =~ "CHECK_SYNC_STATUS" ) {
            @checkSyncStatusArr= split( /=/, $_ );
        }
        elsif ( $_ =~ "SWITCH_TO_ENM" ) {
            @switchToEnmEdit= split( /=/, $_ );
        }
       elsif ( $_ =~ "ARNE_FILE_GENERATION" ) {
           @arneFileGenerationEdit = split( /=/, $_ );
        }
       elsif ( $_=~"SERVER_TYPE" ) {
           @serverTypeEdit = split( /=/, $_ );
        }
        elsif ( $_=~"SWITCH_TO_RV" ) {
           @switchToRvEdit = split( /=/, $_ );
       }
       elsif ( $_=~"DEFAULT_DESTINATION" ) {
           @defaultDestinationEdit = split( /=/, $_ );
        }
       elsif ( $_=~"ENM_MASTER_SERVER" ) {
           @masterServerEdit = split( /=/, $_ );
       }
       elsif ( $_=~"ENM_MASTER_USER" ) {
           @masterUserEdit = split( /=/, $_ );
       }
       elsif ( $_=~"ENM_MASTER_PASS" ) {
           @masterPassEdit = split( /=/, $_ );
       }
    }
    chomp( $fetchSimFromDefaultPath[1] );
    my $fetchSimFromDefaultPath = $fetchSimFromDefaultPath[1];
    chomp( $networkFlagLte[1] );
    my $networkFlagLte = $networkFlagLte[1];
    chomp( $networkFlagWran[1] );
    my $networkFlagWran = $networkFlagWran[1];
    chomp( $networkFlagGran[1] );
    my $networkFlagGran = $networkFlagGran[1];
    chomp( $networkFlagCore[1] );
    my $networkFlagCore = $networkFlagCore[1];
    chomp( $networkFlagPico[1] );
    my $networkFlagPico = $networkFlagPico[1];
    chomp( $securityStatusTLSEdit[1] );
    my $securityStatusTLS = $securityStatusTLSEdit[1];
    chomp( $securityStatusSL3Edit[1] );
    my $securityStatusSL3 = $securityStatusSL3Edit[1];
    chomp( $copyArneToDefaultLocationEdit[1] );
    my $copyArneToDefaultLocation = $copyArneToDefaultLocationEdit[1];
    chomp( $hostFolderToCopyArneXmlEdit[1] );
    my $hostFolderToCopyArneXml = $hostFolderToCopyArneXmlEdit[1];
    chomp( $ossmasterNameEdit[1] );
    my $ossmasterNameVar = $ossmasterNameEdit[1];
    chomp( $ossmasterUserEdit[1] );
    my $ossmasterUserVar = $ossmasterUserEdit[1];
    chomp( $ossmasterPassEdit[1] );
    my $ossmasterPassVar = $ossmasterPassEdit[1];
    chomp( $netsimNameEdit[1] );
    my $netsimNameVar = $netsimNameEdit[1];
    chomp( $netsimUserEdit[1] );
    my $netsimUserVar = $netsimUserEdit[1];
    chomp( $netsimPassEdit[1] );
    my $netsimPassVar = $netsimPassEdit[1];
    chomp( $omsasNameEdit[1] );
    my $omsasNameVar = $omsasNameEdit[1];
    chomp( $omsasUserEdit[1] );
    my $omsasUserVar = $omsasUserEdit[1];
    chomp( $omsasPassEdit[1] );
    my $omsasPassVar = $omsasPassEdit[1];
    chomp($fetchfromftpEdit[1] );
    my $fetchfromftpvar = $fetchfromftpEdit[1];
    chomp( $importStatusEdit[1] );
    my $importStatus = $importStatusEdit[1];
    chomp( $checkSyncStatusArr[1] );
    my $checkSyncStatus = $checkSyncStatusArr[1];
    chomp($switchToEnmEdit[1] );
    my $switchToEnmVar = $switchToEnmEdit[1];
    chomp( $arneFileGenerationEdit[1] );
    my $arneFileGenerationVar = $arneFileGenerationEdit[1];
    chomp ( $serverTypeEdit[1] );
    my $serverTypeVar = $serverTypeEdit[1];
    chomp ( $defaultDestinationEdit[1] );
    my $defaultDestinationVar = $defaultDestinationEdit[1];
    chomp ( $masterServerEdit[1] );
    my $masterServerVar = $masterServerEdit[1];
    chomp ( $masterUserEdit[1] );
    my $masterUserVar = $masterUserEdit[1];
    chomp ( $masterPassEdit[1] );
    my $masterPassVar = $masterPassEdit[1];
    chomp ( $switchToRvEdit[1] );
    my $switchToRv = $switchToRvEdit[1];

    if ( "$fetchSimFromDefaultPath" eq "YES" ) {
        @listOfSimPath = ();
    }
    return (
        $securityStatusTLS,       $securityStatusSL3,
        $importStatus,            $fetchSimFromDefaultPath,
        $networkFlagLte,          $networkFlagWran,
        $networkFlagGran,         $networkFlagCore,
        $networkFlagPico,         $copyArneToDefaultLocation,
        $hostFolderToCopyArneXml, $ossmasterNameVar,
        $ossmasterUserVar,        $ossmasterPassVar,
        $netsimNameVar,           $netsimUserVar,
        $netsimPassVar,           $omsasNameVar,
        $omsasUserVar,            $omsasPassVar,
        $fetchfromftpvar,         $checkSyncStatus,
        $switchToEnmVar,          $arneFileGenerationVar,
        $serverTypeVar,           $switchToRv,
        $defaultDestinationVar,   $masterServerVar,
        $masterUserVar,           $masterPassVar,
       @listOfSimPath,
    );
}

#
#---------------------------------------------------------------------------------
#Function call to read simulation storage path
#-------------------------------------------------------------------------------
sub readSimulationStoragePath {
    (
        my $ossTrackAdd,
        my $networkFlagLte,
        my $networkFlagWran,
        my $networkFlagGran,
        my $networkFlagCore,
        my $networkFlagPico,
        my $fetchFromFtp,
        my $switchToEnm,
        my $deploymentType
    ) = @_;
    $arrayIndex = 0;
    my $LTEPath;
    my $GRANPath;
    my $WRANPath;
    my $COREPath;
    my $PICOPath;

    if("$switchToEnm" eq "NO") {
        @ossTrackCompenents = split( /\./, $ossTrackAdd );

        # print "\$ossTrackCompenents[0] = $ossTrackCompenents[0]\n";
        my $majorOSSRelease = "O" . $ossTrackCompenents[0];
        # print "\$majorOSSRelease = $majorOSSRelease \n";

        if ( "$networkFlagLte" eq "YES" ) {
            if("$fetchFromFtp" eq "YES"){
                $LTEPath = '/sims/'
                . $majorOSSRelease
                . '/FeatureTest/'
                . "$ossTrackAdd"
                . '/LTE/LATEST';
            }
            else {
                $LTEPath =
                'LTE/FT/ALL/'
                . "$ossTrackAdd"
                . '/LATEST';
            }
        }
        if ( "$networkFlagWran" eq "YES" ) {
            if("$fetchFromFtp" eq "YES"){
                $WRANPath =
                '/sims/'
                . $majorOSSRelease
                . '/FeatureTest/'
                . "$ossTrackAdd"
                . '/WRAN/LATEST';
            }
            else {
                $WRANPath =
                'WRAN/FT/ALL/'
                . "$ossTrackAdd"
                . '/LATEST';
            }
        }
        if ( "$networkFlagGran" eq "YES" ) {
            if("$fetchFromFtp" eq "YES"){
                 $GRANPath =
                '/sims/'
                . $majorOSSRelease
                . '/FeatureTest/'
                . "$ossTrackAdd"
                . '/GRAN/LATEST';
            }
            else {
                $GRANPath =
                'GRAN/FT/ALL/'
                . "$ossTrackAdd"
                . '/LATEST';
            }
        }
        if ( "$networkFlagCore" eq "YES" ) {
            if("$fetchFromFtp" eq "YES"){
                $COREPath =
                '/sims/'
                . $majorOSSRelease
                . '/FeatureTest/'
                . "$ossTrackAdd"
                . '/CORE/LATEST';
            }
            else {
                $COREPath =
                'CORE/FT/ALL/'
                . "$ossTrackAdd"
                . '/LATEST';
            }
        }
        if ( "$networkFlagPico" eq "YES" ) {
            if("$fetchFromFtp" eq "YES"){
                $PICOPath =
                '/sims/'
                . $majorOSSRelease
                . '/FeatureTest/'
                . "$ossTrackAdd"
                . '/PICO/LATEST';
            }
            else {
                $PICOPath =
                'PICO/FT/ALL/'
                . "$ossTrackAdd"
                . '/LATEST';
            }
        }
    }
    else {
        @ossTrackCompenents = split( /\./, $ossTrackAdd );

        # print "\$ossTrackCompenents[0] = $ossTrackCompenents[0]\n";
        my $majorOSSRelease = "O" . $ossTrackCompenents[0];
        #print "\$majorOSSRelease = $majorOSSRelease \n";

        if ( "$networkFlagLte" eq "YES" ) {
            if("$fetchFromFtp" eq "YES"){
                $LTEPath =
                '/sims/'
                .$majorOSSRelease
                .'/ENM/'
                . "$ossTrackAdd"
                ."/$deploymentType"
                . '/LTE/'
                .'5KLTE/';
            }
            else {
                $LTEPath =
                '/sims/portal/LTE/'
                . "$ossTrackAdd";
            }
        }
        if ( "$networkFlagWran" eq "YES" ) {
            if("$fetchFromFtp" eq "YES"){
                $WRANPath =
                '/sims/'
                .$majorOSSRelease
                .'/ENM/'
                . "$ossTrackAdd"
                ."/$deploymentType"
                . '/WRAN/';
            }
            else {
                $WRANPath =
                '/sims/portal/WRAN/'
                . "$ossTrackAdd";
            }
        }
        if ( "$networkFlagGran" eq "YES" ) {
            if("$fetchFromFtp" eq "YES"){
                $GRANPath =
                '/sims/'
                .$majorOSSRelease
                .'/ENM/'
                . "$ossTrackAdd"
                ."/$deploymentType"
                . '/GRAN/';
            }
            else {
                $GRANPath =
                '/sims/portal/GRAN/'
                . "$ossTrackAdd";
            }
        }
        if ( "$networkFlagCore" eq "YES" ) {
            if("$fetchFromFtp" eq "YES"){
                $COREPath =
                '/sims/'
                .$majorOSSRelease
                .'/ENM/'
                . "$ossTrackAdd"
                ."/$deploymentType"
                . '/CORE/';
            }
            else {
                $COREPath =
                '/sims/portal/CORE/'
                . "$ossTrackAdd";
            }
        }
        if ( "$networkFlagPico" eq "YES" ) {
            if("$fetchFromFtp" eq "YES"){
                $PICOPath =
                '/sims/'
                .$majorOSSRelease
                .'/ENM/'
                . "$ossTrackAdd"
                ."/$deploymentType"
                . '/PICO/';
            }
            else {
                $PICOPath =
                '/sims/portal/PICO/'
                . "$ossTrackAdd";
            }
        }
    }
    return (
            $LTEPath,
            $GRANPath,
            $WRANPath,
            $COREPath,
            $PICOPath
          );
}

sub readSimulationStoragePathNonDefault {
    (
        my $simulationStoragePathNonDefault,
        my $networkFlagLte,
        my $networkFlagWran,
        my $networkFlagGran,
        my $networkFlagCore,
        my $networkFlagPico
    ) = @_;
    $arrayIndex = 0;
    my $LTEPath;
    my $GRANPath;
    my $WRANPath;
    my $COREPath;
    my $PICOPath;
    if ( "$networkFlagLte" eq "YES" ) {
        print "networkFlagLte= $networkFlagLte\n";
        foreach (@$simulationStoragePathNonDefault) {
            if ( "$_" =~ /lte/i || /pico/i ) {
                $LTEPath = $_;
                last;
            }
        }
    }
    if ( "$networkFlagWran" eq "YES" ) {
        print "networkFlagWran= $networkFlagWran\n";
        foreach (@$simulationStoragePathNonDefault) {
            if ( "$_" =~ /wran/i ) {
                $WRANPath = $_;
                last;
            }
        }
    }
    if ( "$networkFlagGran" eq "YES" ) {
        print "networkFlagGran= $networkFlagGran\n";
        foreach (@$simulationStoragePathNonDefault) {
            if ( "$_" =~ /gran/i ) {
                $GRANPath = $_;
                last;
            }
        }
    }
    if ( "$networkFlagCore" eq "YES" ) {
        print "networkFlagCore= $networkFlagCore\n";
        foreach (@$simulationStoragePathNonDefault) {
            if ( "$_" =~ /core/i ) {
                $COREPath = $_;
                last;
            }
        }
    }
    if ( "$networkFlagPico" eq "YES" ) {
        print "networkFlagPico= $networkFlagPico\n";
        foreach (@$simulationStoragePathNonDefault) {
            if ( "$_" =~ /pico/i ) {
                $PICOPath = $_;
                last;
            }
        }
    }
    return (
            $LTEPath,
            $GRANPath,
            $WRANPath,
            $COREPath,
            $PICOPath
          );
}

#
#---------------------------------------------------------------------------------
#Function call to get working directory
#---------------------------------------------------------------------------------
sub getWorkingPath {
    ( my $checkPath, my $osstrack ) = @_;
    if ( "$checkPath" =~ /lte/i ) {
        $returnWorkingPath = "/tmp/LTE/$simLTE/simNetDeployer/" . "$osstrack\/";
    }
    elsif ( "$checkPath" =~ /wran/i ) {
        $returnWorkingPath = "/tmp/WRAN/$simWRAN/simNetDeployer/" . "$osstrack\/";
    }
    elsif ( "$checkPath" =~ /gran/i ) {
        $returnWorkingPath = '/tmp/GRAN/simNetDeployer/' . "$osstrack\/";
    }
    elsif ( "$checkPath" =~ /core/i ) {
        $returnWorkingPath = "/tmp/CORE/$simCORE/simNetDeployer/" . "$osstrack\/";
    }
    elsif ( "$checkPath" =~ /pico/i ) {
        $returnWorkingPath = '/tmp/PICO/simNetDeployer/' . "$osstrack\/";
    }
    else {
        $returnWorkingPath = '/tmp/simNetDeployer' . "$osstrack\/";
    }
    return $returnWorkingPath;
}

#
#---------------------------------------------------------------------------------
#SubRoutine to verify connectivity and set up the environmnet on NETSim
#---------------------------------------------------------------------------------
#
sub setupEnvNetsim {

    #Variables declarations
    my $dirSimNetDeployer = $_[0];

    #This variable contains the present working directory path
    LogFiles("INFO: Setting up environment for the simNetDeployer on netsim\n");

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
    LogFiles("INFO: Accessing netsim=$hostNetsim to verify connectivity\n");
    $netSimSecurity = '/netsim/netsimdir/Security';
    LogFiles(
"INFO: Creating and Copying files to netsim under $dirSimNetDeployer on netsim\n"
    );
    $dirSimNetDeployerBin      = "$dirSimNetDeployer" . "bin\/";
    $dirSimNetDeployerConf     = "$dirSimNetDeployer" . "conf\/";
    $dirSimNetDeployerCert     = "$dirSimNetDeployer" . "certs\/";
    $dirSimNetDeployerDat      = "$dirSimNetDeployer" . "dat\/";
    $dirSimNetDeployerDatXML   = "$dirSimNetDeployer" . "dat\/" . "XML\/";
    $dirSimNetDeployerSecurity = "$dirSimNetDeployer" . "Security\/";
    $dirSimNetDeployerSecurityTLS =
      "$dirSimNetDeployer" . "Security\/" . "TLS\/";
    $dirSimNetDeployerSecuritySL2 =
      "$dirSimNetDeployer" . "Security\/" . "SL2\/";
    $dirSimNetDeployerSecuritySL3 =
      "$dirSimNetDeployer" . "Security\/" . "SL3\/";
    $dirSimNetDeployerDocs = "$dirSimNetDeployer" . "docs\/";
    $dirSimNetDeployerLogs = "$dirSimNetDeployer" . "logs\/";

    #$dirSimNetDeployerLib = "$dirSimNetDeployer"."lib\/";
    $dirSimNetDeployerUtils = "$dirSimNetDeployer" . "utils\/";
    my @cmdArrayNetsim = "
/netsim/inst/restart_gui;
mkdir -p $dirSimNetDeployer;
mkdir -p $dirSimNetDeployerBin;
mkdir -p $dirSimNetDeployerConf;
mkdir -p $dirSimNetDeployerCert;
mkdir -p $dirSimNetDeployerDat;
mkdir -p $dirSimNetDeployerDatXML;
mkdir -p $dirSimNetDeployerSecurity;
mkdir -p $dirSimNetDeployerSecurityTLS;
mkdir -p $dirSimNetDeployerSecuritySL2;
mkdir -p $dirSimNetDeployerSecuritySL3;
mkdir -p $dirSimNetDeployerDocs;
mkdir -p $dirSimNetDeployerLogs;
mkdir -p $dirSimNetDeployerUtils;
mkdir -p $netSimSecurity\/TLS;
mkdir -p $netSimSecurity\/SL2;
mkdir -p $netSimSecurity\/SL3;
chmod -R 777 $dirSimNetDeployer";
    my ( $outputNetsim, $errputNetsim ) =
      $sshNetsim->capture2( { timeout => 30 }, "@cmdArrayNetsim" );
    if($sshNetsim->error){
        LogFiles "ERROR: ssh failed: while creating folders " . $sshNetsim->error . "\n";
        if ("$errputNetsim") {
            LogFiles("$errputNetsim");
        }
#        exit(204);
    }
    my $gatewayNetsimBinPath     = "$simDepPath/netsim/";
    my $gatewayNetsimDatPath     = "$simDepPath/../dat/netsim/";
    my $gatewaySecurityDatPath   = "$simDepPath/../dat/masterserver/";
    my $gatewayNetsimConfPath    = "$simDepPath/../conf/";
    my $gatewayNetsimUtilsPath   = "$simDepPath/../utils/netsim/";
    my $gatewayNetsimCertPath    = "$simDepPath/../certs/";
    $timeout = 10;
    @cmd = "scp $gatewayNetsimBinPath\* root\@$netsimName:$dirSimNetDeployerBin;
scp $gatewayNetsimConfPath\* root\@$netsimName:$dirSimNetDeployerConf;
scp $gatewayNetsimDatPath\* root\@$netsimName:$dirSimNetDeployerDat;
scp $gatewaySecurityDatPath\* root\@$netsimName:$dirSimNetDeployerDat;
scp $gatewayNetsimUtilsPath\* root\@$netsimName:$dirSimNetDeployerUtils;
scp $gatewayNetsimCertPath\* root\@$netsimName:$dirSimNetDeployerCert;
scp $gatewayNetsimCertPath\* root\@$netsimName:$netSimSecurity\/TLS;
scp $gatewayNetsimCertPath\* root\@$netsimName:$netSimSecurity\/SL2";
    ( $pty, $pid ) = $sshNetsim->open2pty(@cmd);
    if($sshNetsim->error){
       LogFiles "ERROR: unable to run remote command @cmd" . $sshNetsim->error . "\n";
       exit(204);
    }
    $expect = Expect->init($pty);

    $expect->raw_pty(1);
    $expect->log_file( "../log/expect-copyFileToNetsim.pm_log", "w" );

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
    $fileName = "../log/expect-copyFileToNetsim.pm_log";
    &append($fileName);

#NOTE - Need to write a subroutine which will generate the ftp Services files and
#keep it under dat folder, presently we use temp files.
#Set up Security Folders
#
}
#
#---------------------------------------------------------------------------------
#SubRoutine to rollout nodes
#---------------------------------------------------------------------------------
#
sub rollout {
    LogFiles("INFO: Starting Rollout process on netsim\n");

    #Variable declarations
    ( my $path, my $address, my $dirSimNetDeployer ,my $serverType ,my $release , my $securityStatusTLS  ,my $ipv6per ,my $switchToRvConf ,my $sim ) = @_;

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
    LogFiles("INFO: The simulations are being rolled out on netsim now.\n");

    #LogFiles("Please login and refer to $dirSimNetDeployer/logs/simNetDeployerLogs.txt for more details \n");
    LogFiles "INFO: The Parameters passes are: \n";
    LogFiles "INFO: PATH_OF_SIMS_ON_STORAGE_DEVICE = $path \n";
    #LogFiles "INFO: IP_ADDRESS_OF_OSSMASTER = $ossmasterAddress \n";
    LogFiles "INFO: SIMNET_DEPLOYER_DIR = $dirSimNetDeployer\n";
    
    if (defined $sim) {
        @cmdArrayNetsim = "chmod u+x $dirSimNetDeployer/bin/rollout.pl;
        $dirSimNetDeployer/bin/rollout.pl $path $ossmasterAddress $dirSimNetDeployer $serverType $release $securityStatusTLS $ipv6per $switchToRvConf $sim";
    }
    else {
        @cmdArrayNetsim = "chmod u+x $dirSimNetDeployer/bin/rollout.pl;
        $dirSimNetDeployer/bin/rollout.pl $path $ossmasterAddress $dirSimNetDeployer $serverType $release $securityStatusTLS $ipv6per $switchToRvConf";
    }
    if ( ! -s "$dirSimNetDeployer/bin/rollout.pl" ){
        print "Failed to copy the content of bin folder so retrying it again\n";
        system("scp /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/* $dirSimNetDeployer/bin/");
        if ($? != 0){
           print "ERROR: Failed to execute system command (scp /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/* $dirSimNetDeployer/bin)\n";
           exit(207);
        }
    }
    my ( $outputNetsim, $errputNetsim ) =
      $sshNetsim->capture2( { timeout => 3000 }, "@cmdArrayNetsim" );

    if ( $errputNetsim ne "" ) {
        LogFiles("INFO: errput = $errputNetsim\n") if defined $errputNetsim;
    }
    if($sshNetsim->error) {
        LogFiles "ERROR: ssh failed: " . $sshNetsim->error . "\n";
        print $outputNetsim. "\n";
        exit(204);
     }

    #LogFiles("INFO: output = $outputNetsim\n");
    print LOGFILEHANDLER $outputNetsim . "\n";
    print $outputNetsim. "\n";

    # get simulations count that are fetched from FTP/Nexus
    #if count is greater than 0 proceed further
    if (! -e "$workingPath/dat/listSimulation.txt") {
        LogFiles "ERROR: File $workingPath/dat/listSimulation.txt doesn't exist.\n";
        exit(206);
    }
    if (! open listSim, "<", "$workingPath/dat/listSimulation.txt") {
        LogFiles "ERROR:Could not open file $workingPath/dat/listSimulation.txt.\n";
        exit(203);
    }
    my @simNamesArray = <listSim>;
    close listSim;
    if(@simNamesArray ) {
        $simsFetched = 1;
        my ( $outputNetsimN, $errputNetsimN ) =
          $sshNetsim->capture2( { timeout => 9 },
           "cat $dirSimNetDeployer/logs/simNetDeployerLogs.txt" );
        if($sshNetsim->error){
            LogFiles "WARN: ssh failed: " . $sshNetsim->error . "\n";
        if ("$errputNetsimN") {
            LogFiles("$errputNetsimN");
        }
    }
        #LogFiles("$outputNetsimN");
        print LOGFILEHANDLER "$outputNetsimN";
        print "$outputNetsimN";
    }
    else {
        $simsFetched = 0;
    }
}

#
#---------------------------------------------------------------------------------
#SubRoutine to set up TLS security in OSSRC
#---------------------------------------------------------------------------------
#
sub setupSecurityOmsasTLS {
    my $serverType = $_[0];
    LogFiles("INFO: Starting set up of TLS Security\n");

    #Variable declarations
    $dirSimNetDeployer = '/tmp/Security/TLS/';

    #Creating SSH object
    my $hostOmsas   = "$omsasName";
    my $userOmsas   = "$omsasUser";
    my $passwdOmsas = "$omsasPass";
    my $sshOmsas    = Net::OpenSSH->new(
        $hostOmsas,
        user        => $userOmsas,
        password    => $passwdOmsas,
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

    @cmdArrayOmsas = "
mkdir -p $dirSimNetDeployer";
    ( $outputOmsas, $errputOmsas ) =
      $sshOmsas->capture2( { timeout => 3 }, "@cmdArrayOmsas" );

    #print "output = $outputOmsas\n";
    #print "errput = $errputOmsas\n";
    if($sshOmsas->error){
        LogFiles "ERROR: ssh create folder failed: " . $sshOmsas->error . "\n";
        if ("$errputOmsas") {
            LogFiles("$errputOmsas");
        }
        exit(204);
    }
    my $gatewayDatOmsasPath = "$simDepPath/../dat/omsas/";
    $timeout = 6;
    $cmd =
      "scp $gatewayDatOmsasPath/conf.txt root\@$omsasName:$dirSimNetDeployer";
    ( $pty, $pid ) = $sshNetsim->open2pty($cmd);
    if($sshNetsim->error){
       LogFiles "ERROR: unable to run remote command $cmd" . $sshNetsim->error . "\n";
       exit(204);
    }
    $expect = Expect->init($pty);
    $expect->raw_pty(1);
    $expect->log_file( "../log/expect-copyConfToOmsas.pm_log", "w" );

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
    $fileName = "../log/expect-copyConfToOmsas.pm_log";
    &append($fileName);

    LogFiles(
"INFO: All security related files can be found under $dirSimNetDeployer folder on OMSAS server \n"
    );
    LogFiles("INFO: Generating Keys.pem file on OMSAS\n");
    $timeout = 10;
    $cmd =
      "/usr/sfw/bin/openssl genrsa -des3 -out $dirSimNetDeployer/keys.pem 1024";
    ( $pty, $pid ) = $sshOmsas->open2pty($cmd);
    if($sshOmsas->error){
       LogFiles "ERROR: unable to run remote command $cmd" . $sshOmsas->error . "\n";
       exit(204);
    }
    $expect = Expect->init($pty);
    $expect->raw_pty(1);
    $expect->log_file( "../log/expect-setupTLS_keys_log", "w" );

    # or multi-match on several spawned commands with callbacks,
    # just like the Tcl version
    $expect->expect(
        $timeout,
        [
            qr/keys.pem/ => sub {
                my $expect = shift;
                $expect->send("eric123\n");
                exp_continue;
            }
        ],
        '-re',
        qr'[#>:] $'    #' wait for shell prompt, then exit expect
    );
    $expect->soft_close();
    $fileName = "../log/expect-setupTLS_keys_log";
    &append($fileName);

    LogFiles("INFO: Creating cert.csr on OMSAS\n");
    $timeout = 10;
    $cmd =
"/usr/sfw/bin/openssl req -new -key $dirSimNetDeployer/keys.pem -out $dirSimNetDeployer/cert.csr -config $dirSimNetDeployer/conf.txt";
    ( $pty, $pid ) = $sshOmsas->open2pty($cmd);
    if($sshOmsas->error){
       LogFiles "ERROR: unable to run remote command $cmd" . $sshOmsas->error . "\n";
       exit(204);
    }
    $expect = Expect->init($pty);
    $expect->raw_pty(1);
    $expect->log_file( "../log/expect-setupTLS_cert_log", "w" );

    # or multi-match on several spawned commands with callbacks,
    # just like the Tcl version
    $expect->expect(
        $timeout,
        [
            qr/keys.pem/ => sub {
                my $expect = shift;
                $expect->send("eric123\n");
                exp_continue;
            }
        ],
        '-re',
        qr'[#>:] $'    #' wait for shell prompt, then exit expect
    );
    $expect->soft_close();

    $fileName = "../log/expect-setupTLS_cert_log";
    &append($fileName);

    #upto to now the second files intermediate file called cert.csr is created
    LogFiles(
"INFO: Creating cert.pem on OMSAS (Would approximately take 12 seconds)\n"
    );
    if ( "$serverType" eq "VAPP" ) {
    $ossmaster = "ossmaster";
    }
    else {
    $ossmaster = $ossmasterName;
    }
    $certsPath     = '/opt/ericsson/csa/certs/';
    $credPath      = '/opt/ericsson/secinst/bin/';
    $NECertCA      = $ossmaster . "NECertCA";
    $MSCertCA      = $ossmaster . "MSCertCA";
    $RootCA        = $ossmaster . "RootCA";
    @cmdArrayOmsas = "
$credPath/credentialsmgr.sh -signCACertReq $dirSimNetDeployer/cert.csr $NECertCA $dirSimNetDeployer/cert.pem
cp $certsPath/$MSCertCA.pem $dirSimNetDeployer/CombinedCertCA.pem
echo '' >> $dirSimNetDeployer/CombinedCertCA.pem
cat $certsPath/$RootCA.pem >> $dirSimNetDeployer/CombinedCertCA.pem
cat $certsPath/$NECertCA.pem >> $dirSimNetDeployer/CombinedCertCA.pem
head -20 $dirSimNetDeployer/cert.pem > $dirSimNetDeployer/cert_single.pem
echo 'SIZE::'
wc -c $dirSimNetDeployer/cert.pem $dirSimNetDeployer/cert_single.pem $dirSimNetDeployer/cert.csr
chmod 644 $dirSimNetDeployer/CombinedCertCA.pem";
    ( $outputOmsas, $errputOmsas ) =
      $sshOmsas->capture2( { timeout => 30 }, "@cmdArrayOmsas" );

    #print "output = $outputOmsas\n";
    #print "errput = $errputOmsas\n";
    if($sshOmsas->error){
        LogFiles "ERROR: ssh create folder failed: " . $sshOmsas->error . "\n";
        exit(204);
    }
        if ("$errputOmsas") {
            LogFiles("---------------------------------------------------------------\n");
            LogFiles("errputOmsas:\n $errputOmsas");
            LogFiles("---------------------------------------------------------------\n");
        }

    print LOGFILEHANDLER "$outputOmsas";
    print "$outputOmsas";

    LogFiles(
"INFO: Transferring pem to netsim Server under \/netsim\/netsimdir\/Security\/TLS folder\n"
    );
    $timeout = 6;
    $cmd =
"scp $dirSimNetDeployer/*pem root\@$netsimName:\/netsim\/netsimdir\/Security\/TLS";
    ( $pty, $pid ) = $sshOmsas->open2pty($cmd);
    if($sshOmsas->error){
       LogFiles "ERROR: unable to run remote command $cmd" . $sshOmsas->error . "\n";
       exit(204);
    }
    $expect = Expect->init($pty);
    $expect->raw_pty(1);
    $expect->log_file( "../log/expect-copyPemFromOmsas.pm_log", "w" );

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
    $fileName = "../log/expect-copyPemFromOmsas.pm_log";
    &append($fileName);

}
#
#---------------------------------------------------------------------------------
#Function call to copy certs files.
#---------------------------------------------------------------------------------
#
sub copyCerts {

    my $hostNetsim   = "$netsimName";
    my $userNetsim   = "$netsimUser";
    my $passwdNetsim = "$netsimPass";
    my $sshNetsim    = Net::OpenSSH->new(
        $hostNetsim,
        user        => $userNetsim,
        password    => $passwdNetsim,
        master_opts => [ -o => "StrictHostKeyChecking=no" ]
    );

    $fromPathTLS = '/var/tmp/';
    $toPathTLS = '/netsim/netsimdir/Security/TLS/';
    LogFiles("INFO: Copying security files from $fromPathTLS to $toPathTLS\n");

    $cmd = "cp -v $fromPathTLS*.pem $toPathTLS";
    my ( $out, $err ) = $sshNetsim->capture( { timeout => 6 }, "$cmd" );
    if($sshNetsim->error){
        LogFiles "ERROR: ssh failed: " . $sshNetsim->error . "\n";
        if ("$err") {
            LogFiles("$err");
        }
        exit(204);
    }
    print LOGFILEHANDLER "$out";
    print "$out";
}

#
#---------------------------------------------------------------------------------
#Function call to copy pem files.
#---------------------------------------------------------------------------------

sub copyPem {
    my $workingPath = $_[0];

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

    #
    $fromPathTLS = '/netsim/netsimdir/Security/TLS/';

    #$fromPathSL3 = '/netsim/netsimdir/Security/SL3/';
    $toPathTLS = "$workingPath" . '/Security/TLS/';

    #$toPathSL3 = "$workingPath".'/Security/SL3/';
    LogFiles("INFO: Copying security files from $fromPathTLS to $toPathTLS\n");

    $cmd = "cp -v $fromPathTLS* $toPathTLS";
    my ( $out, $err ) = $sshNetsim->capture( { timeout => 6 }, "$cmd" );
    if($sshNetsim->error){
        LogFiles "ERROR: ssh failed: " . $sshNetsim->error . "\n";
        if ("$err") {
            LogFiles("$err");
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
    $filePath    = '/netsim/netsimdir/Security/TLS/*';
    $cmd = "du -sk $filePath";
    my ( @out, $err ) = $sshNetsim->capture( { timeout => 6 }, "$cmd" );
    if($sshNetsim->error){
        LogFiles "ERROR: ssh failed: " . $sshNetsim->error . "\n";
        if ("$err") {
            LogFiles("$err");
        }
        exit(204);
    }
    my $boolean = 1;
    foreach (@out) {
        my @pathList = split('/', $_ );
        $pathList[0] =~ s/^\s+//;
        $pathList[0] =~ s/\s+$//;
        if($pathList[0] == 0) {
            chomp($pathList[$#pathList]);
            LogFiles("ERROR: pem file $pathList[$#pathList] is not valid (FileSize=$pathList[0]K)\n");
            $boolean =  0; # Pem file is not valid
        }
    }
    return $boolean; # All pem  files are valid
}

#
#
#---------------------------------------------------------------------------------
#SubRoutine to set up security on netsim
#---------------------------------------------------------------------------------
sub setupSecurityNetsim {
    my $workingPath = $_[0];
    my $switchToEnm = $_[1];
    my $serverType  = $_[2];

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
    LogFiles("INFO: Setting up Security on nodes\n");
    @cmdArrayNetsim = "
sudo su -l netsim -c '$workingPath/bin/setupSecurityOSS.pl $workingPath $switchToEnm $serverType'";
    my ( $outputNetsimN, $errputNetsimN ) =
      $sshNetsim->capture2( { timeout => 600 }, "@cmdArrayNetsim" );

    print LOGFILEHANDLER "$outputNetsimN";
    print "$outputNetsimN";

    if($sshNetsim->error){
        LogFiles "WARN: ssh failed: " . $sshNetsim->error . "\n";
        if ("$errputNetsimN") {
            LogFiles("$errputNetsimN");
        }
    }
}

#---------------------------------------------------------------------------------------------------
#SubRoutine to generate summary report
#---------------------------------------------------------------------------------------------------
sub summaryReport {

    #Variable declarations
    my $dirSimNetDeployer = $_[0];

    LogFiles("INFO: Generating summary report for this simulation\n");

    #Creating SSH object for netsim
    my $hostNetsim   = "$netsimName";
    my $userNetsim   = "$netsimUser";
    my $passwdNetsim = "$netsimPass";
    my $sshNetsim    = Net::OpenSSH->new(
        $hostNetsim,
        user        => $userNetsim,
        password    => $passwdNetsim,
        master_opts => [ -o => "StrictHostKeyChecking=no" ]
    );
    $cmd = "
sudo su -l netsim -c '$dirSimNetDeployer/utils/summaryReportGenerator.pl $dirSimNetDeployer'";
    my ($outputNetsimA, $errputNetsimA) = $sshNetsim->capture2( { timeout => 69 }, "$cmd" );


    my $errorStatus = 0; # 0 fail, 1 pass
    if($sshNetsim->error){
        LogFiles "ERROR: ssh failed: " . $sshNetsim->error . "\n";
        if (defined $errputNetsimA) {
            LogFiles("ERROR: ssh failure ($errputNetsimA) \n");
        }
    } else {
        if (index($outputNetsimA, "Error") != -1) {
            LogFiles("ERROR: Netsim threw errors. \n");
        } elsif (index($outputNetsimA, "Terminating") != -1) {
            LogFiles("ERROR: Fatal error. Netsim crashed! (sub summaryReport(1))");
        } else {
            $errorStatus = 1;
        }
    }

    if ($errorStatus != 1){
        LogFiles "ERROR: Shutting down simdep! \n";
        exit(213);
    }

    print LOGFILEHANDLER "$outputNetsimA";
    print "$outputNetsimA";

    LogFiles("INFO: Now gathering rollout status info from netsim\n");
    my ( $outputNetsimB, $errputNetsimB ) =
      $sshNetsim->capture2( { timeout => 3 },
        "cat $dirSimNetDeployer/logs/finalSummaryReport.txt" );

    $errorStatus = 0; # 0 fail, 1 pass
    if($sshNetsim->error){
        LogFiles "ERROR: ssh failed: " . $sshNetsim->error . "\n";
        if (defined $errputNetsimB) {
            LogFiles("ERROR: ssh failure ($errputNetsimB) \n");
        }
    } else {
        if (index($outputNetsimB, "Error") != -1) {
            LogFiles("ERROR: Netsim threw errors. \n");
        } elsif (index($outputNetsimB, "Terminating") != -1) {
            LogFiles("ERROR: Fatal error. Netsim crashed!");
        } elsif (index($outputNetsimB, "OFFLINE") != -1) {
            LogFiles("$outputNetsimB");
            LogFiles("ERROR: Some simulations are offline. See above error.");
        } else {
            $errorStatus = 1;
        }
    }

    if ($errorStatus != 1){
        LogFiles "ERROR: Shutting down simdep! \n";
        exit(213);
    }

    print LOGFILEHANDLER "$outputNetsimB";
    print "$outputNetsimB";
}

#
#------------------------------------------------------------------------------------
#SubRoutine to verify connectivity and set up env on ossmaster
#------------------------------------------------------------------------------------
#
sub setupEnvOssmaster {

    #Variables declarations
    my $dirSimNetDeployer = $_[0];

    #This variable contains the present working directory path
    #Status - Work in progress
    $dirSimNetDeployerBin      = "$dirSimNetDeployer" . "bin\/";
    $dirSimNetDeployerDat      = "$dirSimNetDeployer" . "dat\/";
    $dirSimNetDeployerDatXML   = "$dirSimNetDeployer" . "dat\/" . "XML\/";
    $dirSimNetDeployerSecurity = "$dirSimNetDeployer" . "Security\/";
    $dirSimNetDeployerSecurityTLS =
      "$dirSimNetDeployer" . "Security\/" . "TLS\/";
    $dirSimNetDeployerSecuritySL3 =
      "$dirSimNetDeployer" . "Security\/" . "SL3\/";
    $dirSimNetDeployerDocs = "$dirSimNetDeployer" . "docs\/";
    $dirSimNetDeployerLogs = "$dirSimNetDeployer" . "logs\/";

    #$dirSimNetDeployerLib = "$dirSimNetDeployer"."lib\/";
    $dirSimNetDeployerUtils = "$dirSimNetDeployer" . "utils\/";
    LogFiles(
        "INFO: Setting up environment for the simNetDeployer on ossmaster\n");

    #Creating SSH object
    my $hostOssmaster   = "$ossmasterName";
    my $userOssmaster   = "$ossmasterUser";
    my $passwdOssmaster = "$ossmasterPass";
    my $sshOssmaster    = Net::OpenSSH->new(
        $hostOssmaster,
        user        => $userOssmaster,
        password    => $passwdOssmaster,
        master_opts => [ -o => "StrictHostKeyChecking=no" ]
    );
    LogFiles(
        "INFO: Accessing ossmaster=$hostOssmaster to Set Up Environment\n");
    LogFiles(
"INFO: Creating and Copying files to Ossmaster server under $dirSimNetDeployer\n"
    );
    my @cmdArrayOssmaster = "
mkdir -p $dirSimNetDeployerBin;
mkdir -p $dirSimNetDeployerDat;
mkdir -p $dirSimNetDeployerDatXML;
mkdir -p $dirSimNetDeployerLogs;
mkdir -p $dirSimNetDeployerUtils;
chmod -R 777 $dirSimNetDeployer";
    my ( $outputOssmaster, $errputOssmaster ) =
      $sshOssmaster->capture2( { timeout => 3 }, "@cmdArrayOssmaster" );

    #print "output = $outputOssmaster\n";
    #print "errput = $errputOssmaster\n";
    if($sshOssmaster->error){
        LogFiles "ERROR: ssh create folder failed: " . $sshOssmaster->error . "\n";
        if ("$errputOssmaster") {
            LogFiles("$errputOssmaster");
        }
        exit(204);
    }

    #Creating SSH object for netsim
    my $hostNetsim   = "$netsimName";
    my $userNetsim   = "$netsimUser";
    my $passwdNetsim = "$netsimPass";
    my $sshNetsim    = Net::OpenSSH->new(
        $hostNetsim,
        user        => $userNetsim,
        password    => $passwdNetsim,
        master_opts => [ -o => "StrictHostKeyChecking=no" ]
    );

    my $gatewayOssBinPath  = "$simDepPath/ossmaster";
    my $gatewayOssUtilPath = '../utils/ossmaster/';
    $timeout = 6;
    @cmd = "
scp $gatewayOssBinPath/import.pl root\@$ossmasterName:$dirSimNetDeployerBin;
scp $gatewayOssBinPath/syncStatus.sh root\@$ossmasterName:$dirSimNetDeployerBin;
scp $dirSimNetDeployerDat/listNeName.txt root\@$ossmasterName:$dirSimNetDeployerDat";
    ( $pty, $pid ) = $sshNetsim->open2pty(@cmd);
    if($sshNetsim->error){
       LogFiles "ERROR: unable to run remote command @cmd" . $sshNetsim->error . "\n";
       exit(204);
    }
    $expect = Expect->init($pty);
    $expect->raw_pty(1);
    $expect->log_file( "../log/expect-copyFileToOssmaster.pm_log", "w" );

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
    $fileName = "../log/expect-copyFileToOssmaster.pm_log";
    &append($fileName);

}

#
#---------------------------------------------------------------------------------
#SubRoutine to Copy ARNE XMLs.
#---------------------------------------------------------------------------------
#
sub copyXML {

    #Variable declarations
    ( my $dirSimNetDeployer, my $hostFolder ) = @_;
    LogFiles(
        "INFO: Start copying ARNE XML to ossmaster under path $hostFolder\n");

    #Creating SSH object for netsim
    my $hostNetsim   = "$netsimName";
    my $userNetsim   = "$netsimUser";
    my $passwdNetsim = "$netsimPass";
    my $sshNetsim    = Net::OpenSSH->new(
        $hostNetsim,
        user        => $userNetsim,
        password    => $passwdNetsim,
        master_opts => [ -o => "StrictHostKeyChecking=no" ]
    );

    #Creating SSH object for ossmaster
    my $hostOssmaster   = "$ossmasterName";
    my $userOssmaster   = "$ossmasterUser";
    my $passwdOssmaster = "$ossmasterPass";
    my $sshOssmaster    = Net::OpenSSH->new(
        $hostOssmaster,
        user        => $userOssmaster,
        password    => $passwdOssmaster,
        master_opts => [ -o => "StrictHostKeyChecking=no" ]
    );

    my $timeout = 10;
    my $cmd =
"scp $dirSimNetDeployer/dat/XML/*simdep_create.xml root\@$ossmasterName:$hostFolder";
    my ( $pty, $pid ) = $sshNetsim->open2pty($cmd);
    if($sshNetsim->error){
       LogFiles "WARN: unable to run remote command $cmd" . $sshNetsim->error . "\n";
    }
    my $expect = Expect->init($pty);
    $expect->raw_pty(1);
    $expect->log_file( "../log/expect-copyXMLsFromNetsim.pm_log", "w" );

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
    $fileName = "../log/expect-copyXMLsFromNetsim.pm_log";
    &append($fileName);
    LogFiles(
"INFO: End copying ARNE XMLs from netsim to ossmaster under path $hostFolder\n"
    );

}

#---------------------------------------------------------------------------------
#SubRoutine to import nodes
#---------------------------------------------------------------------------------
#
sub import {
    LogFiles("INFO: Import Process initiated on ossmaster\n");

    #Variable declarations
    my $dirSimNetDeployer = $_[0];

    #Creating SSH object for ossmaster
    my $hostOssmaster   = "$ossmasterName";
    my $userOssmaster   = "$ossmasterUser";
    my $passwdOssmaster = "$ossmasterPass";
    my $sshOssmaster    = Net::OpenSSH->new(
        $hostOssmaster,
        user        => $userOssmaster,
        password    => $passwdOssmaster,
        master_opts => [ -o => "StrictHostKeyChecking=no" ]
    );

    @cmdArrayOssmaster = "
chmod u+x $dirSimNetDeployer/bin/import.pl;
$dirSimNetDeployer/bin/import.pl $dirSimNetDeployer";
    my ( $outputOssmaster, $errputOssmaster ) =
      $sshOssmaster->capture2( { timeout => 4000 }, "@cmdArrayOssmaster" );
    LogFiles("output = $outputOssmaster\n");
    if($sshOssmaster->error){
        LogFiles "WARN: ssh failed: " . $sshOssmaster->error . "\n";
        if ("$errputOssmaster") {
            LogFiles("$errputOssmaster");
        }
    }
    LogFiles("INFO: Now gathering import status info from ossmaster\n");
    my ( $outputOssmasterA, $errputOssmasterA ) =
      $sshOssmaster->capture2( { timeout => 1 },
        "cat $dirSimNetDeployer/logs/summaryImportReport.txt" );
    if($sshOssmaster->error){
        LogFiles "WARN: ssh failed: " . $sshOssmaster->error . "\n";
        if ("$errputOssmaster") {
            LogFiles("$errputOssmaster");
        }
    }
    LogFiles("INFO: $outputOssmasterA");
    if($outputOssmasterA =~ m/PASS/ && $isImportSuccessful == 0) {
        $isImportSuccessful =1;
    }
}

#---------------------------------------------------------------------------------
#SubRoutine to check sync status of the nodes
#---------------------------------------------------------------------------------
#
sub syncStatus {
    LogFiles("INFO: Sync status check process initiated on ossmaster\n");

    #Variable declarations
    my $dirSimNetDeployer = $_[0];

    #Creating SSH object for ossmaster
    my $hostOssmaster   = "$ossmasterName";
    my $userOssmaster   = "$ossmasterUser";
    my $passwdOssmaster = "$ossmasterPass";
    my $sshOssmaster    = Net::OpenSSH->new(
        $hostOssmaster,
        user        => $userOssmaster,
        password    => $passwdOssmaster,
        master_opts => [ -o => "StrictHostKeyChecking=no" ]
    );

    @cmdArrayOssmaster = "
chmod u+x $dirSimNetDeployer/bin/syncStatus.sh;
$dirSimNetDeployer/bin/syncStatus.sh $dirSimNetDeployer";
    my ( $outputOssmaster, $errputOssmaster ) =
      $sshOssmaster->capture2( { timeout => 4000 }, "@cmdArrayOssmaster" );
    if($sshOssmaster->error){
        LogFiles "WARN: ssh failed: " . $sshOssmaster->error . "\n";
    }
    if ("$errputOssmaster") {
        LogFiles("ERROR: \n $errputOssmaster");
        return;
    }
    LogFiles("INFO: Now gathering sync status info from ossmaster\n $outputOssmaster \n");
}

#---------------------------------------------------------------------------------
#SubRoutine to set up security in TLS in ENM
#---------------------------------------------------------------------------------
#
sub securityTLSAndSL2 {
    LogFiles("INFO: Set up Security in ENM mode\n");
    #Variable declarations
    my $dirSimNetDeployer = $_[0];
    my $switchToRv = $_[1];

    #Creating SSH object for ossmaster
    my $hostNetsim   = "$netsimName";
    my $userNetsim   = "$netsimUser";
    my $passwdNetsim = "$netsimPass";
    my $sshNetsim    = Net::OpenSSH->new(
        $hostNetsim,
        user        => $userNetsim,
        password    => $passwdNetsim,
        master_opts => [ -o => "StrictHostKeyChecking=no" ]
    );
    my $setupSecurityScript = "$dirSimNetDeployer/bin/invokeSecurity.pl";
    LogFiles("INFO: Running $setupSecurityScript $server_Type $netsimName $netsimUser $netsimPass $workingPath $securityTLS $securitySL2 $switchToRv \n");
    @cmdArrayNetsim = "
$setupSecurityScript $server_Type $netsimName $netsimUser $netsimPass $workingPath $securityTLS $securitySL2 $switchToRv";
    my ( $outputNetsim, $errputNetsim ) =
      $sshNetsim->capture2( { timeout => 6000 }, "@cmdArrayNetsim" );

    LogFiles("INFO: Now gathering output from security \n$outputNetsim \n");
    if($sshNetsim->error){
        LogFiles "ERROR: (Security) ssh failed: " . $sshNetsim->error . "\n";
        if (defined $errputNetsim) {
            LogFiles("ERROR: (Security) $errputNetsim");
        }
        return 0; # false
    }
    return 1; # true
}

#
#---------------------------------------------------------------------------------
#SubRoutine to set up SL3 security
#---------------------------------------------------------------------------------
#
sub setupSecuritySL3 {
    LogFiles("INFO: Starting set up of SL3 Security\n");
    LogFiles("INFO: PHASE - 1\n");

    #Variable declarations
    ( my $dirSimNetDeployer, my $ossmasterAddress, my $omsrvsAddress ) = @_;

    #Creating SSH object
    my $ssh = Net::SSH::Expect->new(
        host    => "ossmaster",
        user    => 'root',
        raw_pty => 1
    );

    #Starting SSH process
    LogFiles("INFO: Initiating access to remote OMSAS server\n");
    $ssh->run_ssh();
    if($ssh->error) {
        LogFiles "ERROR: SSH process couldn't start: $!\n";
        exit(204);
    }

    # Start the interactive session
    # This part of the code would be erased since we always assume a vApp will not have any previously loaded simulations.
    # As a part of setting up of SL3 we have to import a base node. Here we delete, if previously existing base node
    LogFiles("INFO: Now loging on to OSS MASTER for cleaning environment, if created previously for Security, \n");
    my $gatewayOssDatPath   = '/root/simnet/simdep/dat/ossmaster/';
    my $gatewayOssUtilsPath = '/root/simnet/simdep/utils/ossmaster/';
`scp $gatewayOssDatPath/LTED1180-V2x10-FT-FDD-LTE01-dummy_delete.xml root\@ossmaster:$dirSimNetDeployer\/dat\/XML`;
`scp $gatewayOssUtilsPath/cleanServer.pl root\@ossmaster:$dirSimNetDeployer\/utils`;
    $ssh->exec("chmod u+x $dirSimNetDeployer/utils/cleanServer.pl");
    $ssh->send(
        "perl $dirSimNetDeployer/utils/cleanServer.pl $dirSimNetDeployer");
    $ssh->waitfor( '2', 600 );
    if($ssh->error){
       LogFiles "ERROR: Something went wrong during cleaning dunnym nodes $! \n";
       exit(204);
    }
    LogFiles("Successful operation\n");
    # Creating SSH object
    my $sshNetsim = Net::SSH::Expect->new(
        host    => "netsim",
        user    => 'root',
        raw_pty => 1
    );

    #Starting SSH process
    $sshNetsim->run_ssh();
    if($sshNetsim->error) {
        LogFiles "ERROR: SSH process couldn't start: $!\n";
        exit(204);
    }
    $sshNetsim->read_all(1);
    LogFiles("PHASE - 2 STARTING INITIAL ENROLLMENT\n");

    #This is where the implementation actually begins in its true sense for SL3
    my $testSimSecurity = "/sims/xjigash/simNetDeployer/testSimSecurity";
    LogFiles("INFO: The below rollout cycle is performed as a need for initial enrollment\n");
    $securityStatusTLSOFF = 'OFF';
    $securityStatusSL3OFF = 'OFF';
    LogFiles("INFO: Please note that the parameters that are passed for rollout are the deafult values.\n");
    LogFiles("INFO: These deafult values are need to generate SL3 pem files\n");
    &rollout(
        $testSimSecurity, $ossmasterAddress,     $dirSimNetDeployer,
        $omsrvsAddress,   $securityStatusTLSOFF, $securityStatusSL3OFF
    );
    &import($dirSimNetDeployer);
    LogFiles("INFO: PHASE - 3 Generating pem files now\n");

    #Creating SSH object for OMSAS
    my $sshOmsas = Net::SSH::Expect->new(
        host    => "omsas",
        user    => 'root',
        raw_pty => 1
    );

    #Starting SSH process
    LogFiles("INFO: Initiating access to OMSAS\n");
    $sshOmsas->run_ssh() or die LogFiles("SSH process couldn't start: $!");
    LogFiles("INFO: Creating pem files\n");
    $sshOmsas->exec("su - caasadm");
    $nextResponse = $sshOmsas->read_all(1);
    $sshOmsas->exec('cd /opt/ericsson/cadm/bin/');
    $nextResponse = $sshOmsas->read_all(1);
    $sshOmsas->exec('./caasAdmin init_enroll ossmaster:ERBS00001');
    $sshOmsas->waitfor( "/*jobs*/", 30 );
    LogFiles("INFO: We will now verify if the certs are generated\n");
    $nextResponse = $sshOmsas->read_all(1);
    LogFiles("INFO: Verifying\n");

    #Creating SSH object for netsim
    #Start the interactive session
    $verifyPem =
      $sshNetsim->exec(
"ls /netsim/netsim_dbdir/simdir/netsim/netsimdir/LTED1180-V2x10-FT-FDD-LTE01-dummy/ERBS00001/db/corbacreds/"
      );
    $nextResponse = $sshNetsim->read_all(1);
    $_            = $verifyPem;
    if ( $_ =~ /pem/ ) {
        LogFiles("INFO: Pem files for SL3 generated successfully\n");
        $sshNetsim->exec(
"cp /netsim/netsim_dbdir/simdir/netsim/netsimdir/LTED1180-V2x10-FT-FDD-LTE01-dummy/ERBS00001/db/corbacreds/* /netsim/netsimdir/Security/SL3"
        );
    }
    else {
        LogFiles("INFO: There was an issue while generating pem files \n");
        exit(210);
    }
}
#
#------------
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
    @lines = <APPENDFH>;
    foreach (@lines) {

        #LogFiles("$_");
        print LOGFILEHANDLER "$_";
        print "$_";
    }
}
#
#-------------
sub stopNetsimTrace {
    LogFiles("INFO: Stopping The netsim log trace\n");
    my $netsimInst="/netsim/inst";
    my $hostNetsim   = "$netsimName";
    my $userNetsim   = "$netsimUser";
    my $passwdNetsim = "$netsimPass";
    my $sshNetsim    = Net::OpenSSH->new(
        $hostNetsim,
        user        => $userNetsim,
        password    => $passwdNetsim,
        master_opts => [ -o => "StrictHostKeyChecking=no" ]
    );
    $cmd ="sudo su -l netsim -c '$netsimInst/init_trace.sh stop'";
    my ( $outputNetsim, $errputNetsim ) =$sshNetsim->capture2( { timeout => 60 }, "$cmd" );
    if($sshNetsim->error){
        LogFiles "ERROR: ssh failed: " . $sshNetsim->error . "\n";
        exit(204);
    }
    if ( $errputNetsim ne "" ) {
        LogFiles("INFO: errput = $errputNetsim\n") if defined $errputNetsim;
    }
    LogFiles("INFO: output = $outputNetsim\n");
}

#--------------------------------------------------------------
#Check if the simulations are of network
#--------------------------------------------------------------
sub sims1_8KContent {
    my $pwd =`pwd`;
    chdir("/netsim/simdepContents/");
    chomp($pwd);
    opendir(DIR, "$pwd");
    my $file= grep(/^Simnet_1_8K_CXP*.*\.content/,readdir(DIR));
    closedir(DIR);
    chdir($pwd);
    return $file ;
}

##################################################################################
#   Main
##################################################################################
#
LogFiles("INFO: Welcome to simNetDeployer tool.\n");

#
#----------------------------------------------------------------------------------
#Opening a file to register log
#----------------------------------------------------------------------------------
LogFiles("INFO: You can find real time execution logs of this script at ../log/$logFileName\n");

#
#----------------------------------------------------------------------------------
#Check if the script is executed as root user
#----------------------------------------------------------------------------------
#
my $root  = 'root';
my $user  = `whoami`;
my $USAGE =<<USAGE;

    HELP:
        <Add Descriptions here>

    Usage:
        ./invokeSimNetDeployer.pl   -overwrite -createDirectories
            -securityTLS <securityTLS>
            -release <release>
            -deploymentType <deploymentType>
            -serverType <serverArg>
            -masterServer <master>
            -simLTE <simLTE>
            -simCORE <simCORE>
            -simWRAN <simWRAN>
            -LTE <LTE>
            -CORE <CORE>
            -WRAN <WRAN>
            -GRAN <GRAN>
            -PICO <PICO>
            -ossmaster <ossmasterServer>
            -ossmasterUser <ossUserName>
            -ossmasterPass <ossPassword>
            -omsas <omsasServer>
            -omsasUser <omsasUserName>
            -omsasPass <omsasPassword>

        where madatory parameters/flags are
                <release>   : Release version of NSS Drop

        where optional parameters/flags are
                EVERYTHING ELSE IS OPTIONAL

    Usage examples:

        ./invokeSimNetDeployer.pl -release 16.2
        ./invokeSimNetDeployer.pl -overwrite -release 16.2 -serverType VM   -LTE /sims/O15/ENM/15.8/largeDeployment/LTE -WRAN /sims/O15/ENM/15.8/largeDeployment/WRAN \
                                                                            -CORE /sims/O15/ENM/15.8/largeDeployment/CORE -PICO /sims/O15/ENM/15.8/largeDeployment/PICO \
                                                                            -GRAN /sims/O15/ENM/15.8/largeDeployment/GRAN
        ./invokeSimNetDeployer.pl -overwrite -release 16.2 -serverType VAPP -simLTE LTE01:LTE02 -simWRAN RNC01 -simCORE CORE
        ./invokeSimNetDeployer.pl -overwrite -release 16.2 -serverType VAPP -simLTE LTE01:LTE02 -simWRAN RNC01 -simCORE CORE -securityTLS on -masterServer 192.168.0.12
        ./invokeSimNetDeployer.pl -overwrite -release 16.2 -serverType VAPP -simLTE LTE01:LTE02 -simWRAN RNC01 -simCORE CORE -securityTLS off
        ./invokeSimNetDeployer.pl -overwrite -release 16.2 -serverType VAPP -simLTE LTE07 -simWRAN "" -simCORE "" -LTE /sims/O16/ENM/16.2/DOCKER/LTE -securityTLS off

USAGE

chomp($user);
if ( $user ne $root ) {
    LogFiles("Error: Not a root user. Please execute the script as a root user \n");
    exit(201);
}

#
#----------------------------------------------------------------------------------
#Check if the script usage is right
#----------------------------------------------------------------------------------
#
if ( @ARGV > 40 ) {
    LogFiles("WARNING: $USAGE");
    exit(202);
}
our $release;
our $serverArg;
our $LTE;
our $WRAN;
our $PICO;
our $GRAN;
our $CORE;
our $deploymentType = "mediumDeployment";
our $sim;
our $overwrite = '';
our $createDirectories = '';
our $simLTE;
our $simWRAN;
our $simCORE;
our $masterServer;
our $masterUser;
our $masterPass;
our $ciPortal;
our $securityTLS;
our $securitySL2;
our $docker;
our $switchToRV;
our $IPV6Per;

Getopt::Long::GetOptions(
    'overwrite' => \$overwrite,
    'createDirectories' => \$createDirectories,
    'release=s' => \$release,
    'serverType=s' => \$serverArg,
    'LTE=s' => \$LTE,
    'WRAN=s' => \$WRAN,
    'GRAN=s' => \$GRAN,
    'PICO=s' => \$PICO,
    'CORE=s' => \$CORE,
    'deploymentType=s' => \$deploymentType,
    'simLTE=s' => \$simLTE,
    'simWRAN=s' => \$simWRAN,
    'simCORE=s' => \$simCORE,
    'securityTLS=s' => \$securityTLS,
    'securitySL2=s' => \$securitySL2,
    'ossmaster=s' => \$ossmasterServer,
    'ossmasterUser=s' => \$ossUserName,
    'ossmasterPass=s' => \$ossPassword,
    'omsas=s' => \$omsasServer,
    'omsasUser=s' => \$omsasUserName,
    'omsasPass=s' => \$omsasPassword,
    'masterServer=s' => \$master,
    'ciPortal=s' => \$ciPortal,
    'docker=s' => \$docker,
    'switchToRv=s' => \$switchToRV,
    'IPV6Per=s' => \$IPV6Per
);

#
#---------------------------------------------------------------------------------
#Function call to read configuration file.
#---------------------------------------------------------------------------------
#
my $securityStatusSL2;
my $confPath = '../conf/conf.txt';
(
    my $securityStatusTLS,
    my $securityStatusSL3,
    my $importStatus,
    my $fetchSimFromDefaultPath,
    my $networkFlagLte,
    my $networkFlagWran,
    my $networkFlagGran,
    my $networkFlagCore,
    my $networkFlagPico,
    my $copyArneToDefaultLocation,
    my $hostFolderToCopyArneXml,
    $ossmasterName,
    $ossmasterUser,
    $ossmasterPass,
    $netsimName,
    $netsimUser,
    $netsimPass,
    $omsasName,
    $omsasUser,
    $omsasPass,
    my $fetchFromFtp,
    my $checkSyncStatus,
    my $switchToEnm,
    my $arneFileGeneration,
    my $serverType,
    my $switchToRvConf,
    my $defaultDestination,
    $masterServer,
    $masterUser,
    $masterPass,
    my @listOfSimPath
) = &readConfig($confPath);

if (defined $securityTLS and $securitySL2 ne '')
{
    system("sed -i '/SETUP_SECURITY_TLS/c\\SETUP_SECURITY_TLS=" . uc($securityTLS) . "' $confPath");
    if($? != 0) {
        LogFiles "ERROR: Failed to execute system command (sed -i '/SETUP_SECURITY_TLS/c\\SETUP_SECURITY_TLS=" . uc($securityTLS) . "' $confPath)  in module $0 \n";
        exit(207);
    } else {
        $securityStatusTLS = $securityTLS;
    }
}

if (defined $securitySL2 and $securitySL2 ne '' )
{
    system("sed -i '/SETUP_SECURITY_SL2/c\\SETUP_SECURITY_SL2=" . uc($securitySL2) . "' $confPath");
    if($? != 0) {
        LogFiles "ERROR: Failed to execute system command (sed -i '/SETUP_SECURITY_SL2/c\\SETUP_SECURITY_SL2=" . uc($securitySL2) . "' $confPath)  in module $0 \n";
        exit(207);
    } else {
        $securityStatusSL2 = $securitySL2;
    }
}

if (defined $deploymentType and $deploymentType ne '' )
{
    system("sed -i '/DEPLOYMENT_TYPE=/c\\DEPLOYMENT_TYPE=$deploymentType' $confPath");
    if($? != 0) {
        LogFiles "ERROR: Failed to execute system command (sed -i '/DEPLOYMENT_TYPE=/c\\DEPLOYMENT_TYPE= .$deploymentType . ' $confPath)  in module $0 \n";
        exit(207);
    }
}

if (defined $docker and $docker ne '' )
{
    system("sed -i '/SWITCH_TO_DOCKER=/c\\SWITCH_TO_DOCKER=$docker' $confPath");
    if($? != 0) {
        LogFiles "ERROR: Failed to execute system command (sed -i '/SWITCH_TO_DOCKER=/c\\SWITCH_TO_DOCKER="
                 . $docker . " ' $confPath)  in module $0 \n";
        exit(207);
    }
}

if (defined $switchToRV and $switchToRV ne '' )
{
    system("sed -i '/SWITCH_TO_RV=/c\\SWITCH_TO_RV=". uc($switchToRV)."' $confPath");
    if($? != 0) {
        LogFiles "ERROR: Failed to execute system command (sed -i '/SWITCH_TO_RV=/c\\SWITCH_TO_RV="
                 . $switchToRV . " ' $confPath)  in module $0 \n";
        exit(207);
    }
}


if (defined $ciPortal and $ciPortal ne '')
{
    if ( lc "$ciPortal" eq lc "yes" ) {
        $fetchFromFtp = "NO";
        system("sed -i '/FETCH_SIMS_METHOD=/c\\FETCH_SIMS_METHOD=PORTAL' $confPath");
        if($? != 0) {
            LogFiles "ERROR: Failed to execute system command (sed -i 's/FETCH_SIMS_METHOD=/c\\FETCH_SIMS_METHOD=PORTAL' $confPath)  in module $0 \n";
            exit(207);
        } else {
            $securityStatusTLS = $securityTLS;
        }
    } else {
        system("sed -i '/FETCH_SIMS_METHOD=/c\\FETCH_SIMS_METHOD=FTP' $confPath");
        if($? != 0) {
            LogFiles "ERROR: Failed to execute system command (sed -i 's/FETCH_SIMS_METHOD=/c\\FETCH_SIMS_METHOD=PORTAL' $confPath)  in module $0 \n";
            exit(207);
        }
    }
}


if (defined $ossmasterServer)
{
    $ossmasterName = $ossmasterServer;
}
if (defined $ossUserName)
{
    $ossmasterUser = $ossUserName;
}
if (defined $ossPassword)
{
    $ossmasterPass = $ossPassword;
}
if (defined $omsasServer)
{
    $omsasName = $omsasServer;
}
if (defined $omsasUserName)
{
    $omsasUser = $omsasUserName;
}
if (defined $omsasPassword)
{
    $omsasPass = $omsasPassword;
}
if (defined $master)
{
    $masterServer = $master;
}
if (defined $switchToRV)
{
    $switchToRvConf = $switchToRV;
}
#Prerequisites
LogFiles "INFO: Delete ossmaster ssh-key\n";
system("ssh-keygen -R $ossmasterName >/dev/null 2>&1");
if($? != 0)
{
    LogFiles "INFO: Failed to execute system command (ssh-keygen -R $ossmasterName) \n";
}

LogFiles "INFO: Delete omsas ssh-key\n";
system("ssh-keygen -R $omsasName >/dev/null 2>&1");
if($? != 0)
{
    LogFiles "INFO: Failed to execute system command (ssh-keygen -R $omsasName)  in module $0 \n";
}

LogFiles "INFO: Delete master server ssh-key\n";
system("ssh-keygen -R $masterServer >/dev/null 2>&1");
if($? != 0)
{
    LogFiles "INFO: Failed to execute system command (ssh-keygen -R $masterServer)  in module $0 \n";
}

if (defined $serverArg)
{
    $server_Type = $serverArg;
}
else {
    $server_Type = $serverType;
}


LogFiles "INFO: The parameters that we read \n";

#LogFiles "INFO: OSS_TRACK = $ossTrack\n";
LogFiles "INFO: SECURITY_TLS = " . uc($securityStatusTLS) ."\n";
LogFiles "INFO: SECURITY_SL2 = " . uc($securityStatusSL2) ."\n";
LogFiles "INFO: SECURITY_SL3 = $securityStatusSL3\n";
LogFiles "INFO: DEPLOYMENT_TYPE = $deploymentType \n";
LogFiles "INFO: IMPORT_STATUS = $importStatus\n";
LogFiles "INFO: FETCH_SIM_FROM_DEFAULT_PATH = $fetchSimFromDefaultPath\n";
LogFiles "INFO: ROLLOUT_LTE = $networkFlagLte\n";
LogFiles "INFO: ROLLOUT_WRAN = $networkFlagWran\n";
LogFiles "INFO: ROLLOUT_GRAN = $networkFlagGran\n";
LogFiles "INFO: ROLLOUT_CORE = $networkFlagCore\n";
LogFiles "INFO: ROLLOUT_PICO = $networkFlagPico\n";
LogFiles "INFO: COPY_ARNE_TO_DEFAULT_LOCATION = $copyArneToDefaultLocation\n";
LogFiles "INFO: FETCH_FROM_FTP = $fetchFromFtp\n";
LogFiles "INFO: CHECK_SYNC_STATUS = $checkSyncStatus\n";
LogFiles "INFO: SWITCH_TO_ENM = $switchToEnm\n";
LogFiles "INFO: ARNE_FILE_GENERATION = $arneFileGeneration\n";
LogFiles "INFO: SERVER_TYPE = $server_Type\n";
LogFiles "INFO: SWITCH_TO_RV = " . uc($switchToRvConf) . "\n";
LogFiles "INFO: IPV6Per = " . uc($IPV6Per) ."\n";
#LogFiles "INFO: USER_SPECIFIED_FTP_PATH = @listOfSimPath\n";
#
#---------------------------------------------------------------------------------
#Environment Variables
#---------------------------------------------------------------------------------
#The idea here is to read all parameters and from the configEnvironment file


$ossmasterAddress = $defaultDestination;
$omsrvsAddress = "192.168.0.4";
$netsimName = `hostname`;
chomp($netsimName);
chomp($ossmasterAddress);
chomp($omsrvsAddress);
@simDepPath = split( /invokeSimNetDeployer\.pl/, abs_path($0) );
$simDepPath = $simDepPath[0];
chomp($simDepPath);
#---------------------------------------------------------------------------------
#Function call to read OSS Track
#---------------------------------------------------------------------------------
#

#switchtoENM
if("$switchToEnm" eq "NO") {
    $ossTrack = &readOssTrack();
    LogFiles "INFO: The oss track is $ossTrack \n";
}
# For storing log files
else {
     if(defined $release) {
         $ossTrack = $release;
         chomp($ossTrack);
         LogFiles "INFO: The ENM version is $release \n";
     }
     else {
          LogFiles "ERROR: No release version detected, exiting code \n";
          LogFiles("ERROR: $USAGE");
          exit(211);
          }
     }

#
#----------------------------------------------------------------------------------
#Function call to read PATH from the configPath.txt file.
#----------------------------------------------------------------------------------
#The idea is to read data from a configPath.txt file and take the data into an array
my $LTEPath;
my $GRANPath;
my $WRANPath;
my $COREPath;
my $PICOPath;
my @simulationStoragePath;

if ( "$fetchSimFromDefaultPath" eq "YES" ) {
          (
            $LTEPath,
            $GRANPath,
            $WRANPath,
            $COREPath,
            $PICOPath,
          ) = &readSimulationStoragePath(
        $ossTrack,        $networkFlagLte,  $networkFlagWran,
        $networkFlagGran, $networkFlagCore, $networkFlagPico,
        $fetchFromFtp,    $switchToEnm,     $deploymentType
    );
}

if ( "$fetchSimFromDefaultPath" eq "NO" ) {
          (
            $LTEPath,
            $GRANPath,
            $WRANPath,
            $COREPath,
            $PICOPath
          ) = &readSimulationStoragePathNonDefault(
        \@listOfSimPath,  $networkFlagLte,  $networkFlagWran,
        $networkFlagGran, $networkFlagCore, $networkFlagPico
    );
}

if (defined $LTE)
{
    $LTEPath = $LTE;
}
if (defined $WRAN)
{
    $WRANPath = $WRAN;
}
if (defined $CORE)
{
    $COREPath = $CORE;
}
if (defined $GRAN)
{
    $GRANPath = $GRAN;
}
if (defined $PICO)
{
    $PICOPath = $PICO;
}

if ($overwrite) {
    LogFiles "INFO: -overwrite flag is activated. Cmd line args has precedence over config file args.\n";
    $LTEPath = undef if defined $simLTE and $simLTE eq "";
    $WRANPath = undef if defined $simWRAN and $simWRAN eq "";
    $COREPath = undef if defined $simCORE and $simCORE eq "";
    $GRANPath = $GRAN;
    $PICOPath = $PICO;
}

$index = 0;
if (defined $LTEPath)
{
    $simulationStoragePath[ $index++ ] = $LTEPath;
}
if (defined $WRANPath)
{
    $simulationStoragePath[ $index++ ] = $WRANPath;
}
if (defined $COREPath)
{
    $simulationStoragePath[ $index++ ] = $COREPath;
}
if (defined $GRANPath)
{
    $simulationStoragePath[ $index++ ] = $GRANPath;
}
if (defined $PICOPath)
{
    $simulationStoragePath[ $index++ ] = $PICOPath;
}

foreach (@simulationStoragePath) {
    LogFiles "INFO: Now we are looping for $_\n";
    my $userSpecifiedFtpPath = $_;
    LogFiles "INFO: USER_SPECIFIED_STORAGE_PATH = $userSpecifiedFtpPath\n";

    #
    #---------------------------------------------------------------------------------
    #Function call to create the environment on NETSim
    #--------------------------------------------------------------------------------
    #
    $workingPath = &getWorkingPath( "$_", "$ossTrack" );
    LogFiles "INFO: netsim_path = $workingPath\n";
    &setupEnvNetsim($workingPath);

    if ($createDirectories) {
        LogFiles "INFO: -createDirectories flag is activated. No simulations will be rolled out.\n";
        next;
    }
    #
    #Replace /netsim/inst/binstart_all_simne.sh with start_five_simne.sh if network is 1.8K
    #---------------------------------------------------------------------------------------------
    my $file_1_8K = &sims1_8KContent();
    my $network = `cat /netsim/simdepContents/NRMDetails | grep "RolloutNetwork" `;
    if ("$file_1_8K" && "$serverType" eq "VM")
    {
       system("mv $workingPath/bin/start_1_8K_Nodes_VM.sh /netsim/inst/bin/start_all_simne.sh");
    }
    elsif ("$file_1_8K")
    {
        system("cp $workingPath/bin/start_five_all_simne.sh /netsim/inst/bin");
        system("rm -rf /netsim/inst/bin/start_all_simne.sh");
        system("cp /netsim/inst/bin/start_five_all_simne.sh /netsim/inst/bin/start_all_simne.sh");
        system("rm -rf /netsim/inst/bin/start_five_all_simne.sh");
    }
    elsif ($network =~ m/rvModuleLRAN_Small_NRM4.1/i || $network =~ m/rvModuleWRAN_Small_NRM4.1/i || $network =~ m/rvModuleCore_Small_NRM4.1/i || $network =~ m/rvModuleTransport_Small_NRM4.1/i || $network =~ m/rvModuleNRM5_5K_/i || $network =~ m/rvModuleTransport_300Nodes_NRM6/i ) {
       system("cp $workingPath/bin/start_all_simne_parallel.sh /netsim/inst/bin");
       system("rm -rf /netsim/inst/bin/start_all_simne.sh");
       system("mv /netsim/inst/bin/start_all_simne_parallel.sh /netsim/inst/bin/start_all_simne.sh");
    }
    #----------------------------------------------------------------------------------
    #Function call to start the rollout
    #----------------------------------------------------------------------------------
    #
    #The logic is here to sequentailly traverse through every path that and perfrom sequentail rollout
    chomp($release);
    if ( $_ =~ LTE)
    {
         if (defined $simLTE)
         {
              &rollout( $_, $ossmasterAddress, $workingPath, $server_Type, $release, $securityStatusTLS, $IPV6Per, $switchToRvConf, $simLTE );
         }
         else
         {
              &rollout( $_, $ossmasterAddress, $workingPath, $server_Type, $release, $securityStatusTLS, $IPV6Per, $switchToRvConf );
         }
    }
    elsif ( $_ =~ WRAN)
    {
         if (defined $simWRAN)
         {
              &rollout( $_, $ossmasterAddress, $workingPath, $server_Type, $release, $securityStatusTLS, $IPV6Per, $switchToRvConf, $simWRAN );
         }
         else
         {
              &rollout( $_, $ossmasterAddress, $workingPath, $server_Type, $release, $securityStatusTLS, $IPV6Per, $switchToRvConf );
         }
    }
    elsif ( $_ =~ CORE)
    {
         if (defined $simCORE)
         {
              &rollout( $_, $ossmasterAddress, $workingPath, $server_Type, $release, $securityStatusTLS, $IPV6Per, $switchToRvConf, $simCORE );
         }
         else
         {
              &rollout( $_, $ossmasterAddress, $workingPath, $server_Type, $release, $securityStatusTLS, $IPV6Per, $switchToRvConf );
         }
    }
    else
    {
         &rollout( $_, $ossmasterAddress, $workingPath, $server_Type, $release, $securityStatusTLS, $IPV6Per, $switchToRvConf );
    }

    #
    #--------------------------------------------------------------:-------------------
    #Function call to set up TLS and SL2 security (Temporary solution)
    #--------------------------------------------------------------------------------
    #
    #TLS is set up for PICO and ECIM nodes and SL2 for CPP(ERBS|MGw) nodes
    if( $simsFetched ) {

        if ( lc "$switchToEnm" eq lc "YES") {
            if ( lc "$securityStatusTLS" eq lc "ON" || lc "$securityStatusSL2" eq lc "ON"  ) {
                if ( ! &securityTLSAndSL2($workingPath,$switchToRvConf) ) {
                    LogFiles "ERROR: Due to above errors security is not applied! \n";
                    LogFiles "ERROR: Shutting down simdep! \n";
                    exit(213);
                } else {
                    LogFiles "INFO: Security check completed. \n";
                }
            }
        } else {
            if ( lc "$securityStatusTLS" eq lc "ON"  ) {
                #Set up security and create pem files on omsas server and copy it to netsim
                &setupSecurityOmsasTLS($server_Type);

                #validate pem files
                if ( &validatePem() ) {
                    #Copy pem files under relevant folder within netsim
                    &copyPem($workingPath);

                    #Set up security on netsim
                    &setupSecurityNetsim($workingPath, $switchToEnm, $serverType);
                }
                else {
                    LogFiles "ERROR: Due to pem file errors TLS security is not applied!\n";
                }
            }
        }

        #
        #--------------------------------------------------------------------------------
        #Function call to generate Summary report
        #--------------------------------------------------------------------------------
        #
        &summaryReport($workingPath);

        #--------------------------------------------------------------------------------
        #Function call to copy ARNE XMLs
        #--------------------------------------------------------------------------------
        if ( "$copyArneToDefaultLocation" eq "NO" && "$switchToEnm" eq "NO") {
              &copyXML( $workingPath, $hostFolderToCopyArneXml );
        }

        #---------------------------------------------------------------------------------
        #Function call to create the environment on ossmaster
        #--------------------------------------------------------------------------------
        #
        if ( "$importStatus" eq "ON" && "$arneFileGeneration" eq "ON") {
            LogFiles "INFO: osspath_path = $workingPath\n";
            &setupEnvOssmaster($workingPath);
            my $ossmasterFolderToCopyArneXml = "$workingPath" . '/dat/XML/';
            &copyXML( $workingPath, $ossmasterFolderToCopyArneXml );

            #Function call to import ARNE XMLs
            &import($workingPath);
            push(@networksRolledOut, $workingPath);
        }
    }
}

#---------------------------------------------------------------------------------
#Function call to verify node synch status
#--------------------------------------------------------------------------------
#
if ( "$importStatus" eq "ON" && "$checkSyncStatus" eq "ON" && "$arneFileGeneration" eq "ON")  {
    if( $isImportSuccessful == 1 ) {
        my $SLEEP_TIME=120;
       LogFiles "INFO: Minumum wating time is set to $SLEEP_TIME seconds to start getting sync status\n";
        sleep ($SLEEP_TIME);
        foreach (@networksRolledOut) {
            LogFiles "INFO: Start getting sync status for the sims $_\n";
            #Function call to check sync status
            &syncStatus($_);
        }
    }
    else {
        LogFiles "INFO: Synch status of nodes can't be verified as ARNE import was not successful.\n";
    }
}
#-----------------------------------------------------------------------------------
#Setting number of days for removing nsslogging files
#-----------------------------------------------------------------------------------
if ( "$switchToRvConf" eq "yes" ) {
     $RV_MML="RV.mml";
     open MML ,"+>> ../dat/$RV_MML";
     print MML <<"END";
.set env RV
END
system("su netsim -c '/netsim/inst/netsim_shell < ../dat/$RV_MML'");
system("rm ../dat/$RV_MML");
}

#-----------------------------------------------------------------------------------
#add Kibana scripts in simdepContents
#-----------------------------------------------------------------------------------
system("cp /var/simnet/enm-ni-simdep/scripts/simdep/ext/jenkins/elk/Kibana_ddp_setup.sh /netsim/simdepContents/");
system("cp /var/simnet/enm-ni-simdep/scripts/simdep/ext/jenkins/elk/DATAROOT_PATH /var/tmp/ddc_data/config/plugins/DATAROOT_PATH");
system("cp /var/simnet/enm-ni-simdep/scripts/simdep/ext/jenkins/elk/netsim.dat /var/tmp/ddc_data/config/plugins/netsim.dat");
system("cp /var/simnet/enm-ni-simdep/scripts/simdep/ext/jenkins/elk/ddc_plugin /root/");
system("service ddc restart");


#Remove the extra characters
#Stop Netsim Log trace after rollout is completed for Rv testing
#LogFiles("INFO: All activities related to SimNet Deployer are now complete.\n");
system( "perl", "-pi", "-e", "tr/\r//d", "../log/$logFileName" );
if($? != 0)
{
    LogFiles " Failed to execute system command (perl", "-pi", "-e", "tr/\r//d", "../log/$logFileName)  in module $0 \n";
    exit(207);
}
##



