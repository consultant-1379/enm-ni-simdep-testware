#!/usr/bin/perl -w
use Getopt::Long();

###################################################################################
#
#     File Name : fetchFreeIps.pl
#
#     Version : 2.00
#
#     Author : Jigar Shah
#
#     Description : Executes showfreeIPs and gets the IPs
#
#     Date Created : 29 October 2013
#
#     Syntax : ./fetchFreeIps.pl <NumberOfIps>
#
#     Parameters : <ipv4||ipv6> The number of Ips that needs to be fetched
#
#     Example :  ./fetchFreeIps.pl -ipv4=20
#
#     Dependencies : 1. showfreeIPs should be present
#
#     NOTE:
#
#     Return Values : 1 -> Not a netsim user
#             2 -> Usage is incorrect
#
###################################################################################
#
#----------------------------------------------------------------------------------
#Variables
#----------------------------------------------------------------------------------
$PWD = `pwd`;
chomp($PWD);

#
#----------------------------------------------------------------------------------
#Check if the scrip is executed as netsim user
#----------------------------------------------------------------------------------
#
$user = `whoami`;
chomp($user);
$netsim = 'netsim';
if ( $user ne $netsim ) {
    print "ERROR: Not netsim user. Please execute the script as netsim user\n";
    exit(201);
}

#
#----------------------------------------------------------------------------------
#Check if the script usage is right
#----------------------------------------------------------------------------------
sub usage {
    my $message = $_[0];
    if ( defined $message && length $message ) {
        $message = "HELP: $message \n"
          unless $message =~ /\n$/;
    }

    my $command = $0;
    $command =~ s#^.*/##;

    print STDERR (
        $message,
        "  usage: $command -ipv4=12 \n"
          . "  usage: $command -ipv6=10 \n"
          . "  usage: $command -ipv4=12  -ipv6=10 \n"
    );

    die("\n");
}

my $numOfIpv4;
my $numOfIpv6;

Getopt::Long::GetOptions(
    'ipv4=i' => \$numOfIpv4,
    'ipv6=i' => \$numOfIpv6,
) or usage("ERROR: Invalid commmand line options.");

usage("ERROR: Type and number of ip address must be specified.")
  unless defined $numOfIpv4 || $numOfIpv6;

print "RUNNING: $0 @ARGV \n";


#
#----------------------------------------------------------------------------------
#Environment variable
#----------------------------------------------------------------------------------
#
print "requested-numOfIpv4=$numOfIpv4 \n" if defined $numOfIpv4;
print "requested-numOfIpv6=$numOfIpv6 \n" if defined $numOfIpv6;

my $IPv4_FILE = "$PWD/../dat/free_IpAddr_IPv4.txt";
my $IPv6_FILE = "$PWD/../dat/free_IpAddr_IPv6.txt";


