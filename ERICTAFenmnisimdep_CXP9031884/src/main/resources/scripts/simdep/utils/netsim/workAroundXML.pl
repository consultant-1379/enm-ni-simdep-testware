#!/usr/bin/perl -w
use warnings;
use strict;
use Storable;
# Created by  : Fatih ONUR
# Created in  : 2014.12.15
##
### VERSION HISTORY
# Ver         : Follow up from gerrit
# Purpose     : Created for processing arne xmls
# Description :
# Date        : 27 JAN 2012
# Who         : Fatih ONUR
#
#----------------------------------------------------------------------------------
#Check if the scrip is executed as netsim user
#----------------------------------------------------------------------------------
#
my $user = `whoami`;
chomp($user);
my $netsim = 'netsim';
#if ( $user ne $netsim ) {
#    print "Error: Not netsim user. Please execute the script as netsim user\n";
#    exit(201);
#}

#
#----------------------------------------------------------------------------------
#Check if the script usage is right
#----------------------------------------------------------------------------------
my $USAGE = "Usage: $0 <simName> \nE.g. $0 LTED142x10-FT-TDD-LTE06.zip\n";

# HELP
if ( @ARGV != 1 ) {
    print "ERROR: --Need Help?--\n$USAGE";
    exit(202);
}
print "RUNNING: $0 @ARGV \n";

#
#----------------------------------------------------------------------------------
#Env variable
#----------------------------------------------------------------------------------
my $PWD     = `pwd`;
chomp($PWD);

my $simNameTemp = "$ARGV[0]";
my @tempSimName = split( '\.zip', $simNameTemp );
my $simName = $tempSimName[0];

my %granFtpServicesMapIpv4= (
    "kloker"           => "nedssv4",
    "aistore-kloker"   => "aifgran"
);
my %granFtpServicesMapIpv6= (
    "kloker"           => "nedssv6",
    "aistore-kloker"   => "aifgranIP6"
);
my %coreFtpServicesMapIpv4= (
    "SMRSSLAVE-kloker" => "SMRSSLAVE-CORE-nedssv4",
    "keystore-kloker"  => "c-key-nedssv4",
    "swstore-kloker"   => "c-swstore-nedssv4",
    "backup-kloker"    => "c-back-nedssv4",
    "aistore-kloker"   => "aifcore"
);
my %coreFtpServicesMapIpv6= (
    "SMRSSLAVE-kloker" => "SMRSSLAVE-CORE-nedssv6",
    "keystore-kloker"  => "c-key-nedssv6",
    "swstore-kloker"   => "c-swstore-nedssv6",
    "backup-kloker"    => "c-back-nedssv6",
    "aistore-kloker"   => "aifcoreIP6"
);
my %lteFtpServicesMapIpv4= (
    "SMRSSLAVE-kloker" => "SMRSSLAVE-LRAN-nedssv4",
    "keystore-kloker"  => "l-key-nedssv4",
    "swstore-kloker"   => "l-sws-nedssv4",
    "backup-kloker"    => "l-back-nedssv4",
    "aistore-kloker"   => "aiflran"
);
my %lteFtpServicesMapIpv6= (
    "SMRSSLAVE-kloker" => "SMRSSLAVE-LRAN-nedssv6",
    "keystore-kloker"  => "l-key-nedssv6",
    "swstore-kloker"   => "l-sws-nedssv6",
    "backup-kloker"    => "l-back-nedssv6",
    "aistore-kloker"   => "aiflranIP6"
);
my %wranFtpServicesMapIpv4= (
    "SMRSSLAVE-kloker" => "SMRSSLAVE-WRAN-nedssv4",
    "keystore-kloker"  => "w-key-nedssv4",
    "swstore-kloker"   => "w-sws-nedssv4",
    "backup-kloker"    => "w-back-nedssv4",
    "aistore-kloker"   => "aifwran"
);
my %wranFtpServicesMapIpv6= (
    "SMRSSLAVE-kloker" => "SMRSSLAVE-WRAN-nedssv6",
    "keystore-kloker"  => "w-key-nedssv6",
    "swstore-kloker"   => "w-sws-nedssv6",
    "backup-kloker"    => "w-back-nedssv6",
    "aistore-kloker"   => "aifwranIP6"
);

