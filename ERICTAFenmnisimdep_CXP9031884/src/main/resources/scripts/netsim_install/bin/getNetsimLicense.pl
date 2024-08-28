#!/usr/bin/perl -w
use Getopt::Long();
my $logFile = $ENV{'logFile'};
my $PWD = `pwd`;
chomp($PWD);
if( ! defined $logFile )
{
    $dateVar = `date +%F`;
    chomp($dateVar);
    $timeVar = `date +%T`;
    chomp($timeVar);
    $logFile = "$PWD/../log/getNetsimLicense_$dateVar\_$timeVar.log";
}

#----------------------------------------------------------------------------------
#Check if the script usage is right
#----------------------------------------------------------------------------------
sub usage {
    my $message = $_[0];
    if ( defined $message && length $message ) {
        $message = "HELP: $message \n"
          unless $message =~ /\n$/;
    }
    my $command = $0;
    $command =~ s#^.*/##;
    print STDERR (
        $message,
        "  usage: $command -v=R28A -t=link \n" .
        "  usage: $command -v=R27J -t=rel \n"
    );
    exit 1
  #  die("\n");
}
#
#----------------------------------------------------------------------------------
#SubRoutine to capture Logs
#----------------------------------------------------------------------------------
#
sub LogFiles {
    $dateVar = `date +%b_%d`;
    chomp($dateVar);
    $timeVar = `date +%T`;
    chomp($timeVar);
    print STDERR "[$dateVar $timeVar] @_";
}

my $version;
my $type;

Getopt::Long::GetOptions(
    'v=s' => \$version,
    't=s' => \$type
) or usage("Invalid commmand line options.");

usage("Enter netsim version and release type.")
  unless defined $version && $type;


my $PRODUCT_VERSION = $version;
my $LINK_HEAD = "http://netsim.lmera.ericsson.se/licences/";
my @releaseVersions = ();
my @releaseVersionsLink = ();

#print "PRODUCT_VERSION=$PRODUCT_VERSION \n";

# Start downloading Netsim Licenses html page
my @htmlPage = `su - netsim -c "wget -O - $LINK_HEAD 2>/dev/null 2>&1"`;
if ( $? != 0 ){
    @htmlPage = `su - netsim -c "wget --no-proxy -O - $LINK_HEAD 2>/dev/null 2>&1"`;
    if ( $? != 0 ){
        print STDERR "@htmlPage";
        LogFiles("ERROR: Unable to access the following link: $LINK_HEAD \n");
        exit 204;
    }
}

# Start processing html page in order to get License name
my $i = 0;
foreach(@htmlPage) {
    if ( /Generic_Ericsson/ ) {
        my $licensename = $2 if /Generic_Ericsson.(.*?)\">(.*?)<\/a><\/td>/;
        push(@releaseVersions, $2);
        my $versionLink = $LINK_HEAD . "$licensename";
        push(@releaseVersionsLink, $versionLink);
    }
    $i++;
}
chomp($type);

if ( $type =~ m/^l/i ){
    $i = 1;
    foreach(@releaseVersionsLink) {
        print "$_\n";
    }
}
if ( $type =~ m/^r/i ){
    $i = 1;
    foreach(@releaseVersions) {
        print "$_\n";
    }
}

