#!/usr/bin/perl -w
use Net::FTP;
use Expect;
use Net::SSH::Expect;
use Net::OpenSSH;
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
#Environment variables
#---------------------------------------------------------------------------------
#Status - Work in Progress
#The idea here is to read all parameters and from the configEnvironment file
my $ossServerName = 'ossmaster';
@arr = `nslookup $ossServerName`;
print "arr=@arr \n";
print "arr[4]= $arr[4] \n";
$ossmasterAddress = substr( $arr[4], 9 );
chomp($ossmasterAddress);
print "ossmsterAddress = $ossmasterAddress \n";
exit;
my $omsrvsServerName = 'omsrvm';
@arr = `nslookup $omsrvsServerName`;
$omsrvsAddress = substr( $arr[4], 9 );
chomp($omsrvsAddress);
$dateVar = `date +%F`;
chomp($dateVar);
$timeVar = `date +%T`;
chomp($timeVar);
open LOGFILEHANDLER, "+> ../log/invokeSimNetDeployerLogs_$dateVar\_$timeVar.log"
  or die LogFiles("ERROR: Could not open log file");

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
	print LOGFILEHANDLER "$timeVar:<$hostName>: @_";
	print "$timeVar:<$hostName>: @_";
}

#
#---------------------------------------------------------------------------------
#Function call to read oss track
#---------------------------------------------------------------------------------
sub readOssTrack {
	LogFiles("INFO: Accessing OSS Master to read oss track\n");

	#Creating SSH object
	my $hostOssmaster   = 'ossmaster';
	my $userOssmaster   = 'root';
	my $passwdOssmaster = 'shroot';
	my $sshOssmaster    = Net::OpenSSH->new(
		$hostOssmaster,
		user        => $userOssmaster,
		password    => $passwdOssmaster,
		master_opts => [ -o => "StrictHostKeyChecking=no" ]
	);
	my ( $outputOssmaster, $errputOssmaster ) =
	  $sshOssmaster->capture2( { timeout => 1 },
		"cat  /var/opt/ericsson/sck/data/cp.status" );
	$sshOssmaster->error and die "ssh failed: " . $sshOssmaster->error;
	my @cpStatusDat   = split( / /, $outputOssmaster );
	my @ossTrackField = split( /_/, $cpStatusDat[1] );
	my $ossTrack = $ossTrackField[4];
	return $ossTrack;
}

