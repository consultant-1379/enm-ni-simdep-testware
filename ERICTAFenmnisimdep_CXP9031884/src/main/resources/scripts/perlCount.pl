#!/usr/bin/perl -w
use ExtUtils::Installed;
use Switch;
use Cwd 'abs_path';
use File::Basename;

##########################################################################################################################
# Created by  : Sneha Srivatsav Arra
# Created in  : 2015.11.25
##
### VERSION HISTORY
# Ver         : Follow up from gerrit
# Purpose     : To count the number of perl packages installed and installs if any package  is missing.
# Dependency  :
# Description : checks the perl packages installed and calls the perl_install.sh script if any packages is missing.
# Date        : 25 NOV 2015
# Who         : Sneha Srivatsav Arra
###########################################################################################################################
#
#---------------------------------------------------------------------------------
#variables
#---------------------------------------------------------------------------------
my $multiRollout=$ARGV[0];
my $serverType=$ARGV[1];
my $install_Type=$ARGV[2];
my $rolloutType=$ARGV[3];
my $module;
my $inst = ExtUtils::Installed->new();
my $Config="Config::Tiny";
my $Expect="Expect";
my $IO="IO::Tty";
my $IP="Net::IP";
my $OpenSSH="Net::OpenSSH";
my $Perl="Perl";
my $parallel="Parallel::ForkManager";
my $Flag=0;
my $opensslversion=`openssl version | cut -d ' ' -f2`;
chomp($opensslversion);
$opensslversion=substr($opensslversion,0,5);
$opensslversion=~ s/\.//g;
my $opensshversion=`rpm -qa | grep openssh | grep -v askpass | grep -v server | grep -v clients`;
chomp($opensshversion);
$opensshversion=substr($opensshversion,8,3);
$opensshversion=~ s/\.//g;
$NRM=`cat /netsim/simdepContents/NRMDetails | grep -w 'RolloutNetwork' | cut -d '=' -f2`;
$LARGE_NTWK_CHECK=`ls /netsim/simdepContents/ | grep -E "GSM_30Kcells|30KGRAN|10KWCDMA"`;
#
#---------------------------------------------------------------------------------
# Checking the arguments and saving all installed modules so far in a variable.
#---------------------------------------------------------------------------------
my (@modules) = $inst->modules();
my $length = @modules;
my $USAGE = "$0 y VAPP online GCP or  $0 n VM online no or $0 y VM online GCP or $0 n VAPP offline no\n";
if ( @ARGV != 4 ) {
    print "Please provide correct arguments. \nUsage: $USAGE";
    exit(202);
}
#
#---------------------------------------------------------------------------------
# Main
#---------------------------------------------------------------------------------
if($serverType eq "VM")
{
    if($multiRollout eq "y")
    {
        if($length >= 7)
        {
            foreach $module (@modules) {
                switch ($module) {
                    case [$Config,$Expect,$IO, $IP, $OpenSSH, $Perl, $parallel] { print "$module: installed!\n" }
                    else { $Flag=1; print "$module : not installed! \n"}
                }
            }
        }
        else
        {
             $Flag=1;
        }
    }
    else
    {
        if($length >= 6)
        {
            foreach $module (@modules) {
                switch ($module) {
                    case [$Config, $Expect, $IO, $IP, $OpenSSH, $Perl, $parallel] { print "$module: installed!\n" }
                    else { $Flag=1; print "$module : not installed! \n"}
                }
            }
        }
        else
        {
             $Flag=1;
        }
    }
    if($opensslversion ne 111 )
    {
        print "Openssl is not the latest version \n";
        $Flag=1;
    }
    if ($NRM eq "rvModuleNRM5_5K_GSM" || $NRM eq "rvModuleGRAN_30KCells_NRM5" || defined $LARGE_NTWK_CHECK)
    {
        $bitversion=`openssl version -a | grep -w 'platform:' | awk -F ': ' '{print $2}'`;
        if($bitversion ne "linux-x86_64")
        {
            $Flag=1;
        }
    }
    else
    {
        $bitversion=`openssl version -a | grep -w 'platform:' | awk -F ': ' '{print $2}'`;
        if($bitversion ne "linux-generic32")
        {
            $Flag=1;
        }
    }
    $releaseFile = '/etc/centos-release';
    unless (-e $releaseFile) {
      if( $opensshversion < 58 )
      {
         print "Openssh is not the latest version \n";
         $Flag=1;
      }
    }
}

if($serverType eq "VAPP")
{
     if($opensslversion ne 111 )
     {
        print "Openssl is not the latest version \n";
        $Flag=1;
     }
} 

if($Flag eq 1)
{
    print "INFO: Need to install perl modules!!\n";
    print "INFO: Installing perl modules \n";
    my $absScriptName = abs_path($0);
    my $scriptDir =  File::Basename::dirname($absScriptName);
    my $targetScript = $scriptDir . "/perl_install.sh " . $install_Type . " " . $rolloutType;
    print "INFO: Cmd to run : .$targetScript \n";
    system("$targetScript");
}
else
{
    print "INFO: Perl packages seems ok. Requires a double check.\n";
}
