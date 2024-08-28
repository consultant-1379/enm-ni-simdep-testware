#!/usr/bin/perl -w
use Getopt::Long();
my $logFile = $ENV{'logFile'};
my $PWD = `pwd`;
chomp($PWD);
if( ! defined $logFile ){
    $dateVar = `date +%F`;
    chomp($dateVar);
    $timeVar = `date +%T`;
    chomp($timeVar);
    $logFile = "$PWD/../log/getNetsimVerifiedPatchList_$dateVar\_$timeVar.log";
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
        "  usage: $command -v=R27J \n" .
        "  usage: $command -v=R27J -q \n"
    );

    die("\n");
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
my $quiet= '';	# option variable with default value (false)

Getopt::Long::GetOptions(
    'v=s' => \$version,
    'q' => \$quiet,
) or usage("Invalid commmand line options.");

usage("Enter netsim version.")
  unless defined $version && length($version) > 3;

#----------------------------------------------------------------------------------
#Subroutine to return netsim product version
#----------------------------------------------------------------------------------
sub getNetsimProductVersion {
    my $netsimVersion = $_[0];
    return "" if length($netsimVersion) < 3;

    my $netsimMajorVersion = substr($netsimVersion, 1,1);
    my $netsimMinorVersion = substr($netsimVersion, 2,1);

    my $productMajorVersion = $netsimMajorVersion + 4;
    my $productVersion = $productMajorVersion . ".". $netsimMinorVersion;
    return $productVersion;
}

#----------------------------------------------------------------------------------
#Subroutine to check wheter PATCH link is provided
#----------------------------------------------------------------------------------
sub isNetsimPatchLinkAvailable{
    my $LINK_HEAD = $_[0];
    my $NETSIM_VERSION = $_[1];
    my @htmlPage = `su - netsim -c "wget -q --spider $LINK_HEAD 2>/dev/null 2>&1"`;
    if ( $? != 0 ){
       @htmlPage = `su - netsim -c "wget --no-proxy -q --spider $LINK_HEAD 2>/dev/null 2>&1"`;
       if ( $? != 0 ){
            print "INFO: No patches available for $NETSIM_VERSION yet\n";
            return -1;
        }
        else {
            print "INFO: $LINK_HEAD link is available \n";
            return 0;
        }
   }
    else {
        print "INFO: $LINK_HEAD link is available \n";
            return 0;
        }
}

my $PRODUCT_VERSION = &getNetsimProductVersion($version);
my $NETSIM_VERSION = $version;
my $LINK_HEAD = "http://netsim.lmera.ericsson.se/tssweb/netsim$PRODUCT_VERSION/released/NETSim_UMTS.$NETSIM_VERSION/Patches/";
my @verifiedPatches = ();
my @verifiedPatchesLink = ();

if (&isNetsimPatchLinkAvailable($LINK_HEAD, $NETSIM_VERSION)){
    exit;
}

# Start downloading NetsimPatches html page
my @htmlPage = `su - netsim -c "wget -O - $LINK_HEAD 2>/dev/null 2>&1"`;
if ( $? != 0 ){
    @htmlPage = `su - netsim -c "wget --no-proxy -O - $LINK_HEAD 2>/dev/null 2>&1"`;
    if ( $? != 0 ){
        if ($quiet){
            exit;
        } else {
            print STDERR "@htmlPage";
            LogFiles("ERROR: Unable to access the following link: $LINK_HEAD \n");
            exit 204;
        }
    }
}

# Start processing html page in order to get verfied patch name
my $i = 0;
foreach(@htmlPage) {
    if ( /zip">(.*?)<\/a><\/td>/ ) {
       my $patch= $1 if /zip">(.*?)<\/a><\/td>/;
       my $status = $htmlPage[$i-3];
       my @matches = ( $status =~ />(.*?)</ );
       $status = $matches[0];

       if ( "$status" !~ m/not/i ){
           push(@verifiedPatches, $patch);
           my $patchLink = $LINK_HEAD . $patch;
           push(@verifiedPatchesLink, $patchLink);
       }
    }
    $i++;
}

$i = 1;
foreach(@verifiedPatches) {
}

# START printing verfied patch links
$i = 1;
foreach(@verifiedPatchesLink) {
    print "$_\n";
}

