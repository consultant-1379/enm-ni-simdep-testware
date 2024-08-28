#!/usr/bin/perl -w

use strict;
use warnings;
use POSIX();
use Config::Tiny;

# Create a config
my $Config = Config::Tiny->new;

my $IPV6_CONFIG_FILE = "ipv6.txt";
my $SIM = "RNCV43070x1-FT-RBSU230x15-RXIK190x2-RNC01-test";
my $NETSIMDIR = "/netsim/netsimdir";
my $SIM_INTERNAL_PATH = "/data_files";
my $IPV6_CONFIG_FILE_PATH = $NETSIMDIR . "/" .$SIM . 
	$SIM_INTERNAL_PATH . "/" . $IPV6_CONFIG_FILE;

# Open the config
$Config = Config::Tiny->read($IPV6_CONFIG_FILE_PATH);

my @simNesArrTemp = `echo -e \".open $SIM \n .show simnes\" \\
| /netsim/inst/netsim_pipe`;
my %wran = ();
my @simNesArr = ();
my $count = 0;
for my $line (@simNesArrTemp){
	next if ++$count < 5; # after lineNo=5
	next if $line =~ /^\s*$/; # no any space
	next if $line =~ /^OK/; # no line start with OK
	#print "line=$line";
 	my @columns = split(/\s+/, $line);	
	my $NE_TYPE = 2;
	print "-------$columns[$NE_TYPE]" . "\n";
	push(@simNesArr, $columns[$NE_TYPE]);
	#$wran{'rnc'}++ if $columns[$NE_TYPE] =~ /rnc/i;
	#$wran{'rbs'}++ if $columns[$NE_TYPE] =~ /rbs/i;
	#$wran{'rxi'}++ if $columns[$NE_TYPE] =~ /rxi/i;
	$wran{$columns[$NE_TYPE]}++;
}

for my $key ( keys %wran ) {
	my $value = $wran{$key};
	print "$key => $value\n";
}

my %ipv4Map = ();
my %ipv6Map = ();

my %ipv4Map_ = ();
my %ipv6Map_ = ();

my %ipv6Perc = ();

my $nw = "wran";

if (defined $Config){
	foreach my $neType (keys %wran){
		print "neType: $neType \n";
		my $perc = $Config->{$nw}->{$neType};
		my $numOfNodes = $wran{$neType};
		$ipv6Perc{$neType} = $perc; 
		my $resIpv6 = int ( $numOfNodes * ( $perc / 100 ) + 0.5 );	
		$ipv6Map_{$neType} = $resIpv6 if $resIpv6 != 0;
	 	my $resIpv4 = $numOfNodes - $resIpv6;	
		$ipv4Map_{$neType} = $resIpv4 if $resIpv4 != 0;
	}
}

#while((my $neType, my $perc) = each %ipv6Perc){
#	print "config-- $neType=$perc \n";
#}

#exit;

	my $rncTotal = $wran{'RNC'};
	my $rbsTotal = $wran{'RBS'};
	my $rxiTotal = $wran{'RXI'};

	my $rncIpv6Num;
	my $rxiIpv6Num;
	my $rbsIpv6Num;

	my $rncIpv4Num;
	my $rxiIpv4Num;
	my $rbsIpv4Num;

	my $rncIpv6Perc = $Config->{wran}->{RNC};
	my $rbsIpv6Perc = $Config->{wran}->{RBS};
	my $rxiIpv6Perc = $Config->{wran}->{RXI};
