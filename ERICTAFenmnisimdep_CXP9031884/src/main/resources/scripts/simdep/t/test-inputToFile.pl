#!/usr/bin/perl -w
print "Hello. Now testing on writing multiple lines into a file\n";
open( FH, "+>jig.txt" );
print FH <<"END";
jigar
shah
simNetDeployer
END
close FH;
