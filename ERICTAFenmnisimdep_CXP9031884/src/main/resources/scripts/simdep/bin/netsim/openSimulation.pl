#!/usr/bin/perl -w
###################################################################################
#
#     File Name : openSimulation.pl
#
#     Version : 2.00
#
#     Author : Jigar Shah
#
#     Description : gets files from FTP server
#
#     Date Created : 23 October 2013
#
#     Syntax : ./openSimulation <simName>
#
#     Parameters : <simName> The name of the simulation that needs to be opened in NETSim
#
#     Example :  ./openSimulation CORE-K-FT-M-MGwB15215-FP2x1-vApp.zip
#
#     Dependencies : 1.
#
#     NOTE:
#
#     Return Values : 1 -> Not a netsim user
#                     2 -> Usage is incorrect
#
###################################################################################
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
$USAGE =
"ERROR:\nUsage: $0 <simName> <clearClock> \n  E.g. $0 CORE-K-FT-M-MGwB15215-FP2x1-vApp.zip no\n";
if ( @ARGV != 2 ) {
    print "$USAGE";
    exit(202);
}

#
#----------------------------------------------------------------------------------
#Variables
#----------------------------------------------------------------------------------
my $NETSIM_INSTALL_SHELL = "/netsim/inst/netsim_pipe";
my $simNameTemp          = "$ARGV[0]";
@tempSimName = split( '\.zip', $simNameTemp );
my $simName    = $tempSimName[0];
my $simNameLoc = "/netsim/netsimdir/$simName";

#
#----------------------------------------------------------------------------------yy
#
#Define NETSim MO file and Open file in append mode
#----------------------------------------------------------------------------------
$MML_MML = "MML.mml";
open MML, "+>>../dat/$MML_MML";

#
#----------------------------------------------------------------------------------
# Check if sim exist
#----------------------------------------------------------------------------------
if ( -e "$simNameLoc" ) {
    print "simName=$simName exists at $simNameLoc \n";
    print MML ".deletesimulation $simName force\n";
}

#---------------------------------------------------------------------------------
# Clear if there is any uncompress lock in NETSim
# --------------------------------------------------------------------------------
if ( "$ARGV[1]" eq "yes" ) {
    print MML ".uncompressandopen clear_lock\n";
    print MML ".sleep 30\n";
}

#
#----------------------------------------------------------------------------------
#Unzip and Open the Simulation in NetSim.
#----------------------------------------------------------------------------------
if ($simName=~ m/RNC/i) {
print MML ".uncompressandopen $simName force\n";
print MML ".select network\n";
print MML ".emptyfilestore\n";
} else {
print MML ".uncompressandopen $simName force\n";
print MML ".select network\n";
}

system("$NETSIM_INSTALL_SHELL < ../dat/$MML_MML");
if ($? != 0)
{
    print "ERROR: Failed to execute system command ($NETSIM_INSTALL_SHELL < ../dat/$MML_MML)\n";
    exit(207);
}
close MML;
system("rm ../dat/$MML_MML");
if ($? != 0)
{
    print "INFO: Failed to execute system command (rm ../dat/$MML_MML)\n";
}
