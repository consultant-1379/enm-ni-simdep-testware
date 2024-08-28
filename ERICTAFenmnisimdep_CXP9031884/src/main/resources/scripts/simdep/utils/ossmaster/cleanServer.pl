#!/usr/bin/perl -w
use POSIX;
###################################################################################
#
#     File Name : cleanServer.pl
#
#     Version : 2.00
#
#     Author : Jigar Shah
#
#     Description : delete dummy XML.
#
#     Date Created : 12 Feburary 2014
#
#     Syntax : ./cleanServer.pl <PATH>
#
#     Parameters :
#
#
#     Example :
#
#     Dependencies : 1.
#
#     NOTE: 1.
#
#     Return Values : 1 ->
#
#
###################################################################################
#
#----------------------------------------------------------------------------------
#Check if the scrip is executed as root user
#----------------------------------------------------------------------------------
#
$user = `whoami`;
chomp($user);
$root = 'root';
if ( $user ne $root ) {
    print "Error: Not root user. Please execute the script as root user\n";
    exit(1);
}

#
#Var
$dirSimNetDeployer = $ARGV[0];
$xmlPath           = "$dirSimNetDeployer/dat/XML";

#----------------------------------------------------------------------------------
#import nodes
#----------------------------------------------------------------------------------

for ( $count = 3 ; $count >= 1 ; $count-- ) {

`/opt/ericsson/arne/bin/import.sh -f $xmlPath/LTED1180-V2x10-FT-FDD-LTE01-dummy_delete.xml -import -i_nau > $dirSimNetDeployer/logs/output.log`;
    $validTextImport   = "No Errors Reported.";
    $compareTextImport = `tail -1 $dirSimNetDeployer/logs/output.log`;
    chomp($compareTextImport);
    if ( "$validTextImport" eq "$compareTextImport" ) {
`mv $dirSimNetDeployer/logs/output.log $dirSimNetDeployer/logs/output.log.pass`;
        print "Import successful\n";
        `rm $xmlPath/LTED1180-V2x10-FT-FDD-LTE01-dummy_delete.xml`;
        `rm $xmlPath/LTED1180-V2x10-FT-FDD-LTE01-dummy_modified.xml`;
        exit(2);
    }
    else {
`mv $dirSimNetDeployer/logs/output.log $dirSimNetDeployer/logs/output.log.fail`;
        print "Import not successful \n";
    }
}
