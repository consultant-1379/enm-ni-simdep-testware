#!/usr/bin/perl
### VERSION HISTORY
######################################################################################
#
#     Author : SimNet/epatdal
#
#     Description : searches the LMI Nexus for SimNet repository namely :-
#                   https://arm901-eiffel004.athtem.eei.ericsson.se:8443/nexus/content/repositories/simnet/com/ericsson/simnet/ENM
#                   for network simulations of type LTE, WRAN, GRAN, Core or ONETWORK based on user input defined parameters
#                   and either downloads or displays the simulation(s)
#
#     Version : 1.0.2
#
#     User Story : OSS-50499
#
#     User Guide : LMI-14:002445
#
#     Syntax : ./searchNexusSimNet.pl <NETWORKREVISION> <NETWORKTYPE> <NETWORKAREA> <NETWORKIDENTIFIER> <ACTION>
#     Example : ./searchNexusSimNet.pl 14.0.1 LTE FT ALL DOWNLOAD
#
#     Params : <NETWORKREVISION> = software revision of the softwarea eg. 13.0.2,14.1.2 etc.
#              <NETWORKTYPE> = eg. LTE or WRAN or GRAN or Core or ONETWORK
#              <NETWORKAREA> = eg. RV or FT
#              <NETWORKIDENTIFIER> = simulation instance revision eg. 1,2,3,4 etc.
#              <ACTION> = either DOWNLOAD simulation(s) or DISPLAY simulation(s)
#              {NETWORKTESTSTATUS} = either PENDING, PASSED or LATEST {optional param. for DOWNLOAD sims. only}
#
#     Date : November 2014
######################################################################################
# Version     : LTE 16.01
# User Story  : NSS-1097
# Purpose     : Integrate download simulation from nexus to ENM SimDep scripts
# Description : - Extend nexus_simnet_repository path to use the scripts input
#                   parameters to narrow the search, making it more precise.
#               - Update logic so optional parameter {NETWORKTESTATUS} must be
#                   provided when {ACTION}="DOWNLOAD" is selected.
#               - Remove the effect of {NETWORKIDENTIFIER}.
# Date        : 06 Nov 2015
# Who         : edalrey
######################################################################################
####################
# Env
####################
use FindBin qw($Bin);
use Cwd;
use File::Basename;
####################
# Vars
####################
local @helpinfo=qq(
Usage : ${0} <NETWORKREVISION> <NETWORKTYPE> <NETWORKAREA> <NETWORKIDENTIFIER> <ACTION> {NETWORKTESTSTATUS}

Example: ${0} 15.2.1 GRAN RV 1 DISPLAY
         ${0} 14.0.1 WRAN FT 2 DISPLAY
         ${0} 14.0.1 LTE FT ALL DOWNLOAD PENDING
         ${0} 14.2.3 CORE RV 10 DOWNLOAD PASSED
         ${0} 15.0.1 LTE RV 10 DOWNLOAD LATEST

         ### RESERVED Simulation Versions ###
         ${0} 0.0.0 LTE FT ALL DOWNLOAD LATEST
         Note : version 0.0.0 is for test simulations ONLY (see Eridoc LMI-14:002445)

         ${0} 1.1.1 WRAN RV 3 DISPLAY
         Note : version 1.1.1 is for DEV simulations ONLY (see Eridoc LMI-14:002445)

         ${0} 2.2.2 CORE RV 3 DISPLAY
         Note : version 2.2.2 is for ARCHIVE simulations ONLY (see Eridoc LMI-14:002445)

Description  : this script queries the LMI Nexus SimNet repository at :
               https://arm901-eiffel004.athtem.eei.ericsson.se:8443/nexus/content/repositories/simnet/com/ericsson/simnet/ENM
               and lists and/or downloads the simulations based on the user input search parameters

               <NETWORKREVISION> = software revision of the softwarea eg. 13.0.2,14.1.2 etc.
               <NETWORKTYPE> = eg. LTE or WRAN or GRAN or Core or ONETWORK
               <NETWORKAREA> = eg. RV or FT
               <NETWORKIDENTIFIER> = simulation instance revision eg. 1,2,3,4 etc.
               <ACTION> = either DOWNLOAD simulation(s) or DISPLAY simulation(s)
               {NETWORKTESTSTATUS} = either PENDING, PASSED or LATEST {optional param. for DOWNLOAD sims. only}
               );
