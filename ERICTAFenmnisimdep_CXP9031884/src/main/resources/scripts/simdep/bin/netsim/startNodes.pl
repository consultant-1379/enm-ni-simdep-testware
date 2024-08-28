#!/usr/bin/perl -w
use strict;
use Data::Dumper qw(Dumper);
###################################################################################
#     USAGE
#
#     Perl rules: Do not include underscores in Variable names. Camel case for variables and upper case for static data.
#     the starting word
#
#     File Name : startNodes.pl
#
#     Version : 5.00
#
#     Author : Fatih ONUR
#
#     Description : starts Nodes of a simulation based and set load balancing
#
#     Date Created : 29 Feb 2016
#
#     Syntax : ./startNodes.pl <simName> <neTypeName|neTypeNameArr>
#
#     Parameters : <simName> The name of the simulation that needs to be opened in NETSim
#
#     Example :  ./startNodes.pl LTE15B-V13x80_16B-V6x80-5K-DG2-FDD-LTE08.zip "LTE MSRBS-V2 16B-V6:LTE MSRBS-V2 15B-V13"
#     Example :  ./startNodes.pl LTE15B-V13x80_16B-V6x80-5K-DG2-FDD-LTE08.zip "LTE MSRBS-V2 16B-V6"
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
#Variables
my $NETSIM_INSTALL_SHELL = "/netsim/inst/netsim_pipe";

#
#----------------------------------------------------------------------------------
#Check if the scrip is executed as netsim user
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
#Check if the script usage is right
#----------------------------------------------------------------------------------
my $USAGE =
  "Usage: $0 <simName> <neTypeFullNameArray> \n
  E.g. $0 LTE15B-V13x80_16B-V6x80-5K-DG2-FDD-LTE08.zip  \"LTE MSRBS-V2 16B-V6:LTE MSRBS-V2 15B-V13\"
  E.g. $0 LTE15B-V13x80_16B-V6x80-5K-DG2-FDD-LTE08.zip  \"LTE MSRBS-V2 16B-V6\"
\n";

# HELP
if ( @ARGV != 2 ) {
    print "ERROR: $USAGE";
    exit(202);
}
print "\nRUNNING: $0 @ARGV \n";

#
#----------------------------------------------------------------------------------
#Environment variable
#----------------------------------------------------------------------------------
my $simNameTemp = "$ARGV[0]";
my @tempSimName = split( '\.zip', $simNameTemp );
my $simName = $tempSimName[0];
my $neType = "$ARGV[1]";

#--------------------------------------------------------------------------------
# Creating ne type array and map
#--------------------------------------------------------------------------------
my @neTypeArr = split(/:/, $neType);
my %neTypeMap =  map { $_ => 1 } @neTypeArr;

#-----------------------------------------------------------------------------------
#Debugging purpose
#----------------------------------------------------------------------------------
#print Dumper(\@neTypeArr);
#print Dumper(\%neTypeMap);

#--------------------------------------------------------------------------------
# Get neType in simple format. From "LTE MSRBS-V2 16B-V6" to "MSRBS-V2 16B-V6"
#--------------------------------------------------------------------------------
my $neTypeNameFull = $neTypeArr[0];
my @neTypeNameFullPieces = split( / / , $neTypeNameFull );
my $neTypeName = join(' ', @neTypeNameFullPieces[1..2]);
chomp($neTypeName);

#----------------------------------------------------------------------------------
#Define NETSim MO file and Open file in append mode
#----------------------------------------------------------------------------------
my $MML_MML = "MML.mml";
open MML, "+>>$MML_MML";

#----------------------------------------------------------------------------------
#Removes Exisiting security definitions if any
#----------------------------------------------------------------------------------
sub removeSeurity {
    if (-d "/netsim/netsimdir/$simName/security") {
        my @existingSecurityDefinitions = `ls /netsim/netsimdir/$simName/security`;
        foreach (@existingSecurityDefinitions) {
            print MML ".set ssliop no $_ \n";
            print MML ".set save \n";
            print MML ".setssliop delete /netsim/netsimdir/$simName $_ \n";
        }
    }
}

#----------------------------------------------------------------------------------
#Set user as a netsim for SGSN sims
#----------------------------------------------------------------------------------
sub setUser {
    if ($simName=~ m/SGSN/i) {
        print MML ".setuser netsim netsim \n";
        print MML ".set save \n";
    }
}

#----------------------------------------------------------------------------------
#Loads balancing setting
#----------------------------------------------------------------------------------
sub setLoad {
    if ($simName=~ m/DG2/i || $simName=~ m/SGSN/i) {
        print MML ".show serverloadconfig \n";
        foreach $neTypeNameFull (keys %neTypeMap) {
            my @neTypeNameFullPieces = split( / / , $neTypeNameFull );
            my $neTypeName = join(' ', @neTypeNameFullPieces[1..2]);
            chomp($neTypeName);
            print MML ".set nodeserverload $neTypeName 8 \n";

        }
    }
    if ($neTypeName=~ m/ERBS/i){
        print MML ".set nodeserverload $neTypeName 12 \n";
    }
}
#
#---------------------------------------------------------------------------------
#Start the simulation
#---------------------------------------------------------------------------------
print MML ".open $simName\n";
print MML ".select network\n";
&setUser();
&setLoad();
&removeSeurity();
if ($simName !~ m/SGSN-WPP/i && $simName !~ m/M-MGw/i) {
    if($simName=~ m/DG2/i) {
        print MML ".start\n";
    }
    else {
        print MML ".start -parallel\n";
    }
}

#
system("$NETSIM_INSTALL_SHELL < $MML_MML");
if ($? != 0)
{
    print "ERROR: Failed to execute system command ($NETSIM_INSTALL_SHELL < $MML_MML)\n";
    exit(207);
}
close MML;
system("rm $MML_MML");
if ($? != 0)
{
    print "INFO: Failed to execute system command (rm $MML_MML)\n";

}
