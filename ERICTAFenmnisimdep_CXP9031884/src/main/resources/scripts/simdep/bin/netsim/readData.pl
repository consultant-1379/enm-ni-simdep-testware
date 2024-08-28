#!/usr/bin/perl -w
#use strict;
#use warnings;
####################################################################################
##
##     File Name : readSimData.pl
##
##     Version : 2.00
##
##     Author : Jigar Sha
##
##     Description : Reads the following data from the simuation, nodeName, NeType.
##
##     Date Created : 29 October 2013
##
##     Syntax : ./readSimData.pl <simName>
##
##     Parameters : <simName> The name of the simulation whos data needs to be read
##
##     Example :  ./openSimulation CORE-K-FT-M-MGwB15215-FP2x1-vApp.zip
##
##     Dependencies : 1.
##
##     NOTE:
##
##     Return Values :   1 -> Not a netsim user
##           2 -> Usage is incorrect
##           dumpNeType.txt -> file with all details about the NEs.
##
####################################################################################
##
#----------------------------------------------------------------------------------
##Variables
my $NETSIM_INSTALL_SHELL = "/netsim/inst/netsim_pipe";
#
##
##----------------------------------------------------------------------------------
##Check if the scrip is executed as netsim user
##----------------------------------------------------------------------------------
##
my $user = `whoami`;
chomp($user);
my $netsim = 'netsim';
if ( $user ne $netsim ) {
    print "ERROR: Not netsim user. Please execute the script as netsim user\n";
    exit(201);
}
#
##----------------------------------------------------------------------------------
##Check if the script usage is right
##----------------------------------------------------------------------------------
my $USAGE =
  "Usage: $0 <simName> \n  E.g. $0 CORE-K-FT-M-MGwB15215-FP2x1-vApp.zip\n";

# HELP
if ( @ARGV != 1 ) {
    print "ERROR: $USAGE";
    exit(202);
}
print "INFO: RUNNING: $0 @ARGV \n";
#
##----------------------------------------------------------------------------------
##Env variable
##----------------------------------------------------------------------------------
my $simNameTemp = "$ARGV[0]";
my @tempSimName = split( '\.zip', $simNameTemp );
my $simName     = $tempSimName[0];
my $hostName = `hostname`;
chomp($hostName);
my $PWD = `pwd`;
chomp($PWD);

#----------------------------------------------------------------------------------
##Define NETSim MO file and Open file in append mode
##----------------------------------------------------------------------------------
my $MML_MML = "MML.mml";
open MML, "+>> $MML_MML";
#
##----------------------------------------------------------------------------------
##Open the Simulation and read data into an array.
##----------------------------------------------------------------------------------
print MML ".open $simName\n";
print MML ".selectnocallback network\n";
print MML ".show simnes\n";
my @simNesArrTemp = `$NETSIM_INSTALL_SHELL < $MML_MML`;
close MML;
#
##
##----------------------------------------------------------------------------------
##Extract the Node name and the NE Type
##----------------------------------------------------------------------------------
print "INFO: Read data(simnes) is @simNesArrTemp\n";

my @simNeTypeFullArr = ();
my @simNeNameArr     = ();
my $count             = 0;
my @tab = ();
for my $line (@simNesArrTemp) {
    next if ++$count < 7;        # after lineNo=7, just after NeName,Type line
    next if $line =~ /^\s*$/;    # no any space
    next if $line =~ /^OK/;      # no line start with OK

    if (index($line, $hostName) != -1)
    {
            @tab = split($hostName, $line);
    }
    else
    {
            @tab = split(/\?/, $line);
    }
    $line = $tab[0];
    $line =~ /^(.+?)\s+(.+?)$/;
    my $neName     = $1;
    my $neTypeFull = $2;
    print "neName = $neName, ";
    print "neTypeFull = $neTypeFull \n";

    push( @simNeNameArr, "$neName\n" );
    push( @simNeTypeFullArr, "$neTypeFull\n" );
}
open dumpNeName, ">/var/simnet/softwareUpdate/$simName/dat/dumpNeName.txt";
open dumpNeType, ">/var/simnet/softwareUpdate/$simName/dat/dumpNeType.txt";
open listNeName, ">/var/simnet/softwareUpdate/$simName/dat/listNeName.txt";
open listNeType, ">/var/simnet/softwareUpdate/$simName/dat/listNeType.txt";
print dumpNeName @simNeNameArr;
print dumpNeType @simNeTypeFullArr;
print listNeName @simNeNameArr;
print listNeType $simNeTypeFullArr[0];
close dumpNeName;
close dumpNeType;
close listNeName;
close listNeType;