#-----------------------------------------
# ensure params are as expected
#-----------------------------------------
if (!( @ARGV==5 || @ARGV==6 )){
    print "@helpinfo\n";exit(1);
}
local $NETWORKREVISION=$ARGV[0],$NETWORKTYPE=$ARGV[1],$NETWORKAREA=$ARGV[2],$NETWORKIDENTIFIER=$ARGV[3],$ACTION=$ARGV[4],$NETWORKTESTSTATUS=$ARGV[5];
local $dir=cwd;my $currentdir=$dir."/";
local $scriptpath="$currentdir";
local $username=`/usr/bin/whoami`;$username=~s/\n//;
#################################
# NEXUS Server Details
################################
local $netsimdir="/netsim/netsimdir/";
local $nexus_http_prefix="https\:\/\/";
local $nexus_http_port="\:8443";
local $nexus_search_command="/usr/bin/wget -d -r -np -N --spider -nd -e robots=off --no-check-certificate";
local $nexus_server="arm901-eiffel004.athtem.eei.ericsson.se";
local $nexus_simnet_repository="\/nexus\/content\/repositories\/simnet\/com\/ericsson\/simnet\/ENM\/$NETWORKREVISION\/$NETWORKTYPE\/$NETWORKAREA\/";
local $nexus_simnet_searchparam1=" 2\>\&1 \| grep \"\ -> \"";
local $nexus_simnet_searchparam2="\| grep \-Ev \"\\\/\\\?C\=\"";
local $nexus_simnet_searchparam3="\| sed \"s\/\.\* \-> \/\/\"";
local $nexus_simnet_searchparam4="\| grep -i \".zip\"";
local $nexus_simnet_searchexecution="$nexus_search_command "."$nexus_http_prefix"."$nexus_server"."$nexus_http_port"."$nexus_simnet_repository"."$nexus_simnet_searchparam1"."$nexus_simnet_searchparam2"."$nexus_simnet_searchparam3"."$nexus_simnet_searchparam4";
local @NEXUS_COMMAND_SEARCHEXECUTION=`$nexus_simnet_searchexecution`;
local @NEXUS_FOUND_SIMS=();
local $commandline,$commandline2,$unzipcommand,$downloadsim;
local $nexussimcounter;
local $teststatus="UNKNOWN";
if($NETWORKTESTSTATUS eq ""){$NETWORKTESTSTATUS="UNKNOWN";}
####################
# Integrity Check
####################
#-----------------------------------------
# ensure NEXUS command executed as expected
#-----------------------------------------
if(@NEXUS_COMMAND_SEARCHEXECUTION==0){
    print "FATAL ERROR : $nexus_simnet_searchexecution FAILED to execute as expected\n";exit(1);
}# end if
#-----------------------------------------
# ensure script being executed by netsim
#-----------------------------------------
if ($username ne "netsim"){
    print "FATAL ERROR : ${0} needs to be executed as user : netsim and NOT user : $username\n";exit(1);
}# end if
#-----------------------------------------
# ensure ACTION param populated correctly
#-----------------------------------------
if(($ACTION eq "DOWNLOAD")||($ACTION eq "DISPLAY")){
}# end if
else{
    print "\nFATAL ERROR : <ACTION> param incorrectly input as $ACTION";print "@helpinfo\n";exit(1);
}# end else
#-----------------------------------------------
# ensure NETWORKTESTSTATUS param is as expected
#-----------------------------------------------
if( ($ACTION eq "DOWNLOAD") && ($NETWORKTESTSTATUS ne "UNKNOWN") ){
    print "\nFATAL ERROR : {NETWORKTESTATUS} param combination incorrectly input as $NETWORKTESTSTATUS where <ACTION> is $ACTION";
    print "\nMESSAGE : {NETWORKTESTATUS} can only be set when <ACTION> is DOWNLOAD\n";print "@helpinfo\n";exit(1);
}# end else
################################
# MAIN
################################
$nexussimcounter=0;
###############################
# search NEXUS server for sims
###############################
foreach $element(@NEXUS_COMMAND_SEARCHEXECUTION){
    # NETWORKREVISION
    if( !($NETWORKREVISION=~m/ALL/) ){
        if( !($element=~m/$NETWORKREVISION/) ){
            next;
        }
    }# end NETWORKREVISION

    # NETWORKTYPE
    if( !($NETWORKTYPE=~m/ALL/) ){
        if( !($element=~m/$NETWORKTYPE/) ){
            next;
        }
    }# end NETWORKTYPE

    # NETWORKAREA
    if( !($NETWORKAREA=~m/ALL/) ){
        if( !($element=~m/$NETWORKAREA/) ){
            next;
        }
    }# end NETWORKAREA

    $NEXUS_FOUND_SIMS[$nexussimcounter]=$element;
    $nexussimcounter++;
}# end foreach

# check simulation found on Nexus respoitory
if(@NEXUS_FOUND_SIMS==0){
    print "MESSAGE : ZERO simulations have been found meeting your search criteria on the LMI Nexus for SimNet repository\n";
   # exit(1);
}# end if
#--------------------------
# output Nexus simulations
#--------------------------
if($ACTION eq "DISPLAY"){
    print "**** ${0} SimNet DISPLAY SIMULATIONS ****\n";
    foreach $element(@NEXUS_FOUND_SIMS){
	print "$element\n";
    }# end foreach
}# end if
else{
    my $filenamelatest = "../dat/latestSims.txt";
    open latests, "+>>$filenamelatest";
    print "**** ${0} SimNet DOWNLOAD SIMULATIONS ****\n";
    foreach $element(@NEXUS_FOUND_SIMS){
        $downloadsim="";
        $tempelement=$element;
        $tempelement=~s/.*\///;
        $commandline="/usr/bin/wget --quiet -O $netsimdir$tempelement $element";
        $commandline=~s/\n//;
        print "DOWNLOADING: $commandline\n";
        $ACTIONRETURN = `$commandline`;
        $unzipcommand="/usr/bin/unzip -l $netsimdir$tempelement|grep -i $NETWORKTESTSTATUS";
        $unzipcommand=~s/\n//;
        $commandline2=$unzipcommand;
        $teststatus=`$commandline2`;
        # check teststatus = NETWORKTESTSTATUS
        if($teststatus=~/$NETWORKTESTSTATUS/){
                $downloadsim="$element ... (SIMULATION TEST STATUS = $NETWORKTESTSTATUS)";
                $downloadsim=~s/\n//;
                print "$downloadsim\n";
                my ($tmp) = fileparse $element;
                chomp($tmp);
                print latests "$tmp \n";
        }# end if
        else{
            unlink $element;
        }# end else
    }# end foreach
}# end else
`../utils/filterSims.pl | tee -a ../logs/runtimLogFetchFiles.txt`;
##############################################
# EOS EOS EOS EOS EOS EOS EOS EOS EOS EOS EOS
##############################################
