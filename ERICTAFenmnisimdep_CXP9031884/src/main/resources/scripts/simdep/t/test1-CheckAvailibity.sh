#!/usr/bin/perl -w
use Expect;
use Net::OpenSSH;
use Cwd 'abs_path';


#Creating SSH object
#my $ossmasterName="ossmaster";
my $ossmasterName="192.168.0.5";
my $ossmasterUser="root";
my $ossmasterPass="shroot";


#
#---------------------------------------------------------------------------------
#Function call to read oss track
#---------------------------------------------------------------------------------
sub readOssTrack {
	print("INFO: Accessing OSS Master to read oss track\n");

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
	  $sshOssmaster->capture2( { timeout => 100 },
		"cat  /var/opt/ericsson/sck/data/cp.status" );
	$sshOssmaster->error and die "ssh failed: " . $sshOssmaster->error;
	my @cpStatusDat   = split( / /, $outputOssmaster );
	my @ossTrackField = split( /_/, $cpStatusDat[1] );
	my $ossTrack = $ossTrackField[4];
	return $ossTrack;
}


#---------------------------------------------------------------------------------
#Function call to read OSS Track
#---------------------------------------------------------------------------------
#
$ossTrack = &readOssTrack();

print "ossTrack = $ossTrack \n";



