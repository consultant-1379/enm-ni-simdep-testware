#!/usr/bin/perl -w
use Net::FTP;
use POSIX;
###################################################################################
#
#     File Name : setupOmsas.pl
#
#     Version : 4.00
#
#     Author : Jigar Shah
#
#     Description : sets up the security related settling prior to deployment
#
#     Date Created : 28 Januray 2103
#
#     Syntax : ./setupSecurity.pl <PATH>
#
#     Parameters : <PATH> The working directory in OMSAS
#
#     Example :  ./setupOmsas.pl /sims/CORE/xjigash/simNetDeployer/
#
#     Dependencies : 1. Should be able to access storage device - FTP server.
#
#     NOTE: 1. The module is only enabled to support FTP as a storage device
#
#     Return Values :
#
###################################################################################
#
#----------------------------------------------------------------------------------
#Check if the scrip is executed as root user
#----------------------------------------------------------------------------------
#
$user = `id`;
chomp($user);
$root = 'uid=0(root) gid=0(root)';
if ( $user ne $root ) {
    print "Error: Not root user. Please execute the script as root user\n";
    exit(1);
}

#
#Vars
$dirSimNetDeployer = $ARGV[0];
my $USAGE =
  "Usage: $0 <storagePath> \n  E.g. $0 /sims/CORE/xjigash/simNetDeployer/ \n";

#----------------------------------------------------------------------------------
#Check if the script usage is right
#----------------------------------------------------------------------------------
#
if ( @ARGV != 1 ) {
    print("$USAGE");
    exit(2);
}

#
#----------------------------------------------------------------------------------
#Change path to dir where you want to transfer the files
#----------------------------------------------------------------------------------
chdir("$dirSimNetDeployer");

#
#------------------------------------------
#Details of FTP server and the credentials.
#------------------------------------------
#The details are hardcoded into the code. Need a better way to do this
$host     = "159.107.220.96";
$user     = "simguest";
$password = "simguest";

#
#------------------------------------------
#Variables
#------------------------------------------
my $pathStorage = '/sims/xjigash/simNetDeployer/omsas/';

#-----------------------------------------------
#Access the FTP server and fetch deployer.
#-----------------------------------------------
#
my $f = Net::FTP->new($host) or die "Can't open $host\n";
$f->login( $user, $password ) or die "Can't log $user in\n";

$f->cwd($pathStorage) or die "Can't cwd to $pathStorage\n";
$f->binary;
$f->get("conf.txt") or die "Error: Failed to get \n";

#
#--