if (defined $Config) {
	print "rncIpv6Perc=$rncIpv6Perc" . "\n";
	print "rbsIpv6Perc=$rbsIpv6Perc" . "\n";
	print "rxiIpv6Perc=$rxiIpv6Perc" . "\n";
	print "----------------" . "\n";
	$rncIpv6Num = int ( $rncTotal * ( $rncIpv6Perc / 100 ) + 0.5 );	
	$rbsIpv6Num = int ( $rbsTotal * ( $rbsIpv6Perc / 100 ) + 0.5 );	
	$rxiIpv6Num = int ( $rxiTotal * ( $rxiIpv6Perc / 100 ) + 0.5 );	
	print "rncIpv6Num=$rncIpv6Num" . "\n";
	print "rbsIpv6Num=$rbsIpv6Num" . "\n";
	print "rxiIpv6Num=$rxiIpv6Num" . "\n";
	$ipv6Map{"rnc"} = $rncIpv6Num if $rncIpv6Num != 0;
	$ipv6Map{"rbs"} = $rbsIpv6Num if $rbsIpv6Num != 0;
	$ipv6Map{"rxi"} = $rxiIpv6Num if $rxiIpv6Num != 0;

	print "----------------" . "\n";
	$rncIpv4Num = $rncTotal - $rncIpv6Num;
	$rbsIpv4Num = $rbsTotal - $rbsIpv6Num;
	$rxiIpv4Num = $rxiTotal - $rxiIpv6Num;
	print "rncIpv4Num=$rncIpv4Num" . "\n";
	print "rbsIpv4Num=$rbsIpv4Num" . "\n";
	print "rxiIpv4Num=$rxiIpv4Num" . "\n";
	$ipv4Map{"rnc"} = $rncIpv4Num if $rncIpv4Num != 0;
	$ipv4Map{"rbs"} = $rbsIpv4Num if $rbsIpv4Num != 0;
	$ipv4Map{"rxi"} = $rxiIpv4Num if $rxiIpv4Num != 0;
}

my @freeIpv4 = (1..1);

for(@freeIpv4) {
	print "$_ ";
}
print "\n";


sub getFreeIp2(){
	#my @freeIpv4  = @_;
	#my $firstIp = shift(@freeIpv4);
	#my $firstIp = shift(@_);
	#my $firstIp = shift(@freeIpv4);
	#my $item = 9;
 	#$item = shift(@freeIpv4) if @freeIpv4 > 0;
	#print "\@freeIpv4 = " . @freeIpv4 . "\n";
	#if ( @freeIpv4 > 0 ){
	#	 $item = shift(@freeIpv4);
	#} else {
	#	$item = 100;
	#}
	my $firstIp = shift(@freeIpv4) if @freeIpv4 > 0;
}

sub getFreeIp(){
	#my $arr = @_;
	#shift(@{$arr}) if @{$arr} > 0;
	#my $arr = @_;
	#print "\$arr:". @{$arr} . "\n";
	#print "\@arr:". @arr . "\n";
	#print "\@arr: @arr  \n";
	#print "\@{\$arr}:". $arr . "\n";
	#print "\@_: @_" . "\n";
	#my $ref = shift;
	#my ($ref) = @_;
	#print "\$ref_: @{$ref}" . "\n";
	my ($ref) = @_;
	shift(@{$ref}) if @{$ref}> 0;
}

