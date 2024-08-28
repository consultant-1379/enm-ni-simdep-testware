#!/usr/bin/perl

%ttys = ();

open(WHO, "who|")                   or die "can't open who: $!";
while (<WHO>) {
    ($user, $tty) = split;
    push( @{$ttys{$user}}, $tty );
}

foreach $user (sort keys %ttys) {
    #print "$user: @{$ttys{$user}}\n";
}

$string = "simulation.zip";
$sim = substr($string, 0, length($string) - 4);
#print "$sim\n";
$sim = substr($string, 0, index($string, '.'));
#print "$sim\n";

my %hash = ();
#my %hash = undef;
#my %hash; 
my $hashRef = \%hash;
print "defined-ref \n" if defined $hashRef;
print "defined-hash \n" if defined %hashRef;
print "emptyHash \n" if not %hash ;
print "\%hash = |" . %hash . "| \n";

print map { "$_ => $$hashRef{$_}\n" } keys %$hashRef;
my $size = keys %$hashRef;
print "hashRef size = $size \n";
#print map { "$_ => $hash{$_}\n" } keys %$hash;

