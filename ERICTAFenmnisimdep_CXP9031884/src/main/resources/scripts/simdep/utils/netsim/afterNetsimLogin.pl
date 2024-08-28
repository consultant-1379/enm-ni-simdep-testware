#!/usr/bin/perl -w
#
###################################################################################
#
#     File Name : afternetsimlogin.pl
#
#     Version : 2.4
#
#     Author : Jigar Shah
#
#     Description : This script is sets up SSH, TELNET, SNMP and FTP.
#
#     Date Created : 5th March 2013.
#
#     Syntax : ./afternetsimlogin.pl
#
#     Parameters :
#
#     Example :  ./afternetsimlogin.pl
#
#     Dependencies : 1. You need to execute this script as a root user.
#                    2.
#
#
#     NOTE:  You must be a root user to execute this script.
#	     Incase you want to start all NE after NETSim restart, execute
#	     /netsim/inst/netsim_shell | /netsim/inst/bin/start_all_simne.sh
#
#     Return Values : /tmp/Afternetsimloginlogs.txt --> Time stamped logs.
#
###################################################################################
#
#
#vars
$PWD = `pwd`;
chomp($PWD);

#
#
###################################################################################
#Subroutine to create logfile
###################################################################################
open logFileHandler, "+>>$PWD/afterNetsimLoginLogs.txt" or die $!;

sub LogFiles {
    $Date = localtime;
    print logFileHandler "$Date: @_";
    print "$Date: @_";
}

#
#
#
###################################################################################
#Check if the user is root
###################################################################################
$user = `whoami`;
chomp($user);
$root = 'root';
if ( $user ne $root ) {
    &LogFiles("ERROR: Not root user. Please execute the script as root \n");
    exit(201);
}

#
#
#----------------------------------------------------------------------------------
#Check if the script usage is right
#----------------------------------------------------------------------------------
my $USAGE = "Usage: $0 \n  E.g. $0 \n";
if ( @ARGV != 0 ) {
    print("$USAGE");
    exit(202);
}

#
#######################################
# Get the IP address of netsim server.
#######################################
$Hostname = `hostname`;
@arr      = `nslookup $Hostname`;
$Address  = substr( $arr[4], 9 );

#
#
#
#
#################################################################################
#set up SSH
#################################################################################
LogFiles("set up SSH \n");
if ( -e "/etc/ssh/sshd_config" ) {

    #This is implementation of section 2.7.3 section in SAG.
    #Read the ssh deamon config file
    open FILE, "/etc/ssh/sshd_config" or die &LogFiles($!);

    #flag =0 indicates that the ListenAddress needs to be added.
    $flag = 0;
    foreach (<FILE>) {
        if ( $_ =~ m/^ListenAddress $Address/ ) {
            $flag = 1;

        #Set $Flag =1 here if ListenAddress is right. And break out of the loop.
            last;
        }
    }
    close FILE or die &LogFiles($!);    # Close the file

    #If ListenAddress is not added, add it.
    if ( $flag == 0 ) {
        open FH, "+>>/etc/ssh/sshd_config" or die &LogFiles($!);
        print FH "ListenAddress $Address";
        print FH "ListenAddress 127.0.0.1";
        close(FH);
    }

    #Reload the configuration.
    @sshsetUp = `/etc/init.d/sshd restart`;
    chomp(@sshsetUp);
    @sshsetUpVerify =
      ( "Shutting down SSH daemon..done", "Starting SSH daemon..done" );
    if ( $sshsetUp[0] eq $sshsetUpVerify[0] ) {
        if ( $sshsetUp[1] eq $sshsetUpVerify[1] ) {
            &LogFiles("Reload configuration successful \n");
            &LogFiles("All the NEs to start their own SSH server \n");
        }
    }
}
else {
    &LogFiles(
        "set up SSH not successful as /etc/ssh/sshd_config file is missing\n");
}

#
#
#
#Setting the right access rights on the netsim home directory
system("chmod 755 ~netsim");
if ($? != 0)
{
    print "ERROR: Failed to execute system command (chmod 755 ~netsim)\n";
    exit(207);
}

#
#
#
#############################################################################
#Setting up TELNET
#############################################################################
LogFiles("set up TELNET\n");
if ( -e "/etc/xinetd.d/telnet" ) {

    #Read the telnet config file
    open FILE, "/etc/xinetd.d/telnet" or die &LogFiles($!);

    #
    #flag =0 indicates that the ListenAddress needs to be added.
    $flag = 0;
    foreach (<FILE>) {
        if ( $_ =~ /interface       = $Address/ ) {
            $flag = 1;

        #Set $Flag =1 here if ListenAddress is right. And break out of the loop.
            last;
        }
    }
    close FILE or die &LogFiles($!);    # Close the file

    #If ListenAddress is not added, add it.
    if ( $flag == 0 ) {
        open FH, "+>>/etc/xinetd.d/telnet" or die &LogFiles($!);

        #delete the last \n and } of the file
        truncate( FH, 292 );

        #Add the line that you need
        print FH "{\n";
        print FH "        socket_type     = stream\n";
        print FH "        protocol        = tcp\n";
        print FH "        wait            = no\n";
        print FH "        user            = root\n";
        print FH "        server          = /usr/sbin/in.telnetd\n";
        print FH "      interface       = $Address";
        print FH "}";
        close(FH);
    }

    #Restart xinetd
    @telnet = `/etc/init.d/xinetd restart`;
    chomp(@telnet);
    @telnetVerify = (
        "Shutting down xinetd:..done",
        "Starting INET services. (xinetd)..done"
    );
    @telnetVerify1 = (
        "Shutting down xinetd: (waiting for all children to terminate) ..done",
        "Starting INET services. (xinetd)..done"
    );
    if (   ( $telnet[0] eq $telnetVerify[0] )
        || ( $telnet[0] eq $telnetVerify1[0] ) )
    {
        if ( $telnet[1] eq $telnetVerify[1] ) {
            &LogFiles("Restart of xinetd successful \n");
            &LogFiles("All the NEs to start their own TELENT server \n");
        }
    }
    else {
        &LogFiles("restart xinetd not successful \n");
    }
}
else {
    &LogFiles(
        "set up TELNET not successful as /etc/xinetd.d/telnet file is missing\n"
    );
}

