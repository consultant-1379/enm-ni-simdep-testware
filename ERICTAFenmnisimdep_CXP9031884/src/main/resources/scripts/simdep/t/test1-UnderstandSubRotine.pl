#!/usr/bin/perl -w
use Net::FTP;
use Expect;
use Net::SSH::Expect;
use Net::OpenSSH;

my $ossServerName = 'ossmaster';
@arr = `nslookup $ossServerName`;
$ossmasterAddress = substr( $arr[4], 9 );
chomp($ossmasterAddress);
my $omsrvsServerName = 'omsrvm';
@arr = `nslookup $omsrvsServerName`;
$omsrvsAddress = substr( $arr[4], 9 );
chomp($omsrvsAddress);
$dateVar = `date +%F`;
chomp($dateVar);
$timeVar = `date +%T`;
chomp($timeVar);

LogFiles("ERROR: Could not open log file");

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

	#print LOGFILEHANDLER "$timeVar:<$hostName>: @_";
	print "$timeVar:<$hostName>: @_ \n";
}

my ( $v1, $v2 ) = ( "fatih", "onur" );
upcase_in( $v1, $v2 );    # this changes $v1 and $v2

sub upcase_in {
	for (@_) { tr/a-z/A-Z/ }
}
print "v1=$v1, v2=$v2 \n";

