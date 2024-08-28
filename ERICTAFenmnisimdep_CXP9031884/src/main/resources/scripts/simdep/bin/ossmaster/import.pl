#!/usr/bin/perl -w
###################################################################################
#
#     File Name : import.pl
#
#     Version : 2.00
#
#     Author : Jigar Shah
#
#     Description : Imports XMLs present under /tmp/simNetDeployer/LTE-XML /tmp/simNetDeployer/WRAN-XML /tmp/simNetDeployer/CORE-XML.
#
#     Date Created : 16 January 2014
#
#     Syntax : ./import.pl <PATH>
#
#     Parameters : <PATH> The working directory
#
#
#     Example :  ./import.pl /tmp/LTE/simNetDeployer/
#
#     Dependencies : 1.
#
#     NOTE: 1.
#
#     Return Values : 1 -> Done
#
#
###################################################################################
#
#----------------------------------------------------------------------------------
#SubRoutine to capture Logs
#----------------------------------------------------------------------------------
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
my $dirSimNetDeployer = $ARGV[0];
chdir("$dirSimNetDeployer/dat/XML");

#----------------------------------------------------------------------------------
# Set up log file
#----------------------------------------------------------------------------------
$dateVar = `date +%F`;
chomp($dateVar);
$timeVar = `date +%T`;
chomp($timeVar);
open LOGFILEHANDLER,
  "+> $dirSimNetDeployer/logs/importLogs_$dateVar\_$timeVar.log"
  or die LogFiles("ERROR: Could not open log file");
LogFiles(
"INFO: You can find real time execution logs of this script at ../logs/importLogs_$dateVar\_$timeVar.log\n"
);

#

#----------------------------------------------------------------------------------
#import nodes
#----------------------------------------------------------------------------------
@listOfXML = `ls -1`;
my @importReporter;
$indexForImportReporter = 0;
foreach (@listOfXML) {
    chomp($_);
    LogFiles("INFO: Validating $_\n");
`/opt/ericsson/arne/bin/import.sh -f $_ -val:rall > $dirSimNetDeployer/logs/output$_.log`;
    $validTextValidate   = "There were 0 errors reported during validation";
    $compareTextValidate = `tail -1 $dirSimNetDeployer/logs/output$_.log`;
    chomp($compareTextValidate);
    if ( "$validTextValidate" eq "$compareTextValidate" ) {
        LogFiles("INFO: Valadition successful for $_. Now importing\n");
`/opt/ericsson/arne/bin/import.sh -f $_ -import -i_nau > $dirSimNetDeployer/logs/output$_.log`;
        $validTextImport   = "No Errors Reported.";
        $compareTextImport = `tail -1 $dirSimNetDeployer/logs/output$_.log`;
        chomp($compareTextImport);
        if ( "$validTextImport" eq "$compareTextImport" ) {
            LogFiles("INFO: Import successful for $_\n");
`mv $dirSimNetDeployer/logs/output$_.log $dirSimNetDeployer/logs/output$_.log.pass`;
            $importReporter[ $indexForImportReporter++ ] =
              "$_" . ":" . "PASS\n";
        }
        else {
            LogFiles("ERROR: Import not successful for $_\n");
`mv $dirSimNetDeployer/logs/output$_.log $dirSimNetDeployer/logs/output$_.log.fail`;
            $importReporter[ $indexForImportReporter++ ] =
              "$_" . ":" . "FAIL\n";
        }
    }
    else {
        LogFiles("ERROR: Validation not successful for $_\n");
`mv $dirSimNetDeployer/logs/output$_.log $dirSimNetDeployer/logs/output$_.log.fail`;
        $importReporter[ $indexForImportReporter++ ] = "$_" . ":" . "FAIL\n";
    }
}

open FH, ">$dirSimNetDeployer/logs/summaryImportReport.txt" or die;
print FH "@importReporter";
close FH;
