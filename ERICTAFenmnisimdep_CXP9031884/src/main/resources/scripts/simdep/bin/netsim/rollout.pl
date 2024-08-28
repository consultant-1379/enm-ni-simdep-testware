#!/usr/bin/perl -w
use Net::FTP;
use POSIX;
use Config::Tiny;
use Cwd qw(abs_path);
use File::Basename;
###################################################################################
#
#     File Name : rollout.pl
#
#     Version : 5.00
#
#     Author : Jigar Shah
#
#     Description : Gets the latest deployer build version from storage server.
#
#     Date Created : 28 Januray 2103
#
#     Syntax : ./rollout.pl <simPath> <IP-OSS-Master> <PATH> <caasIP>
#
#     Parameters : <simPath> Path where sims are.
#                  <IP-OSS-Master> IP address of OSS master
#                  <PATH> The working directory
#
#     Example :  ./rollout.pl /sims/CORE/xjigash/simNetDeployer/simulation
#
#     Dependencies : 1. Should be able to access storage device - FTP server.
#
#     NOTE: 1. The module is only enabled to support FTP as a storage device
#
#     Return Values : 1 ->Not a root user
#                     2 -> Usage is incorrect
#
###################################################################################
#
#----------------------------------------------------------------------------------
#Check if the scrip is executed as root user
#----------------------------------------------------------------------------------
#
my $user = `whoami`;
chomp($user);
my $root = 'root';
if ( $user ne $root ) {
    print "ERROR: Not root user. Please execute the script as root user\n";
    exit(201);
}

#
#----------------------------------------------------------------------------------
#Check if the script usage is right
#----------------------------------------------------------------------------------

my $USAGE =<<USAGE;
    Usage:
        $0 <simPath> <IP-OSS-Master> <Working_Path> <server_Type> <release> <securityStatusTLS> <sims> <ipv6Per><switchToRvConf>
        where:
            <simPath>            : Specifies simulation path from where sims have to be fetched
            <IP-OSS-MASTER>      : Specifies ip address of the oss master.
            <Working_Path>       : Specifies the working path directory.
            <serverType>         : Specifies if the server type is VAPP/VM.
            <release>            : Specifies the release version of simulations.
            <securityStatusTLS>  : Specifies if the TLS is on/off.
            <switchToRvConf>     : Specifies if the Whether the rollout performed is for RV or MT-yes/no
            <sims>               : Specifies the sim names to be fetched from FTP (This is a optional Parameter).
            <ipv6Per>            : Specifies the whether IPV6 nodes needed or not
        usage examples:
             $0 /sims/O16/ENM/16.5/mediumDeployment/LTE/5KLTE/ 192.168.0.12 /tmp/LTE/simNetDeployer/16.5/ VM 16.5 ON LTE01:LTE02:LTE07 no
             $0 /sims/O16/ENM/16.5/mediumDeployment/LTE/5KLTE/ 192.168.0.12 /tmp/LTE/simNetDeployer/16.5/ VM 16.5 ON
        dependencies:
              1. Should be able to access storage device - FTP server.
        Return Values: NONE
USAGE

# HELP
if ( @ARGV > 9 ) {
    print "ERROR:\n$USAGE";
    exit(202);
}
print "RUNNING: $0 @ARGV \n";

#----------------------------------------------------------------------------------
#Variables
#----------------------------------------------------------------------------------
my $PWD = dirname(abs_path($0));
print "PWD:$PWD \n";
chomp($PWD);

#
#Variable Declaration
my $simPath           = "$ARGV[0]";
my $ossIP             = "$ARGV[1]";
my $dirSimNetDeployer = "$ARGV[2]";
my $serverType        = "$ARGV[3]";
my $release           = "$ARGV[4]";
my $securityStatusTLS = "$ARGV[5]";
my $ipv6Per        = "$ARGV[6]";
my $sim            = $ARGV[8];
my $switchToRvConf = "$ARGV[7]";

$sim = "" if not defined $sim;

#
#------------------------------------------
# Config file params
#------------------------------------------
my $CONFIG_FILE  = "conf.txt";
my $CONFIG_FILE_PATH ="$PWD/../conf/$CONFIG_FILE";
my $Config = Config::Tiny->new;
$Config = Config::Tiny->read($CONFIG_FILE_PATH);

