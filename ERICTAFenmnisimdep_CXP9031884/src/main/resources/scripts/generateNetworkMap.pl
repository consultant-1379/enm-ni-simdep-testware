#!/usr/bin/perl -w
use strict;
use Getopt::Long();
use Cwd qw(abs_path);
use File::Basename;
#
##############################################################################
#     File Name     : generateNetworkMap.pl
#     Author        : Sneha Srivatsav Arra
#     Description   : Generates networkMap.json at /netsim/netsimdir directory
#     Date Created  : 02 Nov 2016
###############################################################################
#
#------------------------------------------------------------------------------
#Variables
#------------------------------------------------------------------------------
my $PWD = dirname(abs_path($0));
chomp($PWD);

#---------------------------------------------------------------------------------
#Subroutine to create logfile
#---------------------------------------------------------------------------------
open logFileHandler, "+>>$PWD/generateNetworkMap.txt" or die $!;

sub LogFiles {
    my $dateVar = `date +%F`;
    chomp($dateVar);
    my $timeVar = `date +%T`;
    chomp($timeVar);
    print logFileHandler "$dateVar\_$timeVar: @_";
    print "$dateVar\_$timeVar: @_";
}

#---------------------------------------------------------------------------------
#Check if the user is root
#---------------------------------------------------------------------------------
my $user = `whoami`;
chomp($user);
my $root = 'root';
if ( $user ne $root ) {
    &LogFiles("Error: Not root user. Please execute the script as root \n");
    exit(1);
}

#----------------------------------------------------------------------------------
#Check if the script usage is right
#----------------------------------------------------------------------------------
my $USAGE = "Usage: $0 \n  E.g. $0 \n";
if ( @ARGV != 0 ) {
    print("$USAGE");
    exit(2);
}

#---------------------------------------------------------------------------------
# Generate Network Map JSON File
#---------------------------------------------------------------------------------
sub generateNetworkMap {
    my $generateNetworkMapCommand="echo '.generateNetworkMap' |/netsim/inst/netsim_shell";
    my $sleepTime = 0;
    LogFiles("Generating Network Map JSON File\n");
    system("rm -rf /netsim/netsimdir/networkMap.json");
    if ($? != 0) {
        LogFiles("INFO: Failed to execute system command (rm -rf /netsim/netsimdir/networkMap.json)\n");
        exit 207;
    }
    system("sudo su -l netsim -c '$generateNetworkMapCommand' > runtimeGenerateNetworkMap.txt");
    system("cat runtimeGenerateNetworkMap.txt");
    my $errorHandler = `$PWD/simdep/utils/netsim/checkForError.sh unknown runtimeGenerateNetworkMap.txt`;
    if ($errorHandler == 1) {
        foreach my $i (1..3) {
            LogFiles("INFO: Failed to generate Network Map JSON File. Retrying again ($i/3).\n");
            system("rm -rf /netsim/netsimdir/networkMap.json");
            if ($? != 0) {
                LogFiles("INFO: Failed to execute system command (rm -rf /netsim/netsimdir/networkMap.json)\n");
                exit 207;
            }
            system("sudo su -l netsim -c '$generateNetworkMapCommand' > failedGenerateNetworkMap.txt");
            system("cat failedGenerateNetworkMap.txt");
            my $errorHandlerFailed = `$PWD/simdep/utils/netsim/checkForError.sh unknown failedGenerateNetworkMap.txt`;
            if ($errorHandlerFailed == 1) {
                 if ($i == 3) {
                     LogFiles("ERROR: Failed to generate Network Map JSON File.\n");
                     LogFiles("##########################################\n");
                     exit 207;
                 }
            } else {
                 LogFiles("INFO: Network Map JSON file successfully created \n");
                 last;
            }
            sleep($sleepTime);
            $sleepTime = $sleepTime + 5;
        }
    } else {
        LogFiles("INFO: Network Map JSON file successfully created \n");
    }
}

generateNetworkMap();
close(logFileHandler);