sub getFreeIpGenOld1(){
	my ( $neType, $refFreeIpv4, $refFreeIpv6 ) = @_;
	print "ipv4:$_ " foreach (@{$refFreeIpv4});
	print "\n" if ( @{$refFreeIpv4} );
	print "ipv6:$_ " foreach (@{$refFreeIpv6});
	print "\n";
	#return;
	if ( exists $ipv4Map{lc $neType} ){
		print "ipv4-neType=$neType exist, ipv4Map{lc neType}=" . $ipv4Map{lc $neType} . "\n";
		if ( --$ipv4Map{lc $neType} == 0 ) {
			delete $ipv4Map{lc $neType}; 
			print "neType=$neType is deleted from ipv4Map \n";
		}
		return shift(@{$refFreeIpv4});	
	}
	if ( exists $ipv6Map{lc $neType} ){
		print "ipv6-neType=$neType exist, ipv6Map{lc neType}=" . $ipv6Map{lc $neType} . "\n";
		if ( --$ipv6Map{lc $neType} == 0 ) {
			delete $ipv6Map{lc $neType}; 
			print "neType=$neType is deleted from ipv6Map \n";
		} 
		return shift(@{$refFreeIpv6});	
	}
}
sub getFreeIpGen(){
	my ( $neType, $refFreeIpv4, $refFreeIpv6 ) = @_;
	print "ipv4:$_ " foreach (@{$refFreeIpv4});
	print "\n" if ( @{$refFreeIpv4} );
	print "ipv6:$_ " foreach (@{$refFreeIpv6});
	print "\n";
	#return;
	if ( exists $ipv4Map_{$neType} ){
		print "ipv4-neType=$neType exist, ipv4Map{neType}=" . $ipv4Map_{$neType} . "\n";
		if ( --$ipv4Map_{$neType} == 0 ) {
			delete $ipv4Map_{$neType}; 
			print "neType=$neType is deleted from ipv4Map \n";
		}
		return shift(@{$refFreeIpv4});	
	}
	if ( exists $ipv6Map_{$neType} ){
		print "ipv6-neType=$neType exist, ipv6Map{lc neType}=" . $ipv6Map_{$neType} . "\n";
		if ( --$ipv6Map_{$neType} == 0 ) {
			delete $ipv6Map_{$neType}; 
			print "neType=$neType is deleted from ipv6Map \n";
		} 
		return shift(@{$refFreeIpv6});	
	}
}

my @freeIpv4_ = (1..9);
my @freeIpv6 = (21..29);
my @finalIpList = ();

my ($k,$v);
print "==ipv4Map== \n";
#print "key=$k, val=$v \n" while (($k,$v) = each %ipv4Map);
print "key=$k, val=$v \n" while (($k,$v) = each %ipv4Map_);
print "==ipv6Map== \n";
#print "key=$k, val=$v \n" while (($k, $v) = each %ipv6Map);
print "key=$k, val=$v \n" while (($k, $v) = each %ipv6Map_);

for my $node (@simNesArr) {
	print ">> node=$node \n";
	my ($ip) = &getFreeIpGen($node, \@freeIpv4_, \@freeIpv6);
	push( @finalIpList, $ip );
}	

print "==ipv4Map== \n";
#print "key=$k, val=$v \n" while (($k,$v) = each %ipv4Map);
print "key=$k, val=$v \n" while (($k,$v) = each %ipv4Map_);
print "==ipv6Map== \n";
#print "key=$k, val=$v \n" while (($k, $v) = each %ipv6Map);
print "key=$k, val=$v \n" while (($k, $v) = each %ipv6Map_);

foreach(@finalIpList){
	print "final=$_ \n";
}


exit;

#print "firstIp=" . &getFreeIp(@freeIpv4) . "\n";
#print "secondIp=" . &getFreeIp(@) . "\n";
my $ip = &getFreeIp(\@freeIpv4);
print "firstIp=" . $ip . "\n";
$ip = &getFreeIp(\@freeIpv4);
#$ip = &getFreeIp();
print "secondIp=" . $ip . "\n" if $ip ne "";

for(@freeIpv4){
	print "$_ ";
}
print "\n";
#print "\n";

my $count2 = 0;
for my $node (@simNesArr) {
	#print "node=$node" . "\n";
	if ($node =~ /rnc/i) {
		if ( $rncIpv6Num > 0 ) {
			print ++$count2 . " -- rnc => getFreeIpv6" . "\n";
			$rncIpv6Num--;
			$count2 = 0 if $rncIpv6Num == 0;
		}else {
			print "rnc => getFreeIpv4" . "\n";
		}
	}
	elsif ($node =~ /rbs/i) {
		if ( $rbsIpv6Num > 0 ) {
			print ++$count2 . " -- rbs => getFreeIpv6" . "\n";
			$rbsIpv6Num--;
			$count2 = 0 if $rbsIpv6Num == 0;
		}else {
			print "rbs => getFreeIpv4" . "\n";
		}
	}
	elsif ($node =~ /rxi/i) {
		if ( $rxiIpv6Num > 0 ) {
			print ++$count2 . " -- rxi => getFreeIpv6" . "\n";
			$rxiIpv6Num--;
			#$count2 = 0 if $rxiIpv6Num == 0;
		}else {
			print "rxi => getFreeIpv4" . "\n";
		}
	}
}

