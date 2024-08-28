#!/usr/bin/perl -w
###################################################################################
#
#     File Name : FilterSims.pl
#
#     Version : 5.00
#
#     Author :  Kiran Yakkala 
#
#     Description : The script Filters the simulations with higest version 
#
#     Date Created : 30 December 2014
#
#     Syntax : ./filetrSims.pl <Path to file>
#
#     Parameters : <PathToFile> Filename with path where all the simulation
#	                        Names are specified to filter 
#
#     Example :  ./filetrSims.p /tmp/dat/allsims.txt
#
#     Dependencies : 1.
#
#     Return Values : Creates a file with simulation names having higest version
#
###################################################################################
use strict; 
use warnings;
use File::Basename;

my  @simNamesWithNoVersion=();
my  @simVersions =();
my  $inc = 0;
my  @uniqueSimNames=();

my  $PWD =  `pwd`;
chomp($PWD);
print "$PWD ********";

#---------------------------------------------------------------------------------
# Function call to get list of unique elements
#---------------------------------------------------------------------------------
sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}

#--------------------------------------------------------------------------------
# Reads downloaded simulation names from file and create list of
# simnames with out version and another array with only versions details
#--------------------------------------------------------------------------------
open simsNames, "<$PWD/../dat/latestSims.txt";
my @sims = <simsNames>;
close(simsNames);
for my $line (@sims) {
    my $lastIndexOfZip = rindex($line,".zip");
    $simNamesWithNoVersion[$inc] = substr($line,0,($lastIndexOfZip-1)); 
    $simVersions[$inc] = substr($line, ($lastIndexOfZip-1),1);
    $inc++;
}
#-------------------------------------------------------------------------------
# Filters unique simulation name with higiest version 
#-------------------------------------------------------------------------------
for my $i (0 .. $#simNamesWithNoVersion) {
    my $tmpVersion = $simVersions[$i];
        for my $j (0 .. $#simNamesWithNoVersion){
            if($simNamesWithNoVersion[$i] eq $simNamesWithNoVersion[$j]) {
	        if($simVersions[$i] < $simVersions[$j]){
	        $tmpVersion = $simVersions[$j];	
	        }
            } 
         }
    $uniqueSimNames[$i] = "$simNamesWithNoVersion[$i]$tmpVersion.zip\n";
}

my @filtered = uniq(@uniqueSimNames);
open dumpSimNameList, ">$PWD/../dat/listSimulation.txt";
print dumpSimNameList @filtered;
close dumpSimNameList;
print "@filtered\n";