my %ftpServices = (
    "wran-ipv4" => \%wranFtpServicesMapIpv4,
    "wran-ipv6" => \%wranFtpServicesMapIpv6,
    "lte-ipv4" => \%lteFtpServicesMapIpv4,
    "lte-ipv6" => \%lteFtpServicesMapIpv6,
    "gran-ipv4" => \%granFtpServicesMapIpv4,
    "gran-ipv6" => \%granFtpServicesMapIpv6,
    "core-ipv4" => \%coreFtpServicesMapIpv4,
    "core-ipv6" => \%coreFtpServicesMapIpv6
);


#
#----------------------------------------------------------------------------------
#Subroutine to return network code
#----------------------------------------------------------------------------------
sub getNwType{
    my $simName = $_[0];
    my $nw = "";
    if ( "$simName" =~ m/LTE/i ) {
        $nw= 'lte';
    }
    elsif ( "$simName" =~ m/RNC/i ) {
        $nw= 'wran';
    }
    elsif ("$simName" =~ m/GRAN/i
        || "$simName" =~ m/STN/i
        || "$simName" =~ m/MSC/i
        || "$simName" =~ m/BSC/i
        || "$simName" =~ m/TCU/i )
    {
        $nw= 'gran';
    }
    elsif ( "$simName" =~ m/CORE/i ) {
        $nw= 'core';
        &workAround($simName);
    }
    else {
        print("ERROR: Unknown simulations. Please contact Fatih ONUR\n");
        $nw = undef;
    }
    return $nw
}

#
#----------------------------------------------------------------------------------
#Subroutine to manage special SGSN sims
#----------------------------------------------------------------------------------
sub workAround {
    my $simName = $_[0];
    my $fileName = "/netsim/netsimdir/$simName/conf/change_SGSN_tssuser_xml";
    if ( -e $fileName ) {
        print
"INFO: Applying ARNE XML workaround executing /netsim/netsimdir/$simName/conf/change_SGSN_tssuser_xml script \n";
        print "PWD=$PWD" . "\n";
`cp -v /netsim/netsimdir/exported_items/${simName}_create.xml /netsim/netsimdir/$simName/conf/`;
        system(
"cd /netsim/netsimdir/$simName/conf/; perl /netsim/netsimdir/$simName/conf/change_SGSN_tssuser_xml"
        );
        if ($? != 0)
        {
             print "ERROR: Failed to execute system command (cd /netsim/netsimdir/$simName/conf/; perl /netsim/netsimdir/$simName/conf/change_SGSN_tssuser_xml)\n";
             exit(207);
        }

    }
}

#
#----------------------------------------------------------------------------------
#Subroutine to manage special SGSN sims
#----------------------------------------------------------------------------------
sub getManageElmMap {
    my ($simXmlArrRef) = $_[0];

    my %manageElmMap = ();
    my @manageElmArr = ();
    my $neName = "empty";

    my $flag = 0;
    my $index = 0;
    my $offset = 0;

    #print "------------------------\n";
    foreach(@$simXmlArrRef){
        # print "$_";
        if ( /<ManagedElement sourceType=/ ){
            $flag = 1;
            $offset = $index;
            #print "offset=$offset\n";
		
        }
        if ( $flag == 1 ){
            push(@manageElmArr, $_);
            $neName = $1 if /ManagedElementId string="(.*?)"/;
        } 
        if ( /<\/ManagedElement>/ ){
            if ( $flag > 0 ){
                #print "neName = $neName \n";
                #print "------------------------\n";
                my @arr = (@manageElmArr, $offset);
                # pass arr as a ref within []
                $manageElmMap{$neName} = [@arr]; 
                @manageElmArr = ();
            }
            --$flag;
        }
	    $index++;
    }
    return %manageElmMap;
}

#
#----------------------------------------------------------------------------------
#MAIN
#----------------------------------------------------------------------------------

