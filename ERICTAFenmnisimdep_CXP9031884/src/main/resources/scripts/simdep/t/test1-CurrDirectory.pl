#!/usr/bin/perl -w

use strict;
use warnings;

=head
use File::Basename;
my $dirname = dirname(__FILE__);
print "dirname = $dirname \n";
=cut

# the best option is below
#
#use File::Spec;
use Cwd 'abs_path';
print "abs_path=" . abs_path($0) . "\n";

#my $dirName = `$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )`;
#print "dirName = $dirName \n";

#my ($volume, $directory, $file) = File::Spec->splitpath(__FILE__);
#my ($volume, $directory, $file) = File::Spec->splitpath($0);
#print "directory = $directory \n";

=head
# relative path gives an error
#
use Cwd        ();
use FindBin    ();
use File::Spec ();

my $full_path = File::Spec->catfile( $FindBin::Bin, $FindBin::Script );
my $executed_from_path = Cwd::getcwd();

print <<OUTPUT;
Full path to script: $full_path
Executed from path:  $executed_from_path
OUTPUT

=cut