#
#
#
#############################################################################################
#Set up SNMP
#############################################################################################
LogFiles("set up SNMP\n");
if ( -e "/etc/snmp/snmpd.conf" ) {

    #Read the ssh deamon config file
    open FILE, "/etc/snmp/snmpd.conf" or die &LogFiles($!);

    #flag =0 indicates that the agentaddress needs to be added.
    $flag = 0;
    foreach (<FILE>) {
        if ( $_ =~ m/^agentaddress $Address/ ) {
            $flag = 1;

         #Set $Flag =1 here if agentaddress is right. And break out of the loop.
            last;
        }
    }
    close FILE or die &LogFiles($!);    # Close the file

    #If agentaddress is not added, add it.
    if ( $flag == 0 ) {
        open FH, "+>>/etc/snmp/snmpd.conf" or die &LogFiles($!);
        print FH "agentaddress $Address";
        close(FH);
    }

    #Reload the configuration
    @snmp = `/etc/init.d/snmpd restart`;
    chomp(@snmp);
    @snmpVerify = ( "Shutting down snmpd ..done", "Starting snmpd ..done" );
    if ( @snmp == @snmpVerify ) {
        &LogFiles("Reload of configuration successful \n");
        &LogFiles("All the NEs to start their own SNMP server\n");
    }
}
else {
    &LogFiles(
        "set up SNMP not successful as /etc/snmp/snmpd.conf file is missing \n"
    );
}

#
#
#
#######################################################################################
#set up FTP
#######################################################################################
LogFiles("set up FTP\n");
if ( -e "/etc/vsftpd.conf" ) {
    open FILE, "/etc/vsftpd.conf" or die &LogFiles($!);

    #flag =0 indicates that the listenAddress needs to be added.
    $flag = 0;
    foreach (<FILE>) {
        if ( $_ =~ m/^listen_address=$Address/ ) {
            $flag = 1;

        #Set $Flag =1 here if ListenAddress is right. And break out of the loop.
            last;
        }
    }
    close FILE or die &LogFiles($!);    # Close the file

    #If ListenAddress is not added, add it.
    if ( $flag == 0 ) {
        open FH, "+>>/etc/vsftpd.conf" or die &LogFiles($!);
        print FH "listen_address=$Address";
        close(FH);
    }

    #verify ftp
    @ftp = `/etc/init.d/vsftpd restart`;
    chomp(@ftp);
    @ftpVerify = ( "Shutting down vsftpd ..done", "Starting vsftpd ..done" );
    if ( $ftp[0] eq $ftpVerify[0] ) {
        if ( $ftp[1] eq $ftpVerify[1] ) {
            &LogFiles("Restart of vsftpd successful \n");
            &LogFiles("All the NEs to start their own FTP server \n");
        }
    }
    else {
        &LogFiles("vsftpd restart not successful \n");
    }
}
else {
    &LogFiles(
        "set up FTP not successful as /etc/vsftpd/conf file not present \n");
}

#
#
#
##############################################################################################
#Preparing for NEs Using Privileged Ports
##############################################################################################
$MOSCRIPT_mo = "MOSCRIPT.mo";
open MOSCRIPT, ">$MOSCRIPT_mo" or die &LogFiles($!);
print MOSCRIPT ".server stop all \n";
system("su - netsim -c /netsim/inst/netsim_shell < $MOSCRIPT_mo");
if ($? != 0)
{
    print "ERROR: Failed to execute system command (su - netsim -c /netsim/inst/netsim_shell < $MOSCRIPT_mo)\n";
    exit(207);
}
close MOSCRIPT or die &LogFiles($!);    # Close the file
system("rm $MOSCRIPT_mo");
if ($? != 0)
{
    print "INFO: Failed to execute system command (rm $MOSCRIPT_mo)\n";
}

$SetUpFDServer = `/netsim/inst/bin/setup_fd_server.sh 2>&1`;

if ( $SetUpFDServer eq "" ) {
    &LogFiles("setup_fd_server.sh executed successfully\n");
    &LogFiles("Restarting NETSim\n");
    @arr = `su - netsim -c /netsim/inst/restart_netsim`;
    if ( grep { /NETSim started successfully/ } @arr ) {
        &LogFiles("NETSim started successfully\n");
    }
    else {
        &LogFiles("NETSim restart not successfully\n");
    }
}
else {
    &LogFiles("setup_fd_server.sh not executed successfully. \n");
}
close(logFileHandler);
