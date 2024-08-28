#!/usr/bin/perl -w

use strict;
use warnings;

print "..starting to $0\n";

# In your program
use Config::Tiny;

# Create a config
my $Config = Config::Tiny->new;

# Open the config
$Config = Config::Tiny->read('file.conf');

my $rootproperty = $Config->{_}->{rootproperty};
my $one          = $Config->{section}->{one};
my $Foo          = $Config->{section}->{Foo};

print "rootproperty = $rootproperty\n";
print "one = $one \n";
print "Foo = $Foo \n";

print "..ending to $0\n";