# Reading properties
my $docker = $Config->{_}->{SWITCH_TO_DOCKER};
print "INFO: SWITCH_TO_DOCKER: ". uc($docker) . "\n";


#
#-----------------------------------------------------------------
#Execute ENV files
#-----------------------------------------------------------------
system("chmod u+x $dirSimNetDeployer/utils/showIPs.sh");
if ($? != 0)
{
        print "INFO: Failed to execute system command (chmod u+x $dirSimNetDeployer/utils/showIPs.sh)\n";
        print "************Copying utils,conf and certs content again*******\n";
        system("scp /var/simnet/enm-ni-simdep/scripts/simdep/certs/* $dirSimNetDeployer/certs/");
        system("scp /var/simnet/enm-ni-simdep/scripts/simdep/conf/* $dirSimNetDeployer/conf/");
        system("scp /var/simnet/enm-ni-simdep/scripts/simdep/dat/netsim/* $dirSimNetDeployer/dat/");
        system("scp /var/simnet/enm-ni-simdep/scripts/simdep/dat/masterserver/* $dirSimNetDeployer/dat/");
        system("scp /var/simnet/enm-ni-simdep/scripts/simdep/utils/netsim/* $dirSimNetDeployer/utils/");
        if ($? != 0)
        {
                print "ERROR: Failed to execute system command (scp /var/simnet/enm-ni-simdep/scripts/simdep/utils/netsim/* $dirSimNetDeployer/utils/)\n";
                exit(207);
         }
         system("chmod u+x $dirSimNetDeployer/utils/showIPs.sh");
         if ($? != 0)
         {
                print "ERROR: Failed to execute system command (chmod u+x $dirSimNetDeployer/utils/showIPs.sh)\n";
                exit(207);
         }
}
system("$dirSimNetDeployer/utils/showIPs.sh $dirSimNetDeployer");
if ($? != 0)
{
    print "ERROR: Failed to execute system command ($dirSimNetDeployer/utils/showIPs.sh $dirSimNetDeployer)\n";
    exit(207);
}

#-------------------------------------------------------------------
#Creating tmpfs files
#-------------------------------------------------------------------

#-------------------------------------------------------------------
#Changing permissions for pm_tmpfs
#------------------------------------------------------------------
$PWD =`pwd`;
system("cd /pms_tmpfs;chown netsim:netsim *");
chdir("$PWD");

#if ( $docker !~ m/yes/i ) {
#    system('cp /etc/fstab /etc/fstab.sav;cat /etc/fstab.sav | grep -v pms_tmpfs > /etc/fstab;echo "tmpfs /pms_tmpfs tmpfs rw,size=72G 0 0" >> /etc/fstab; mkdir -p /pms_tmpfs ; mount -a ; chown netsim:netsim /pms_tmpfs');
#} else {
#    print "INFO: Docker mode is ENABLED. Hence /pms_tmpfs folder is NOT created \n";
#}

if ( defined $sim )
{
    system("sudo su -l netsim -c '$dirSimNetDeployer/bin/simNetDeployer.pl $simPath $ossIP $dirSimNetDeployer $serverType $release $securityStatusTLS $ipv6Per $switchToRvConf $sim'");
    if ($? != 0)
    {
        print "ERROR: Failed to execute system command (sudo su -l netsim -c '$dirSimNetDeployer/bin/simNetDeployer.pl $simPath $ossIP $dirSimNetDeployer $serverType $release $securityStatusTLS $ipv6Per $switchToRvConf $sim') \n";
        exit(207);
    }
}
else
{
    system("sudo su -l netsim -c '$dirSimNetDeployer/bin/simNetDeployer.pl $simPath $ossIP $dirSimNetDeployer $serverType $release $securityStatusTLS $ipv6Per $switchToRvConf'");
    if ($? != 0)
    {
        print "ERROR: Failed to execute system command (sudo su -l netsim -c '$dirSimNetDeployer/bin/simNetDeployer.pl $simPath $ossIP $dirSimNetDeployer $serverType $release $securityStatusTLS $ipv6Per $switchToRvConf') \n";
        exit(207);
    }
}
