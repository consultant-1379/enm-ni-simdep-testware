#!/usr/bin/perl
# script 1
use Storable;
my %eTAG,$i;

$eTAG{'Truck'}{'Fuel'}="Gas"; $eTAG{'Truck'}{'mpg'}=15;
$eTAG{'SUV'}{'Fuel'}="Gas"; $eTAG{'SUV'}{'mpg'}=21;
#for illustration only
foreach $i (keys %eTAG){ print "$i\n"; }

store \%eTAG, 'fileHash.dat';

exit 0;
