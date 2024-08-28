#!/usr/bin/perl
#
# @File test6-percCalc-TMP.pl.pl
# @Author qfatonu
# @Created 18-Nov-2014 12:24:05
#

use strict;
use warnings;
use POSIX();
use Config::Tiny;

my $IPV6_CONFIG_FILE = "ipv6.txt";

#my $SIM = "RNCV43070x1-FT-RBSU230x15-RXIK190x2-RNC01-test";
my $SIM =
"MSC-R13Ax1-BSC-G12Bx2-STN-T13B-SIU02x4-LANS-NWI-E-450Ax4-STN-08A-PICOx4-MSC12";

#my $SIM = "CORE-FT-MSC-BC-APG-AXE-R14B";
#my $SIM = "CORE-FT-MSC-S-APG43L-14B-BCx1";
my $NETSIMDIR         = "/netsim/netsimdir";
my $SIM_INTERNAL_PATH = "/data_files";
my $IPV6_CONFIG_FILE_PATH =
  $NETSIMDIR . "/" . $SIM . $SIM_INTERNAL_PATH . "/" . $IPV6_CONFIG_FILE;

# Create a config
my $Config = Config::Tiny->new;

# Open the config
$Config = Config::Tiny->read($IPV6_CONFIG_FILE_PATH);

# Root name, can be update in future such as wran
my $nw = "_";

my %neTypesIpMultiplier = (
    "TimeServer"       => 0,
    "MSC"              => 3,
    "BSC"              => 3,
    "MSC-S-APG"        => 3,
    "MSC-S-CP"         => 0,
    "MSC-S-TSC"        => 0,
    "MSC-S-SPX"        => 0,
    "MSC-S-APG43L"     => 3,
    "MSC-S-CP-APG43L"  => 0,
    "MSC-S-TSC-APG43L" => 0,
    "MSC-S-SPX-APG43L" => 0
);
print "**************************************\n";
print "NE_TYPES_MULTIPLIER LIST \n";
print map { "$_ => $neTypesIpMultiplier{$_}\n" } keys %neTypesIpMultiplier;
print "**************************************\n";
######################################################

#my @simNesArrTemp = `echo -e \".open $SIM \n .show simnes\" \\
#| /netsim/inst/netsim_pipe`;
my %simNesCountMap = ();
my @simNesArr      = ();
my $count          = 0;
for my $line (@simNesArrTemp) {
    next if ++$count < 5;        # after lineNo=5
    next if $line =~ /^\s*$/;    # no any space
    next if $line =~ /^OK/;      # no line start with OK
                                 #print "line=$line";
    my @columns = split( /\s+/, $line );
    my $NE_TYPE = 2;

    #print "-------$columns[$NE_TYPE]" . "\n";
    push( @simNesArr, $columns[$NE_TYPE] );
    $simNesCountMap{ $columns[$NE_TYPE] }++;
}

my %ipv4Map  = ();
my %ipv6Map  = ();
my %ipv6Perc = ();

my $numOfIpv6Nes = 0;
my $numOfIpv4Nes = 0;

if ( defined $Config ) {
    print "-- ipv6 & ipv4 setup starting.. \n";

    #exit 2;
    foreach my $neType ( keys %simNesCountMap ) {
        print "neType: $neType \n";
        my $perc     = $Config->{$nw}->{$neType};
        my $numOfNes = $simNesCountMap{$neType};
        $ipv6Perc{$neType} = $perc;
        my $resIpv6 = int( $numOfNes * ( $perc / 100 ) + 0.5 );
        if ( $resIpv6 != 0 ) {
            $resIpv6 *= $neTypesIpMultiplier{$neType}
              if exists $neTypesIpMultiplier{$neType};
            $numOfIpv6Nes += $resIpv6;
            $ipv6Map{$neType} = $resIpv6;
        }
        my $resIpv4 = $numOfNes - $resIpv6;
        if ( $resIpv4 != 0 ) {
            $resIpv4 *= $neTypesIpMultiplier{$neType}
              if exists $neTypesIpMultiplier{$neType};
            $numOfIpv4Nes += $resIpv4;
            $ipv4Map{$neType} = $resIpv4;
        }
    }
}
else {
    print "FILE_NAME=$IPV6_CONFIG_FILE_PATH doesn't exist \n";
    print "--ipv4 setup starting..\n";

    # default ipv4
    foreach my $neType ( keys %simNesCountMap ) {
        print "neType: $neType \n";
        my $numOfNes = $simNesCountMap{$neType};
        my $resIpv4  = $numOfNes;
        $resIpv4 *= $neTypesIpMultiplier{$neType}
          if exists $neTypesIpMultiplier{$neType};
        $numOfIpv4Nes += $resIpv4;
        $ipv4Map{$neType} = $resIpv4;
    }
}

print "-------------------------------\n";
print "numOfIpv6Nes= $numOfIpv6Nes \n";
print "numOfIpv4Nes= $numOfIpv4Nes \n";
print "-------------------------------\n";

exit;

#for my $neName (@simNeNamesArr){
#    print "neName:$neName \n";
#}
#exit;
