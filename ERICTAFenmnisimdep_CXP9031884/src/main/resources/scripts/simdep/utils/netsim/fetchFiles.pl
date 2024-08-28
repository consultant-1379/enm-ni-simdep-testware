#!/usr/bin/perl -w
use strict;
use Net::FTP;
use Config::Tiny;
use File::Copy;
use Cwd;
###################################################################################
#
#     File Name : fetchFiles.pl
#
#     Version : 3.00
#
#     Author : Fatih Onur
#
#     Description : Gets files from specifeid location.
#
#     Date Created : 28 March 2016
#
#
###################################################################################
#
#----------------------------------------------------------------------------------
# Check if the scrip is executed as netsim user
#----------------------------------------------------------------------------------
#
my $user = `whoami`;
chomp($user);
my $netsim = 'netsim';
if ( $user ne $netsim ) {
    print "ERROR: Not netsim user. Please execute the script as netsim user\n";
    exit(201);
}

#
#----------------------------------------------------------------------------------
# Check if the script usage is right
#----------------------------------------------------------------------------------
my $USAGE =<<USAGE;
    Usage:
        $0 <fetchMethod> <filePath> <sims>

        where:
            <fetchMetod> : Specifeis how to fetch sims. Possible values: LOCAL|FTP|PORTAL
            <filePath>   : Specifies location of sims.
            <sims>       : Allows to filter sims.

        usage examples:
             $0 LOCAL /tmp/sims/16.2/CORE/
             $0 FTP /sims/O15/ENM/15.1/mediumDeployment/LTE LTE01:LTE02
             $0 FTP /sims/O15/ENM/15.1/mediumDeployment/LTE LTE01
             $0 PORTAL /sims/portal/LTE/16.9 LTE01:LTE02

        dependencies:
              1. Should be able to access storage device - FTP or NEXUS server.

        Return Values: 1 -> Not a netsim user
               2 -> Usage is incorrect
               ../dat/listSimulation.txt -> list of all the simulations fetched
USAGE

# HELP
if ( @ARGV < 2 or @ARGV > 3 ) {
    print "ERROR: Invalid command line options. \n$USAGE";
    exit(202);
}
print "\nRUNNING: $0 @ARGV \n";

#
#----------------------------------------------------------------------------------
# Parameters and env variables
#----------------------------------------------------------------------------------
my $fetchSimsMethod = "FTP";
my $simsFileFromPortal="/netsim/simdepContents/simsList.txt";
my $simsFileFromPortalOriginal="/netsim/simdepContents/Simnet_*_CXP*.*.content";
$fetchSimsMethod    = $ARGV[0];
my $filePath        = $ARGV[1];
my $sim             = $ARGV[2];

print "INFO: Sim filter: $sim \n" if defined $sim;
my $PWD = getcwd;

#
#------------------------------------------
# Config file params
#------------------------------------------
my $confPath = "$PWD/../conf/conf.txt";
my $Config = Config::Tiny->new;
print("INFO: Reading config file from $confPath \n");
$Config = Config::Tiny->read($confPath);

#my $fetchSimsMethod = $Config->{servers}->{FETCH_SIMS_METHOD};
#print "INFO: FETCH_SIMS_METHOD:$fetchSimsMethod \n";

#
#------------------------------------------
# Details of FTP server and the credentials.
#------------------------------------------
my $ftpHost = $Config->{servers}->{FTP_SERVER};
my $ftpUser = $Config->{servers}->{FTP_USER};
my $ftpPass = $Config->{servers}->{FTP_PASS};
my $fetchFromFtp = $Config->{servers}->{FETCH_FROM_FTP};
#my $fetchSimsFromLocalFolder = $Config->{servers}->{FETCH_SIMS_FROM_LOCAL_FOLDER};
if ( lc "$fetchSimsMethod" eq lc "portal" ) {
    $fetchFromFtp = "no";
} else {
    print "INFO: FTP_HOST:$ftpHost";
    print " FTP_USER:$ftpUser";
    print " FTP_PASS:$ftpPass";
    print " FETCH_FROM_FTP:$fetchFromFtp \n";
}

