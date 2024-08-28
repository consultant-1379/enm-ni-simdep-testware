#!/usr/bin/perl -w

#vars
$PWD = `pwd`;
chomp($PWD);

#
#
###################################################################################
#Subroutine to create logfile
###################################################################################
open logFileHandler, "+>>$PWD/setupProxyLog.txt" or die $!;

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
    &LogFiles("Error: Not root user. Please execute the script as root \n");
    exit(1);
}

#
#
#----------------------------------------------------------------------------------
#Check if the script usage is right
#----------------------------------------------------------------------------------
my $USAGE = "Usage: $0 \n  E.g. $0 \n";
if ( @ARGV != 0 ) {
    print("$USAGE");
    exit(2);
}

#
#
#######################################################################################
#set up Proxy 
#######################################################################################
sub updateProxy{
	LogFiles("updating proxy\n");
	$PROXY_ADDRESS="159.107.173.253:3128";
	if ( -e "/etc/sysconfig/proxy" ) {
		
		open INPUT, "/etc/sysconfig/proxy" or die &LogFiles($!);
		open OUTPUT, "+>>/etc/sysconfig/proxy.bkp" or die &LogFiles($!);
		
		foreach (<INPUT>) {
			if ( $_ =~ m/^PROXY_ENABLED=*/ ) {
				print OUTPUT "PROXY_ENABLED=\"yes\"\n";
				next;
			}

			if ( $_ =~ m/^HTTP_PROXY=*/ ) {
				print OUTPUT "HTTP_PROXY=\"http://$PROXY_ADDRESS\"\n";
				next;
			}

			if ( $_ =~ m/^HTTPS_PROXY=*/ ) {
				print OUTPUT "HTTPS_PROXY=\"http://$PROXY_ADDRESS\"\n";
				next;
			}

			if ( $_ =~ m/^FTP_PROXY=*/ ) {
				print OUTPUT "FTP_PROXY=\"http://$PROXY_ADDRESS\"\n";
				next;
			}

			print OUTPUT "$_";
		}
		close INPUT or die &LogFiles($!);    # Close the file
		close OUTPUT or die &LogFiles($!);    # Close the file
		
		rename "/etc/sysconfig/proxy.bkp", "/etc/sysconfig/proxy";
	}
	else {
	    &LogFiles(
		"updating proxy not successful as /etc/sysconfig/proxy file not present \n");
	}
}
#
#
#
updateProxy();
close(logFileHandler);
