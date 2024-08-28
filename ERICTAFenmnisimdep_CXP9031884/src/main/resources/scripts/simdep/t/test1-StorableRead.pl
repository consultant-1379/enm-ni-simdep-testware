#!/usr/bin/perl
# Script #2
use Storable;
my $i, $href = retrieve('fileHash.dat',{binmode=>':raw'});

my %eTAG = %$href;  #This was the key to getting it working.

foreach $i (keys %eTAG) { print "$i\n"; }
exit 0;