#
#----------------------------------------------------------------------------
# SubRoutine to fetch sims from Portal
#
#----------------------------------------------------------------------------
#
sub fetchSimsFromPortal {
    my $simsFileFromPortal = $_[0];
    my $filePath           = $_[1];
    my $sim                = $_[2];
    my $index = 0;
    my @downloadedFiles = ();

    my @pathList = split "/", $filePath;    #$filePath structure: /sims/portal/LTE/16.1/
    my $networkType = $pathList[3];

    if (-e $simsFileFromPortal) {
        if ( defined $sim and $sim ne "") {
            print "INFO: Download Mode: Sim Specific\n";
            open simInfo, $simsFileFromPortal or die "ERROR: Could not open $simsFileFromPortal: $!";
            my @simContent = <simInfo>;
            close simInfo;
            my @sims = split (/:/, $sim);

            foreach my $sim (@sims) {
                substr $sim, index($sim, ".zip"), 4,"" if "$sim" =~ /\.zip/;
                foreach my $simPath (@simContent) {
                    my $exactSim = $sim.'-';
                    if ($simPath =~ m/$exactSim/i) {
                        my @simName = split "/", $simPath;
                        my $simulation = "$simName[11]" . ".zip";
                        $downloadedFiles[$index++] = "$simulation\n";
                    }
                }
            }
        } else {
            print "INFO: Download Mode: Default (All files under location: $simsFileFromPortal path with $networkType) \n";
            open simInfo, $simsFileFromPortal or die "ERROR: Could not open $simsFileFromPortal: $!";
            my @simContent = <simInfo>;
            close simInfo;
            foreach my $simPath (@simContent) {
                if ($simPath =~ m/$networkType/i) {
                    my @simName = split "/", $simPath;
                    my $simulation = "$simName[11]" . ".zip";
                    $downloadedFiles[$index++] = "$simulation\n";
                }
            }
        }
    } else {
        print "ERROR: $simsFileFromPortal does not exist. \n";
        exit 206;
    }
    return @downloadedFiles;
}
#
#----------------------------------------------------------------------------
# SubRoutine to fetch sims from Nexus = INCOMPLETE
#----------------------------------------------------------------------------
#
sub fetchSimsFromNexus {
    my $filePath   = $_[0];

    # Following line needs some check here
    my @pathList = split(m%%); # my @pathList = split(m%/% $ARGV[0]);
    my $network = $pathList[0];
    my $testType = $pathList[1];
    my $simVersion = $pathList[2];
    my $ossTrack = $pathList[3];
    my $simStatus = $pathList[4];
    my $str = "$PWD/../utils/searchNexusSimNet.pl  $ossTrack $network $testType $simVersion DOWNLOAD  $simStatus" ;
    `$str | tee -a ../logs/runtimLogFetchFiles.txt`;
}
#
#----------------------------------------------------------------------------
# SubRoutine to fetch files from a defined ftp server
#----------------------------------------------------------------------------
#
sub fetchSimsFromFtp {
    my $ftpHost   = $_[0];
    my $ftpUser   = $_[1];
    my $ftpPass   = $_[2];
    my $filePath  = $_[3];
    my $sim       = $_[4];

    my @downloadedFiles = ();

    my $index = 0;
    my $ftp = Net::FTP->new($ftpHost) or die "ERROR: Car't open $ftpHost\n";
    $ftp->login( $ftpUser, $ftpPass ) or die "ERROR: Can't log $ftpUser in\n";
    $ftp->cwd($filePath) or die "ERROR: Can't cwd to $filePath\n";
    my @filesToGet = $ftp->ls;

    if ( defined $sim  && $sim ne "" ) {
        print "INFO: Download Mode: Sim Specific\n";

        my @sims = split (/:/, $sim);
        foreach my $sim (@sims) {
            foreach my $fileToGet (@filesToGet) {
                if($fileToGet =~ /$sim/) {
                    if($fileToGet =~ /\.zip$/i) {
                        # $fileToGet is a zip file
                        $ftp->binary;
                        $ftp->get($fileToGet) or die "ERROR: Failed to get $fileToGet\n";
                        $downloadedFiles[$index++] = "$fileToGet\n";
                        print "INFO: Downloaded: $fileToGet \n";
                    }
                }
            }
        }
    } else {
        print "INFO: Download Mode: Default (All files under location: $filePath) \n";

        foreach my $fileToGet (@filesToGet) {
            if($fileToGet =~ /\.zip$/i) {
                # $fileToGet is a zip file
                $ftp->binary;
                $ftp->get($fileToGet) or die "ERROR: Failed to get $fileToGet\n";
                $downloadedFiles[$index++] = "$fileToGet\n";
                print "INFO: Downloaded: $fileToGet \n";
            }
        }
    }

    return @downloadedFiles;
}