#
#---------------------------------------------------------------------------------
#Function call to read config file
#---------------------------------------------------------------------------------
sub readConfig {
	my $path = $_[0];
	LogFiles("INFO: Reading config file from $path \n");
	open CONF, "$path" or die;
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
		elsif ( $_ =~ "SETUP_SECURITY_TLS" ) {
			@securityStatusTLSEdit = split( /=/, $_ );
		}
		elsif ( $_ =~ "SETUP_SECURITY_SL3" ) {
			@securityStatusSL3Edit = split( /=/, $_ );
		}
		elsif ( $_ =~ "IMPORT_ARNE_XMLS_ON_TO_OSS" ) {
			@importStatusEdit = split( /=/, $_ );
		}
		elsif ( $_ =~ /^FETCH_SIM_FROM_PATH*/ ) {
			@fetchSimFromPath = split( /=/, $_ );
			chomp( $fetchSimFromPath[1] );
			$listOfSimPath[ $numOfUserEnteredPath++ ] = $fetchSimFromPath[1];
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
	chomp( $securityStatusTLSEdit[1] );
	my $securityStatusTLS = $securityStatusTLSEdit[1];
	chomp( $securityStatusSL3Edit[1] );
	my $securityStatusSL3 = $securityStatusSL3Edit[1];
	chomp( $importStatusEdit[1] );
	my $importStatus = $importStatusEdit[1];

	if ( "$fetchSimFromDefaultPath" eq "YES" ) {
		@listOfSimPath = ();
	}
	return (
		$securityStatusTLS, $securityStatusSL3,
		$importStatus,      $fetchSimFromDefaultPath,
		$networkFlagLte,    $networkFlagWran,
		$networkFlagGran,   $networkFlagCore,
		@listOfSimPath
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
		my $networkFlagCore
	  )
	  = @_;
	$arrayIndex = 0;
	if ( "$networkFlagLte" eq "YES" ) {
		$simulationStoragePath[ $arrayIndex++ ] =
		  '/sims/O14/FeatureTest/' . "$ossTrackAdd" . '/LTE/LATEST';
	}
	if ( "$networkFlagWran" eq "YES" ) {
		$simulationStoragePath[ $arrayIndex++ ] =
		  '/sims/O14/FeatureTest/' . "$ossTrackAdd" . '/WRAN/LATEST';
	}
	if ( "$networkFlagGran" eq "YES" ) {
		$simulationStoragePath[ $arrayIndex++ ] =
		  '/sims/O14/FeatureTest/' . "$ossTrackAdd" . '/GRAN/LATEST';
	}
	if ( "$networkFlagCore" eq "YES" ) {
		$simulationStoragePath[ $arrayIndex++ ] =
		  '/sims/O14/FeatureTest/' . "$ossTrackAdd" . '/CORE/LATEST';
	}
	return @simulationStoragePath;
}

#
#---------------------------------------------------------------------------------
#Function call to get working directory
#---------------------------------------------------------------------------------
sub getWorkingPath {
	( my $checkPath, my $osstrack ) = @_;
	if ( "$checkPath" =~ /lte/i ) {
		$returnWorkingPath = '/tmp/LTE/simNetDeployer/' . "$osstrack\/";
	}
	elsif ( "$checkPath" =~ /wran/i ) {
		$returnWorkingPath = '/tmp/WRAN/simNetDeployer/' . "$osstrack\/";
	}
	elsif ( "$checkPath" =~ /gran/i ) {
		$returnWorkingPath = '/tmp/GRAN/simNetDeployer/' . "$osstrack\/";
	}
	elsif ( "$checkPath" =~ /core/i ) {
		$returnWorkingPath = '/tmp/CORE/simNetDeployer/' . "$osstrack\/";
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
	my $hostNetsim   = 'netsim';
	my $userNetsim   = 'root';
	my $passwdNetsim = 'shroot';
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
	$dirSimNetDeployerBin         = "$dirSimNetDeployer" . "bin\/";
	$dirSimNetDeployerDat         = "$dirSimNetDeployer" . "dat\/";
	$dirSimNetDeployerDatXML      = "$dirSimNetDeployer" . "dat\/" . "XML\/";
	$dirSimNetDeployerSecurity    = "$dirSimNetDeployer" . "Security\/";
	$dirSimNetDeployerSecurityTLS =
	  "$dirSimNetDeployer" . "Security\/" . "TLS\/";
	$dirSimNetDeployerSecuritySL3 =
	  "$dirSimNetDeployer" . "Security\/" . "SL3\/";
	$dirSimNetDeployerDocs = "$dirSimNetDeployer" . "docs\/";
	$dirSimNetDeployerLogs = "$dirSimNetDeployer" . "logs\/";

	#$dirSimNetDeployerLib = "$dirSimNetDeployer"."lib\/";
	$dirSimNetDeployerUtils = "$dirSimNetDeployer" . "utils\/";
	my @cmdArrayNetsim = "
rm -rf $dirSimNetDeployer;
mkdir -p $dirSimNetDeployer;
mkdir -p $dirSimNetDeployerBin;
mkdir -p $dirSimNetDeployerDat;
mkdir -p $dirSimNetDeployerDatXML;
mkdir -p $dirSimNetDeployerSecurity;
mkdir -p $dirSimNetDeployerSecurityTLS;
mkdir -p $dirSimNetDeployerSecuritySL3;
mkdir -p $dirSimNetDeployerDocs;
mkdir -p $dirSimNetDeployerLogs;
mkdir -p $dirSimNetDeployerUtils;
rm -rf $netSimSecurity;
mkdir -p $netSimSecurity\/TLS;
mkdir -p $netSimSecurity\/SL3;
chmod -R 777 $dirSimNetDeployer";
	my ( $outputNetsim, $errputNetsim ) =
	  $sshNetsim->capture2( { timeout => 3 }, "@cmdArrayNetsim" );

	#print "output = $outputNetsim\n";
	#print "errput = $errputNetsim\n";
	$sshNetsim->error and die "ssh failed: " . $sshNetsim->error;
	my $gatewatNetsimBinPath   = '/root/simnet/simdep/bin/netsim/';
	my $gatewatNetsimDatPath   = '/root/simnet/simdep/temp/netsim/';
	my $gatewatNetsimUtilsPath = '/root/simnet/simdep/utils/netsim/';
	`scp $gatewatNetsimBinPath\* root\@netsim:$dirSimNetDeployerBin`;
	`scp $gatewatNetsimDatPath\* root\@netsim:$dirSimNetDeployerDat`;
	`scp $gatewatNetsimUtilsPath\* root\@netsim:$dirSimNetDeployerUtils`;

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
	( my $path, my $address, my $dirSimNetDeployer ) = @_;

	#Creating SSH object
	my $hostNetsim   = 'netsim';
	my $userNetsim   = 'root';
	my $passwdNetsim = 'shroot';
	my $sshNetsim    = Net::OpenSSH->new(
		$hostNetsim,
		user        => $userNetsim,
		password    => $passwdNetsim,
		master_opts => [ -o => "StrictHostKeyChecking=no" ]
	);
	LogFiles("INFO: The simulations are being rolled out on netsim now.\n");

#LogFiles("Please login and refer to $dirSimNetDeployer/logs/simNetDeployerLogs.txt for more details \n");
	LogFiles "INFO: The Parameters passes are: \n";
	LogFiles "INFO: PATH_OF_SIMS_ON_FTP = $path \n";
	LogFiles "INFO: IP_ADDRESS_OF_OSSMASTER = $ossmasterAddress \n";
	LogFiles "INFO: SIMNET_DEPLOYER_DIR = $dirSimNetDeployer\n";
	@cmdArrayNetsim = "
chmod u+x $dirSimNetDeployer/bin/rollout.pl;
$dirSimNetDeployer/bin/rollout.pl $path $ossmasterAddress $dirSimNetDeployer";
	my ( $outputNetsim, $errputNetsim ) =
	  $sshNetsim->capture2( { timeout => 6000 }, "@cmdArrayNetsim" );
	LogFiles("INFO: output = $outputNetsim\n");

	if ( $errputNetsim ne "" ) {
		LogFiles("INFO: errput = $errputNetsim\n") if defined $errputNetsim;
	}

	$sshNetsim->error and die "ssh failed: " . $sshNetsim->error;
	my ( $outputNetsimN, $errputNetsimN ) =
	  $sshNetsim->capture2( { timeout => 9 },
		"cat $dirSimNetDeployer/logs/simNetDeployerLogs.txt" );
	$sshNetsim->error and die "ssh failed: " . $sshNetsim->error;
	LogFiles("$outputNetsimN");
	LogFiles("INFO: Now gathering rollout status info from netsim\n");
	my ( $outputNetsimA, $errputNetsimA ) =
	  $sshNetsim->capture2( { timeout => 3 },
		"cat $dirSimNetDeployer/logs/finalSummaryReport.txt" );
	$sshNetsim->error and die "ssh failed: " . $sshNetsim->error;
	LogFiles("$outputNetsimA");
}

#
#---------------------------------------------------------------------------------
#SubRoutine to set up TLS security
#---------------------------------------------------------------------------------
#
sub setupSecurityOmsasTLS {
	LogFiles("INFO: Starting set up of TLS Security\n");

	#Variable declarations
	$dirSimNetDeployer = '/tmp/Security/TLS/';

	#Creating SSH object
	my $hostOmsas   = 'omsas';
	my $userOmsas   = 'root';
	my $passwdOmsas = 'shroot';
	my $sshOmsas    = Net::OpenSSH->new(
		$hostOmsas,
		user        => $userOmsas,
		password    => $passwdOmsas,
		master_opts => [ -o => "StrictHostKeyChecking=no" ]
	);
	@cmdArrayOmsas = "
rm -rf $dirSimNetDeployer
mkdir -p $dirSimNetDeployer";
	( $outputOmsas, $errputOmsas ) =
	  $sshOmsas->capture2( { timeout => 3 }, "@cmdArrayOmsas" );

	#print "output = $outputOmsas\n";
	#print "errput = $errputOmsas\n";
	$sshOmsas->error and die "ssh create folder failed: " . $sshOmsas->error;
	my $gatewayDatOmsasPath = '/root/simnet/simdep/dat/omsas/';
	`scp $gatewayDatOmsasPath/conf.txt root\@omsas:$dirSimNetDeployer`;
	LogFiles(
"INFO: All security related files can be found under $dirSimNetDeployer folder on OMSAS server \n"
	);
	LogFiles("INFO: Generating Keys.pem file on OMSAS\n");
	$timeout = 10;
	$cmd     =
	  "/usr/sfw/bin/openssl genrsa -des3 -out $dirSimNetDeployer/keys.pem 1024";
	( $pty, $pid ) = $sshOmsas->open2pty($cmd)
	  or die "unable to run remote command $cmd";
	$expect = Expect->init($pty);
	$expect->raw_pty(1);
	$expect->log_file( "../log/expect-setupTLS_log", "w" );

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
	LogFiles("INFO: Creating cert.csr on OMSAS\n");
	$timeout = 10;
	$cmd     =
"/usr/sfw/bin/openssl req -new -key $dirSimNetDeployer/keys.pem -out $dirSimNetDeployer/cert.csr -config $dirSimNetDeployer/conf.txt";
	( $pty, $pid ) = $sshOmsas->open2pty($cmd)
	  or die "unable to run remote command $cmd";
	$expect = Expect->init($pty);
	$expect->raw_pty(1);
	$expect->log_file( "../log/expect-setupTLS_log", "w" );

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

	#upto to now the second files intermediate file called cert.csr is created
	LogFiles(
"INFO: Creating cert.pem on OMSAS (Would approximately take 12 seconds)\n"
	);
	$certsPath     = '/opt/ericsson/csa/certs/';
	$credPath      = '/opt/ericsson/secinst/bin/';
	@cmdArrayOmsas = "
$credPath/credentialsmgr.sh -signCACertReq $dirSimNetDeployer/cert.csr ossmasterNECertCA $dirSimNetDeployer/cert.pem
cp $certsPath/ossmasterMSCertCA.pem $dirSimNetDeployer/CombinedCertCA.pem
echo '' >> $dirSimNetDeployer/CombinedCertCA.pem
cat $certsPath/ossmasterRootCA.pem >> $dirSimNetDeployer/CombinedCertCA.pem
cat $certsPath/ossmasterNECertCA.pem >> $dirSimNetDeployer/CombinedCertCA.pem
head -20 $dirSimNetDeployer/cert.pem > $dirSimNetDeployer/cert_single.pem
chmod 644 $dirSimNetDeployer/CombinedCertCA.pem";
	( $outputOmsas, $errputOmsas ) =
	  $sshOmsas->capture2( { timeout => 20 }, "@cmdArrayOmsas" );

	#print "output = $outputOmsas\n";
	#print "errput = $errputOmsas\n";
	$sshOmsas->error and die "ssh create folder failed: " . $sshOmsas->error;
	LogFiles(
"INFO: Transferring pem to netsim Server under \/netsim\/netsimdir\/Security\/TLS folder\n"
	);
	$timeout = 6;
	$cmd     =
"scp $dirSimNetDeployer/*pem root\@netsim:\/netsim\/netsimdir\/Security\/TLS";
	( $pty, $pid ) = $sshOmsas->open2pty($cmd)
	  or die "unable to run remote command $cmd";
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
}

#
#---------------------------------------------------------------------------------
#Function call to copy pem files.
#---------------------------------------------------------------------------------
sub copyPem {
	my $workingPath = $_[0];

	#Creating SSH object
	my $sshNetsim = Net::SSH::Expect->new(
		host    => "netsim",
		user    => 'root',
		raw_pty => 1
	);

	#
	#Starting SSH process
	$sshNetsim->run_ssh()
	  or die LogFiles("ERROR: SSH process couldn't start: $!");
	$sshNetsim->read_all(1);
	$fromPathTLS = '/netsim/netsimdir/Security/TLS/';

	#$fromPathSL3 = '/netsim/netsimdir/Security/SL3/';
	$toPathTLS = "$workingPath" . '/Security/TLS/';

	#$toPathSL3 = "$workingPath".'/Security/SL3/';
	LogFiles("INFO: Copying security files to $toPathTLS\n");
	$sshNetsim->exec("cp $fromPathTLS* $toPathTLS");

	#LogFiles("INFO: Copying security files to $toPathSL3\n");
	#$sshNetsim->exec("cp $fromPathSL3* $toPathSL3");
}

#
#
#---------------------------------------------------------------------------------
#SubRoutine to set up security on netsim
#---------------------------------------------------------------------------------
sub setupSecurityNetsim {
	my $workingPath = $_[0];

	#Creating SSH object
	my $hostNetsim   = 'netsim';
	my $userNetsim   = 'root';
	my $passwdNetsim = 'shroot';
	my $sshNetsim    = Net::OpenSSH->new(
		$hostNetsim,
		user        => $userNetsim,
		password    => $passwdNetsim,
		master_opts => [ -o => "StrictHostKeyChecking=no" ]
	);
	@cmdArrayNetsim = "
sudo su -l netsim -c '$workingPath/bin/setupSecurity.pl $workingPath'";
	my ( $outputNetsimN, $errputNetsimN ) =
	  $sshNetsim->capture2( { timeout => 600 }, "@cmdArrayNetsim" );
	print("$outputNetsimN");
	print "$errputNetsimN";
	$sshNetsim->error and die "ssh failed: " . $sshNetsim->error;
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
	$dirSimNetDeployerBin         = "$dirSimNetDeployer" . "bin\/";
	$dirSimNetDeployerDat         = "$dirSimNetDeployer" . "dat\/";
	$dirSimNetDeployerDatXML      = "$dirSimNetDeployer" . "dat\/" . "XML\/";
	$dirSimNetDeployerSecurity    = "$dirSimNetDeployer" . "Security\/";
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
	my $hostOssmaster   = 'ossmaster';
	my $userOssmaster   = 'root';
	my $passwdOssmaster = 'shroot';
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
rm -rf $dirSimNetDeployer;
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
	$sshOssmaster->error
	  and die "ssh create folder failed: " . $sshOssmaster->error;
	my $gatewayOssBinPath  = '/root/simnet/simdep/bin/ossmaster/';
	my $gatewayOssUtilPath = '/root/simnet/simdep/utils/ossmaster/';
	`scp $gatewayOssBinPath/import.pl root\@ossmaster:$dirSimNetDeployerBin`;
}

#
#---------------------------------------------------------------------------------
#SubRoutine to Copy ARNE XMLs.
#---------------------------------------------------------------------------------
#
sub copyXML {
	LogFiles("Now copying ARNE XML to on ossmaster\n");

	#Variable declarations
	my $dirSimNetDeployer = $_[0];

	#Creating SSH object for netsim
	my $hostNetsim   = 'netsim';
	my $userNetsim   = 'root';
	my $passwdNetsim = 'shroot';
	my $sshNetsim    = Net::OpenSSH->new(
		$hostNetsim,
		user        => $userNetsim,
		password    => $passwdNetsim,
		master_opts => [ -o => "StrictHostKeyChecking=no" ]
	);

	#Creating SSH object for ossmaster
	my $hostOssmaster   = 'ossmaster';
	my $userOssmaster   = 'root';
	my $passwdOssmaster = 'shroot';
	my $sshOssmaster    = Net::OpenSSH->new(
		$hostOssmaster,
		user        => $userOssmaster,
		password    => $passwdOssmaster,
		master_opts => [ -o => "StrictHostKeyChecking=no" ]
	);

	LogFiles(
"INFO: Fetching XML from $dirSimNetDeployer\/dat\/XML\/ folder on netsim  to import\n"
	);
	my $timeout = 2;

	#print "dirSimNetDeployer=$dirSimNetDeployer/dat/XML/*\n";
	my $cmd =
"scp $dirSimNetDeployer/dat/XML/*modified.xml root\@ossmaster:$dirSimNetDeployer\/dat\/XML";
	my ( $pty, $pid ) = $sshNetsim->open2pty($cmd)
	  or die "unable to run remote command $cmd";
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
	my $hostOssmaster   = 'ossmaster';
	my $userOssmaster   = 'root';
	my $passwdOssmaster = 'shroot';
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
	LogFiles("errput = $errputOssmaster\n");
	$sshOssmaster->error and die "ssh failed: " . $sshOssmaster->error;
	LogFiles("INFO: Now gathering import status info from ossmaster\n");
	my ( $outputOssmasterA, $errputOssmasterA ) =
	  $sshOssmaster->capture2( { timeout => 1 },
		"cat $dirSimNetDeployer/logs/summaryImportReport.txt" );
	$sshOssmaster->error and die "ssh failed: " . $sshOssmaster->error;
	LogFiles("INFO: $outputOssmasterA");
}

#
#---------------------------------------------------------------------------------
#SubRoutine to set up SL3 security
#---------------------------------------------------------------------------------
#
sub setupSecuritySL3 {
	LogFiles("Starting set up of SL3 Security\n");
	LogFiles("PHASE - 1\n");

	#Variable declarations
	( my $dirSimNetDeployer, my $ossmasterAddress, my $omsrvsAddress ) = @_;

	#Creating SSH object
	my $ssh = Net::SSH::Expect->new(
		host    => "ossmaster",
		user    => 'root',
		raw_pty => 1
	);

	#Starting SSH process
	LogFiles("Initiating access to remote OMSAS server\n");
	$ssh->run_ssh() or die LogFiles("SSH process couldn't start: $!");

#Start the interactive session
#This part of the code would be erased since we always assume a vApp will not have any previously loaded simulations.
#As a part of setting up of SL3 we have to import a base node. Here we delete, if previously existing base node
	LogFiles(
"Now loging on to OSS MASTER for cleaning environment, if created previously for Security, \n"
	);
	my $gatewayOssDatPath   = '/root/simnet/simdep/dat/ossmaster/';
	my $gatewayOssUtilsPath = '/root/simnet/simdep/utils/ossmaster/';
`scp $gatewayOssDatPath/LTED1180-V2x10-FT-FDD-LTE01-dummy_delete.xml root\@ossmaster:$dirSimNetDeployer\/dat\/XML`;
`scp $gatewayOssUtilsPath/cleanServer.pl root\@ossmaster:$dirSimNetDeployer\/utils`;
	$ssh->exec("chmod u+x $dirSimNetDeployer/utils/cleanServer.pl");
	$ssh->send(
		"perl $dirSimNetDeployer/utils/cleanServer.pl $dirSimNetDeployer");
	$ssh->waitfor( '2', 600 )
	  or die "Something went wrong during cleaning dunnym nodes $!";
	LogFiles("Successful operation\n");
##Creating SSH object
	my $sshNetsim = Net::SSH::Expect->new(
		host    => "netsim",
		user    => 'root',
		raw_pty => 1
	);

	#Starting SSH process
	$sshNetsim->run_ssh() or die LogFiles("SSH process couldn't start: $!");
	$sshNetsim->read_all(1);
	LogFiles("PHASE - 2 STARTING INITIAL ENROLLEMENT\n");

	#This is where the implementation actually begins in its true sense for SL3
	my $testSimSecurity = "/sims/xjigash/simNetDeployer/testSimSecurity";
	LogFiles(
"The below rollout cycle is performed as a need for initial enrollment\n"
	);
	$securityStatusTLSOFF = 'OFF';
	$securityStatusSL3OFF = 'OFF';
	LogFiles(
"Please note that the parameters that are passed for rollout are the deafult values.\n"
	);
	LogFiles("These deafult values are need to generate SL3 pem files\n");
	&rollout(
		$testSimSecurity, $ossmasterAddress,     $dirSimNetDeployer,
		$omsrvsAddress,   $securityStatusTLSOFF, $securityStatusSL3OFF
	);
	&import($dirSimNetDeployer);
	LogFiles("PHASE - 3 Generating pem files now\n");

	#Creating SSH object for OMSAS
	my $sshOmsas = Net::SSH::Expect->new(
		host    => "omsas",
		user    => 'root',
		raw_pty => 1
	);

	#Starting SSH process
	LogFiles("Initiating access to OMSAS\n");
	$sshOmsas->run_ssh() or die LogFiles("SSH process couldn't start: $!");
	LogFiles("Creating pem files\n");
	$sshOmsas->exec("su - caasadm");
	$nextResponse = $sshOmsas->read_all(1);
	$sshOmsas->exec('cd /opt/ericsson/cadm/bin/');
	$nextResponse = $sshOmsas->read_all(1);
	$sshOmsas->exec('./caasAdmin init_enroll ossmaster:ERBS00001');
	$sshOmsas->waitfor( "/*jobs*/", 30 );
	LogFiles("We will now verify if the certs are generated\n");
	$nextResponse = $sshOmsas->read_all(1);
	LogFiles("Verifying\n");

	#Creating SSH object for netsim
	#Start the interactive session
	$verifyPem =
	  $sshNetsim->exec(
"ls /netsim/netsim_dbdir/simdir/netsim/netsimdir/LTED1180-V2x10-FT-FDD-LTE01-dummy/ERBS00001/db/corbacreds/"
	  );
	$nextResponse = $sshNetsim->read_all(1);
	$_            = $verifyPem;
	if ( $_ =~ /pem/ ) {
		LogFiles("Pem files for SL3 generated successfully\n");
		$sshNetsim->exec(
"cp /netsim/netsim_dbdir/simdir/netsim/netsimdir/LTED1180-V2x10-FT-FDD-LTE01-dummy/ERBS00001/db/corbacreds/* /netsim/netsimdir/Security/SL3"
		);
	}
	else {
		LogFiles("There was an issue while generating pem files \n");
		exit(1);
	}
}

#
##################################################################################
#Main
##################################################################################
#
LogFiles("INFO: Welcome to simNetDeployer tool.\n");

#
#----------------------------------------------------------------------------------
#Opening a file to register log
#----------------------------------------------------------------------------------
LogFiles(
"INFO: You can find real time execution logs of this script at ../log/invokeSimNetDeployerLogs_$dateVar\_$timeVar.log\n"
);

#
#----------------------------------------------------------------------------------
#Check if the script is executed as root user
#----------------------------------------------------------------------------------
#
my $root  = 'root';
my $user  = `whoami`;
my $USAGE = "Usage: $0 \n  E.g. $0 \n";
chomp($user);
if ( $user ne $root ) {
	LogFiles(
		"Error: Not a root user. Please execute the script as a root user \n");
	exit(1);
}

#
#----------------------------------------------------------------------------------
#Check if the script usage is right
#----------------------------------------------------------------------------------
#
if ( @ARGV != 0 ) {
	LogFiles("INFO: $USAGE");
	exit(2);
}

#
#---------------------------------------------------------------------------------
#Function call to read OSS Track
#---------------------------------------------------------------------------------
#
$ossTrack = &readOssTrack();
LogFiles "INFO: The oss track is $ossTrack \n";

#
#---------------------------------------------------------------------------------
#Function call to read configuration file.
#---------------------------------------------------------------------------------
#
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
	my @listOfSimPath
  )
  = &readConfig($confPath);
LogFiles "INFO: The parameters that we read \n";
LogFiles "INFO: OSS_TRACK = $ossTrack\n";
LogFiles "INFO: SECURITY_TLS = $securityStatusTLS\n";
LogFiles "INFO: SECRITY_SL3 = $securityStatusSL3\n";
LogFiles "INFO: IMPORT_STATUS = $importStatus\n";
LogFiles "INFO: FETCH_SIM_FROM_DEFAULT_PATH = $fetchSimFromDefaultPath\n";
LogFiles "INFO: ROLLOUT_LTE = $networkFlagLte\n";
LogFiles "INFO: ROLLOUT_WRAN = $networkFlagWran\n";
LogFiles "INFO: ROLLOUT_GRAN = $networkFlagGran\n";
LogFiles "INFO: ROLLOUT_CORE = $networkFlagCore\n";

#LogFiles "INFO: USER_SPECIFIED_FTP_PATH = @listOfSimPath\n";
#
#----------------------------------------------------------------------------------
#Function call to read PATH from the configPath.txt file.
#----------------------------------------------------------------------------------
#The idea is to read data from a configPath.txt file and take the data into an array
if ( "$fetchSimFromDefaultPath" eq "YES" ) {
	@simulationStoragePath = &readSimulationStoragePath(
		$ossTrack,        $networkFlagLte, $networkFlagWran,
		$networkFlagGran, $networkFlagCore
	);
}
else {
	@simulationStoragePath = @listOfSimPath;
}
foreach (@simulationStoragePath) {
	LogFiles "INFO: USER_SPECIFIED_FTP_PATH = $_\n";
}

#
#---------------------------------------------------------------------------------
#Function call to create the environment on NETSim
#--------------------------------------------------------------------------------
#
foreach (@simulationStoragePath) {
	$workingPath = &getWorkingPath( "$_", "$ossTrack" );
	LogFiles "INFO: netsim_path = $workingPath\n";
	&setupEnvNetsim($workingPath);
}

#
#----------------------------------------------------------------------------------
#Function call to start the rollout
#----------------------------------------------------------------------------------
#
#The logic is here to sequentailly traverse through every path that and perfrom sequentail rollout
foreach (@simulationStoragePath) {
	$workingPath = &getWorkingPath( "$_", "$ossTrack" );
	&rollout( $_, $ossmasterAddress, $workingPath );
}

#
#---------------------------------------------------------------------------------
#Function call to set up TLS security
#--------------------------------------------------------------------------------
#
#TLS is set up for PICO and ECIM nodes
if ( "$securityStatusTLS" eq "ON" ) {

	#Set up security and create pem files on omsas server and copy it to netsim
	&setupSecurityOmsasTLS();

	#Copy pem files under relevant folder within netsim
	foreach (@simulationStoragePath) {
		$workingPath = &getWorkingPath( "$_", "$ossTrack" );
		&copyPem($workingPath);

		#Set up securit on netsim
		&setupSecurityNetsim($workingPath);
	}
}

#
#---------------------------------------------------------------------------------
#Function call to create the environment on ossmaster
#--------------------------------------------------------------------------------
#
if ( "$importStatus" eq "ON" ) {
	foreach (@simulationStoragePath) {
		$workingPath = &getWorkingPath( "$_", "$ossTrack" );
		LogFiles "INFO: osspath_path = $workingPath\n";
		&setupEnvOssmaster($workingPath);

		#Function call to copy ARNE XMLs
		&copyXML($workingPath);

		#Function call to import ARNE XMLs
		&import($workingPath);
	}
}

#
LogFiles("INFO: All the SimNetDeployer related activities are now complete.\n");

#
#---------------------------------------------------------------------------------
#Function call to set up security
#--------------------------------------------------------------------------------
#
#--------
#call SL3
#--------
#Status - Work in progress
#This is one of the most trouble making module as the working of caasAdmin script is not very clear
#SL3 security is set up for LTE and RNC nodes.
#if ("$securityStatusSL3" eq "ON") {
#	$tempSecurityPath = '/tmp/tempSecurity/SL3/';
#	&setupSecuritySL3($tempSecurityPath, $ossmasterAddress, $omsrvsAddress);
#}
#
#----------------
#call to copy pem
#----------------
#Status - Work in progress
#The idea here is to loop through and copy the certs that are generated.
#if (("$securityStatusTLS" eq "ON") || ("$securityStatusSL3" eq "ON")){
#	foreach (@simulationStoragePath) {
#        	$workingPath = &getWorkingPath("$_", "$ossTrack");
#		&copyPem($workingPath);
#	}
#}
##