for my $key ( keys %wran ) {
	my $value = $wran{$key};
	print "$key => $value\n";
}

my @list = (1,"Test", 0, "foo", 20 );

my @has_digit = grep ( /\d/, @list );

print "@has_digit\n";

=head
/////////////////////////////
        if ( exists $ipv6Map{lc $neType} ){
                if ( $ipv6Map{lc $neType} == 0 ) {
                        delete $ipv6Map{lc $neType};
                        print "1-neType=$neType is deleted from ipv6Map \n";
                } else {
                        print "ipv6-neType=$neType exist, ipv6Map{lc neType}=" . $ipv6Map{lc $neType} . "\n";
                }
                if ( --$ipv6Map{lc $neType} == 0 ) {
                        delete $ipv6Map{lc $neType};
                        print "neType=$neType is deleted from ipv6Map \n";
                } else {
                        print "ipv6-neType=$neType exist \n";
                }
\\\\\\\\\\\\\\\\\\\\\

#my @arr = `echo -e ".open MSC-R14_1x1-BSC-G13Bx2-STN-T14B-SIU02x4-LANS-R1x4-STN-09A-PICOx4-MSC05 | /netsim/inst/netsim_pipe"`;
#my $line = `echo -e \".open MSC-R14_1x1-BSC-G13Bx2-STN-T14B-SIU02x4-LANS-R1x4-STN-09A-PICOx4-MSC05 \n .show simnes\" \\
$simName="MSC-R14_1x1-BSC-G13Bx2-STN-T14B-SIU02x4-LANS-R1x4-STN-09A-PICOx4-MSC05";
$simName="MSC-R14_1x1-BSC-G13Bx2-STN-T14B-SIU02x4-LANS-R1x4-STN-09A-PICOx4-MSC05";
my @arr = `echo -e \".open $simName \n .show simnes\" \\
| /netsim/inst/netsim_pipe \\
| awk 'NR > 4 && NF { print }' \\
| awk -F\" \" '{ for (x=3; x<=3; x++) printf(\"%s \", \$x);printf(\"\\n\"); }'`;

# http://stackoverflow.com/questions/6361312/negative-regex-for-perl-string-pattern-match
for my $line(@arr){
	# way 1
	#print "line=$line" if ($line =~ /^(?!^\s*$)/i);
	# way 2
	print "line=$line" if ($line !~ /^\s*$/i);
}
print "----------------" . "\n";
=cut

=head
my @arr2 = `echo -e \".open $simName \n .show simnes\" \\
| /netsim/inst/netsim_pipe`;
my @arr3 = ();
my %wran = ();
#print "@arr2";
my $count = 0;
for my $line (@arr2){
	#print "$_" . "\n";
	#print "$_";
	next if ++$count < 5; # after lineNo=5
	next if $line =~ /^\s*$/; # no any space
	next if $line =~ /^OK/; # no line start with OK
	print "line=$line";
 	my @columns = split(/\s+/, $line);	
	print "-------$columns[2]" . "\n";
	push(@arr3, $columns[2]);	
	$wran{'rnc'}++ if $columns[2] =~ /rnc/i;
	$wran{'rbs'}++ if $columns[2] =~ /rbs/i;
	$wran{'rxi'}++ if $columns[2] =~ /rxi/i;
}

print "----------------" . "\n";

for my $item (@arr3){
	print "$item" . "\n";
}

print "----------------" . "\n";

for my $key ( keys %wran ) {
	my $value = $wran{$key};
	print "$key => $value\n";
}

print "man-rnc= $wran{'rnc'}" . "\n";



#| /netsim/inst/netsim_shell | awk 'NR > 3 { print }' | awk -F" " '{ for (x=3; x<=3; x++) printf("%s ", $x);printf("\n"); }'`;

=cut


# overwrites the comments: not good if you have comments
#$Config->{wran}->{rncTotal} = $rncTotal ;
#$Config->write( $IPV6_CONFIG_FILE_PATH );

=head

my $numTotal = 4;
my $percent = 0.40;
my $numOfIpv4;
my $numOfIpv6;

$numOfIpv4 = $numTotal * $percent;
$numOfIpv6 = $numTotal - $numOfIpv4;

print "numOfIpv4=$numOfIpv4 \n";
print "numOfIpv6=$numOfIpv6 \n";

$numOfIpv4 = int($numTotal * $percent + 0.5);
$numOfIpv6 = $numTotal - $numOfIpv4;

print "numOfIpv4=$numOfIpv4 \n";
print "numOfIpv6=$numOfIpv6 \n";

my $plus = 0.5;
my $num = 0.3;
print "num=$num \n";
print "num=" . int($num + $plus) . "\n";
$num = 0.6;
print "num=$num \n";
print "num=" . int($num + $plus) . "\n";
$num = 0.9;
print "num=$num \n";
print "num=" . int($num + $plus) . "\n";
$num = 1.1;
print "num=$num \n";
print "num=" . int($num + $plus) . "\n";
$num = 1.5;
print "num=$num \n";
print "num=" . int($num + $plus) . "\n";


my $x = 0.4;
print "x=$x \n";
print "x=" . POSIX::floor($x) ." \n";
print "x=" . POSIX::ceil($x) ." \n";

x="RNC-IPV6=100%";
y="RBS-IPV6=50%";
z="RXI-IPV6=10%";

=cut

=head 

my $IPV6_CONFIG_FILEName = "ipv6.txt";
my $simName = "RNCV43070x1-FT-RBSU230x15-RXIK190x2-RNC01-test";
my $NETSIMDIR = "/netsim/NETSIMDIR";
my $SIM_INTERNAL_PATH = "/data_files";
my $IPV6_CONFIG_FILE_PATH = $NETSIMDIR . "/" .$simName . 
	$SIM_INTERNAL_PATH . "/" . $IPV6_CONFIG_FILEName;

if (-e $IPV6_CONFIG_FILE_PATH){
	print "ipv6FilePath=$IPV6_CONFIG_FILE_PATH exist \n";
} else {
	print "ipv6FilePath=$IPV6_CONFIG_FILE_PATH  DOES NOT exist \n";
}

my @ipv6Config = ();
if ( open( IPV6_CONFIG_FILE_FH, '<', $IPV6_CONFIG_FILE_PATH ) ) {
	@ipv6Config = <IPV6_CONFIG_FILE_FH>;
	print "@ipv6Config";
	close IPV6_CONFIG_FILE_FH;
	print "read successfull \n";
} else {
	print "read UNsuccessfull \n";
}
print "\@ipv6Config size = " . scalar(@ipv6Config) . "\n";
my $size = @ipv6Config;
print "\@ipv6Config size = $size\n";

for ( my $i=0; $i<scalar(@ipv6Config); $i++ ) {
	print "ipv6Config[$i]=$ipv6Config[$i]";
}

print "------------------- \n";
#my $input_file = $IPV6_CONFIG_FILE_PATH . "s";
my $input_file = $IPV6_CONFIG_FILE_PATH;
open( my $input_fh, "<", $input_file ) || die "Can't open $input_file: $!";
#if (open( my $input_fh, "<", $input_file ) )
#{
# way 1
#my @lines = <$input_fh>;
#for my $line (@lines){
#	print "$line";
#}

# way 2
my @lines = ();
while (<$input_fh>){
	chomp();
	if ($_ =~ /^#/ 
		|| /^\s*$/ ){
		next;
	}
	push(@lines, $_);	
}

my $rnc;
my $rbs;
my $rxi;

for my $line (@lines){
	print "$line \n";
	#if ($line =~ /RNC/){
		
}
print "another way to print \n";
for ( my $i=0; $i<@lines; $i++ ) {
	print "\$lines[$i]=$lines[$i] \n";
}

#} else {
#	print "UNABLE to open the file \n";
#}

=cut