#
#----------------------------------------------------------------------------
# SubRoutine to copy sims from local folder
#----------------------------------------------------------------------------
#
sub copyMoveFile {
    my $sourceDir = $_[0];
    my $targetDir = $_[1];
    my $file      = $_[2];
    my $operator  = $_[3];

    if (lc $operator eq lc "move") {
       print "INFO: Moving file:$file from:$sourceDir to:$targetDir \n";
       move("$sourceDir/$file", "$targetDir/$file") or die "ERROR: Failed to move $file: $!\n";
       print "INFO: Moved: $file \n";
    } elsif (lc $operator eq  lc "copy") {
       print "INFO: Copying file:$file from:$sourceDir to:$targetDir \n";
       copy("$sourceDir/$file", "$targetDir/$file") or die "ERROR: Failed to copy $file: $!\n";
       print "INFO: Copied: $file \n";
    }
    return 1;
}
#
#----------------------------------------------------------------------------
# SubRoutine to copy sims content to a different file.
#----------------------------------------------------------------------------
#
sub copySimsContent {
    my $sourceFile = $_[0];
    my $targetFile = $_[1];

    print "INFO: Copying $sourceFile to $targetFile \n";
    my $errorStatus = system ("cp -v $sourceFile $targetFile");
    if ($errorStatus) {
        print "ERROR: Failed to copy $sourceFile to $targetFile \n";
    } else {
        print "INFO: Copied: $sourceFile to $targetFile  \n";
    }
    my $cmdErrorStatus = system("perl -p -i -e 's/\"//g' $targetFile");
    if ($cmdErrorStatus) {
        print "ERROR: Failed to remove quotes from $targetFile \n";
    }
}

#
#----------------------------------------------------------------------------
# SubRoutine to fetch sims from local folder
#----------------------------------------------------------------------------
#
sub fetchSimsFromLocalFolder {
    my $filePath = $_[0];
    my $sim      = $_[1];
    my $operator = $_[2];

    my @selectedFiles = ();
    my $index = 0;
    my $netsimDir = "/netsim/netsimdir";

    opendir  (DIR, $filePath) || die "Can't open directory $filePath: $!";
    my @files = grep {/\.zip$/} grep { (!/^\./)  && -f "$filePath/$_" } readdir(DIR);
    closedir DIR;

    if ( defined $sim  && $sim ne "" ) {
        print "INFO: Copy|Move Mode: Sim Specific\n";
        my @sims = split (/:/, $sim);
        foreach my $sim (@sims) {
           print "INFO: Begin searching file that contains: $sim \n";
           foreach my $file (@files) {
               #print "file:$file \n";
               if($file =~ /$sim/) {
                   #print "matched:$file \n";
                   if (&copyMoveFile($filePath, $netsimDir, $file, $operator)) {
                       $selectedFiles[$index++] = "$file\n";
                   } else {
                      print "ERROR: Unable to find the file: $file at filePath: $filePath \n";
                   }
               }
           }
       }
    } else {
        print "INFO: Copy|Move Mode: Default (All files under location: $filePath) \n";
        foreach my $file (@files) {
            &copyMoveFile($filePath, $netsimDir, $file, $operator);
            $selectedFiles[$index++] = "$file\n";
        }
    }

    return @selectedFiles;
}

my @transferedFiles = ();

#
#-----------------------------------------------
#Access the FTP|LOCAL server and fetch relevant files.
#-----------------------------------------------
#
print "INFO: Start fetching sims from $fetchSimsMethod server. \n";

if ( lc $fetchSimsMethod eq lc "PORTAL") {

    &copySimsContent($simsFileFromPortalOriginal, $simsFileFromPortal);
    chdir("/netsim/netsimdir/");
    @transferedFiles = &fetchSimsFromPortal($simsFileFromPortal, $filePath, $sim);

} elsif (lc $fetchSimsMethod eq lc "LOCAL") {

    @transferedFiles = &fetchSimsFromLocalFolder($filePath, $sim, "COPY");

} elsif ( lc $fetchSimsMethod eq lc "FTP" ) {

    chdir("/netsim/netsimdir/");
    @transferedFiles = &fetchSimsFromFtp($ftpHost, $ftpUser, $ftpPass, $filePath, $sim);

} else {

   chdir("/netsim/netsimdir/");
   @transferedFiles = &fetchSimsFromFtp($ftpHost, $ftpUser, $ftpPass, $filePath, $sim);

}

print "INFO: End of fetching sims from $fetchSimsMethod server. \n";

#
#------------------------------------------------------------------
#List of files transfered
#------------------------------------------------------------------
open dumpSimNameList, ">$PWD/../dat/listSimulation.txt";
print dumpSimNameList @transferedFiles;
close dumpSimNameList;