# Read the sim XML
my $simXML = "$simName" . "_create.xml";
open READ_XML, "/netsim/netsimdir/exported_items/$simXML" or die "ERROR: Cannot read XML $simXML\n";
my @simReadXmlArr = <READ_XML>;
close READ_XML;

#-------------------------------------------------
# Remove ftp server data if exist
#------------------------------------------------
my @simWriteXmlArr;
foreach (@simReadXmlArr) {
    next if /<FtpServer user/ .. /<\/FtpServer>/;
    push(@simWriteXmlArr, $_);
#    print "$_";
}

#-------------------------------------------------
# Get network type
#------------------------------------------------
my $nw = &getNwType($simName);

#-------------------------------------------------
# Read simNesIpTypeMap from the file
#------------------------------------------------
my $simNesIpTypeMapRef = {};
my $simNesIpTypeMapFile = "$PWD/../dat/simNesIpTypeMap.dat";
# -s means for "The file exists and has non-zero size"
if ( -s $simNesIpTypeMapFile ) {
  print "$simNesIpTypeMapFile file exist ";
  print "ipv4|Ipv6 nodes will be handled \n";
  $simNesIpTypeMapRef = retrieve("$PWD/../dat/simNesIpTypeMap.dat",{binmode=>':raw'});
  print map { "$_ => $$simNesIpTypeMapRef{$_}\n" } keys %$simNesIpTypeMapRef;
} else {
  print "$simNesIpTypeMapFile file DOES NOT exist. ";
  print "DEFAULT ipv4 nodes only will be handled \n";
}
#my $neName = "DUA-S14B02";
#my $ipType = $$simNesIpTypeMapRef{$neName};
#print "ipType = $ipType \n";

#-------------------------------------------------
# Get managedElement xml sections and their offset per ne
#------------------------------------------------
my %manageElmMap = &getManageElmMap(\@simWriteXmlArr);


#-------------------------------------------------
# Process each node and assign correct ftp services
#------------------------------------------------
while ( my($k,$v) = each %manageElmMap) {
    #print "managedElmMap-key=$k \n";	
    my (@arr) = @$v;
    my (@managedElmArr) = @arr[0..$#arr-1];
    my ($offset) = $arr[$#arr];
    #print "xml-offset=$offset \n";
    my $length = @managedElmArr;
    #print "arr-length = " . @arr . "\n"; 
    #print "managedElmArr-length = $length \n"; 
    #print "managedElmArr= \n @managedElmArr";
    #next;
    
    # loop each line of managedElement and replace ftp services
    # correct values. 
    my $neName = undef;
    foreach (@managedElmArr){
        $neName = $1 if /ManagedElementId string="(.*?)"/;
        next unless /SMRSSLAVE-kloker/;

	print "neName = $neName \n";
        my $ipType = "ipv4";
        if ( %$simNesIpTypeMapRef ) {
            $ipType = $$simNesIpTypeMapRef{$neName};
            print "defined-ipType = $ipType \n";
        } else {
            print "undefined-ipType = $ipType \n";
        }
        my $key = $nw . "-" . $ipType;
        print "--ftpServices-key=$key \n";
        my $ftpServicesRef = \%{$ftpServices{$key}};

        print "<$neName>OLD----\n$_";
        while ( my($k2,$v2) = each %$ftpServicesRef ) {
            s/$k2/$v2/g;
        }
        print "<$neName>NEW----\n$_";
    }
    splice(@simWriteXmlArr, $offset, $length , @managedElmArr);
}

foreach (@simWriteXmlArr) {
#    print "$_";
}

#-------------------------------------------------
# Save updated XML into a file
#------------------------------------------------
$simXML = "$simName" . "_simdep_create.xml";
#open WRITE_XML, "/netsim/netsimdir/exported_items/$simXML" or die "Cannot read XML $simXML\n";
open WRITE_XML, ">$PWD/../dat/XML/$simXML"
  or die "ERROR: Cannot write a new file $simXML\n";
print WRITE_XML @simWriteXmlArr;
close WRITE_XML;

# Copy to common areas for better visibility
`cp -v $PWD/../dat/XML/$simXML /netsim/netsimdir/exported_items/$simXML`;

#exit 0;

