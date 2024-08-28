#!/usr/bin/perl -w
###################################################################################
#
#     File Name : summaryReportGenerator.pl
#
#     Version : 1.00
#
#     Author : Jigar Shah
#
#     Description : Reads the following data from the simuation and generates summary reports.
#
#     Date Created : 05 Feburary 2014
#
#     Syntax : ./summaryReportGenerator.pl <simName>
#
#     Parameters : <simName> The name of the simulation whos data needs to be read
#
#     Example :  ./summaryReportGenerator.pl CORE-K-FT-M-MGwB15215-FP2x1-vApp.zip
#
#     Dependencies : 1.
#
#     NOTE:
#
#     Return Values :   1 -> Not a netsim user
#                       2 -> Usage is incorrect
#
#
###################################################################################
#
#----------------------------------------------------------------------------------
#Variables
my $NETSIM_INSTALL_SHELL = "/netsim/inst/netsim_shell";
my $index                = 0;

my $dirSimNetDeployer = "$ARGV[0]";

#
#----------------------------------------------------------------------------------
#Check if the scrip is executed as netsim user
#----------------------------------------------------------------------------------
#
$user = `whoami`;
chomp($user);
$netsim = 'netsim';
if ( $user ne $netsim ) {
    print "ERROR: Not netsim user. Please execute the script as netsim user\n";
    exit(201);
}

#
#----------------------------------------------------------------------------------
#Check if the script usage is right
#----------------------------------------------------------------------------------
$USAGE = "Usage: $0 <Working Dir Path> \n  E.g. $0 \n";

# HELP
if ( @ARGV != 1 ) {
    print "ERROR: $USAGE";
    exit(202);
}

#
#----------------------------------------------------------------------------------
#Env variable
#----------------------------------------------------------------------------------

#----------------------------------------------------------------------------------
@readAllSimDataName =
`echo ".show started" | $NETSIM_INSTALL_SHELL | grep -i "^    " | grep -v "NE" | awk -F" " \'{print \$1}\'`;

#print "We are now verifying if the output is OK @readAllSimDataName\n";
@readAllSimDataAddress =
`echo ".show started" | $NETSIM_INSTALL_SHELL | grep -i "^    " | grep -v "NE" | awk -F" " \'{print \$2}\'`;

#print "We are now verifying if the output is OK @readAllSimDataAddress\n";

my %hashReporter;
@hashReporter{@readAllSimDataName} = @readAllSimDataAddress;

#So at this stage we have all the NE names and their address mapped to key value pair in the hash.
#while (my ($k,$v)=each %hashReporter){
#chomp($k);
#chomp($v);
#print "$k $v \n";
#}
#We will now read all the NE that have been rolled out so far.
open FH, "$dirSimNetDeployer/dat/listNeName.txt" or die;
my @allSimNe = <FH>;
close FH;

#print "List of all the simulations NE that we have read are @allSimNe\n";

#We will now read all the simulations that are fetched
open FH1, "$dirSimNetDeployer/dat/listSimulation.txt" or die;
my @allSim = <FH1>;
close FH1;

#print "List of all the simulations NE that we have read are @allSim\n";

#We will now read all the simulations that are passed
open FH2, "$dirSimNetDeployer/dat/listSimulationPass.txt" or die;
my @allSimRollout = <FH2>;
close FH2;
$index = 0;

#print "List of all the simulations NE that we have passed are @allSimRollout\n";

#The bloew logic is to decide if a NE is ONLINE or OFFLINE and make a summary report.
foreach (@allSimNe) {
    $NeLabel = $_;
    chomp($NeLabel);
    if ( exists $hashReporter{$_} ) {
        $neAddress = $hashReporter{$_};
        chomp($neAddress);

        #print "$NeLabel : $temp ONLINE \n";
        $summaryReport[$index] =
          "INFO: " . "$NeLabel" . ":" . "$neAddress" . ":" . "ONLINE\n";
    }
    else {

        #print "$NeLabel : OFFLINE \n";
        $summaryReport[$index] = "INFO: " . "$NeLabel" . ":" . "OFFLINE\n";
    }
    $index++;
}

#The bloew logic is to decide if a simulation is ONLINE or OFFLINE
$inc = 0;
foreach (@allSim) {

    #A special usage ~~ which check if one element is present in an entire array
    if ( $_ ~~ @allSimRollout ) {
        chomp($_);
        $simReport[$inc] = "INFO: " . "$_" . ":" . "ONLINE\n";

        #print "The sim is present \n";
    }
    else {
        chomp($_);
        $simReport[$inc] = "INFO: " . "$_" . ":" . "OFFLINE\n";

        #print "Not present \n";
    }
    $inc++;
}
print
"Creating allNeSummaryReport.txt which display ONLINE / OFFLINE status of sim under $dirSimNetDeployer/logs/allNeSummaryReport.txt\n";
open allNeSummaryReport, ">$dirSimNetDeployer/logs/allNeSummaryReport.txt"
  or die;
print allNeSummaryReport @summaryReport;
close allNeSummaryReport;
print
"Creating finalSummaryReport.txt which display ONLINE / OFFLINE status of sim under $dirSimNetDeployer/logs/finalSummaryReport.txt\n";
open SIMREPORT, ">$dirSimNetDeployer/logs/finalSummaryReport.txt" or die;
print SIMREPORT @simReport;
close SIMREPORT;
