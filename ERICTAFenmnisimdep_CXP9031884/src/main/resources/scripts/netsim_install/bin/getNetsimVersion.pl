#!/usr/bin/perl -w

#created by   : Kiran Yakkala
# Created in  : 2015.03.10
##
### VERSION HISTORY
# Ver         : Follow up from gerrit
# Purpose     : To Feteh and install given NETSim License
# Dependency  : None
# Description : Fetehes and installs given NETSim License
# Date        : 10 Mar 2015
# Who         : Kiran Yakkala


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
     $logFile = "$PWD/../log/getNetsimVersion_$dateVar\_$timeVar.log";
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
        "  usage: $command -t=link -v=int \n" .
        "  usage: $command -t=rel -v=int \n"
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
    print STDERR ("[$dateVar $timeVar] @_");
}

my $noOfVersions;
my $type;
Getopt::Long::GetOptions(
    'v=s' => \$noOfVersions,
    't=s' => \$type
) or usage("Invalid commmand line options.");

usage("Enter netsim version.")
  unless defined $type && $noOfVersions;

my @productVersions = ();
my @releaseVersions = ();
my @releaseVersionsLink = ();
my @reverseReleaseVersions = ();
my $LINK_HEAD = "https://netsim.seli.wh.rnd.internal.ericsson.com/tssweb/";
my @htmlPage = `su - netsim -c "wget -O - $LINK_HEAD 2>/dev/null 2>&1"`;
if ( $? != 0 ){
    @htmlPage = `su - netsim -c "wget --no-proxy -O - $LINK_HEAD  2>/dev/null 2>&1"`;
    if ( $? != 0 ){
        print STDERR "@htmlPage";
        LogFiles("ERROR: Unable to access the following link: $LINK_HEAD \n");
        exit 204;
    }
}
foreach(@htmlPage) {
    if( /netsim6/ || /netsim7/) {
        my $version = $2 if /netsim(.*?)>(.*?)\/<\/a>(.*?)/;
        push(@productVersions, $version);
    }
}
# Start processing html page in order to get verfied patch name
my $i = 0;
foreach(@productVersions){
    my $LINK_RELEASES_HEAD = "https://netsim.seli.wh.rnd.internal.ericsson.com/tssweb/$_/released/";
    my @htmlPage1 = `su - netsim -c "wget -O - $LINK_RELEASES_HEAD 2>/dev/null 2>&1"`;
    if ( $? != 0 ){
        @htmlPage1 = `su - netsim -c "wget --no-proxy -O - $LINK_RELEASES_HEAD 2>/dev/null 2>&1"`;
        if ( $? != 0 ){
            print STDERR "@htmlPage1";
            LogFiles("ERROR: Unable to access the following link: $LINK_RELEASES_HEAD \n");
            exit 204;
    }
}

    foreach(@htmlPage1) {
        if ( /NETSim_UMTS/ ) {
            my $version = $1 if /NETSim_UMTS.(.*?)\">(.*?)<\/a><\/td>/;
            push(@releaseVersions, $version);
            my $versionLink = $LINK_RELEASES_HEAD . "NETSim_UMTS.$version/1_19089-FAB760956Ux.$version.zip";
            push(@releaseVersionsLink, $versionLink);
        }
        $i++;
    }
    push( @reverseReleaseVersions, reverse @releaseVersions);
    @releaseVersions=();
}

chomp($type);
if ( $type =~ m/^l/i ) {
    foreach(@releaseVersionsLink) {
        print "$_\n";
    }
}
 $i = 1;
if ( $type =~ m/^r/i ) {
    $arrSize = @reverseReleaseVersions;
    print "$reverseReleaseVersions[$arrSize-$noOfVersions] ";
}

