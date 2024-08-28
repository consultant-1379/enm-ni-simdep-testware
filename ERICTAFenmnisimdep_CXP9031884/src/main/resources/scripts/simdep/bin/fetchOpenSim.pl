#!/usr/bin/perl -w
###################################################################################
#
#     File Name : fetchOpenSim.pl
#
#     Version : 2.00
#
#     Author : Harsha Yeluru, Chaitanya I
#
#     Description : gets files from FTP/PORTAL server
#
#     Date Created : 23 October 2013
#
#     Syntax : ./openSimulation <simName> <simLocation> <simZip>
#
#     Parameters : <simName> The name of the simulation that needs to be opened in NETSim
#                  <simLocation> Location of simulation in CI Portal
#                  <simZip> Simulation name with .zip extension
#
#     Example :  ./fetchOpenSim.pl CORE-MSC-S-BC-APG43L-IS-R18A-V2x1-MSC06-18.09.2 https://arm1s11-eiffel004.eiffel.gic.ericsson.se:8443/nexus/content/repositories/nss/com/ericsson/nss/Simnet_15K/CORE-MSC-S-BC-APG43L-IS-R18A-V2x1-MSC06/18.09.2/CORE-MSC-S-BC-APG43L-IS-R18A-V2x1-MSC06-18.09.2.zip CORE-MSC-S-BC-APG43L-IS-R18A-V2x1-MSC06-18.09.2.zip
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
"ERROR:\nUsage: $0 <simName> \n  E.g. $0 CORE-K-FT-M-MGwB15215-FP2x1-vApp.zip\n";
if ( @ARGV != 4 ) {
    print "$USAGE";
    exit(202);
}

#
#----------------------------------------------------------------------------------
#Variables
#----------------------------------------------------------------------------------
my $NETSIM_INSTALL_SHELL = "/netsim/inst/netsim_pipe";
my $simNameTemp          = "$ARGV[0]";
my $simLocation          = "$ARGV[1]";
my $simZip               = "$ARGV[2]";
@tempSimName = split( '\.zip', $simNameTemp );
my $simName    = $tempSimName[0];
my $simNameLoc = "/netsim/netsimdir/$simName";

#
#----------------------------------------------------------------------------------yy
#
#Define NETSim MO file and Open file in append mode
#----------------------------------------------------------------------------------
$MML_MML = "MML.mml";
open MML, "+>>../dat/$MML_MML" or die "Can not open $MML_MML";
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
if ( "$ARGV[3]" eq "yes" ) {
    print MML ".uncompressandopen clear_lock\n";
    print MML ".sleep 30\n";
}

#
#----------------------------------------------------------------------------------
#Unzip and Open the Simulation in NetSim.
#----------------------------------------------------------------------------------
if ($simName=~ m/RNC/i) {
print MML ".uncompressandopen $simZip force\n";
print MML ".select network\n";
print MML ".emptyfilestore\n";
} else {
print MML ".uncompressandopen $simZip force\n";
print MML ".select network\n";
}
system("$NETSIM_INSTALL_SHELL < ../dat/$MML_MML");
if ($? != 0)
{
    print "ERROR: Failed to execute system command ($NETSIM_INSTALL_SHELL < ../dat/$MML_MML)\n";
    exit(207);
}
close MML;
system("rm -rf /netsim/netsimdir/$simZip");
