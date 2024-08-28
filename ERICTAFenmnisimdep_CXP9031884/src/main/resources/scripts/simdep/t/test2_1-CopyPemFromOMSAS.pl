#!/usr/bin/perl -w
use Net::FTP;
use Expect;
use Net::SSH::Expect;
use Net::OpenSSH;

print "Test dummy script to copy TLS Security\n";

#Variable declarations
$dirSimNetDeployer = '/tmp/Security/TLS/';

#Creating SSH object
my $hostOmsas   = 'omsas';
my $userOmsas   = 'root';
my $passwdOmsas = 'shroot';
my $sshOmsas    = Net::OpenSSH->new(
	$hostOmsas,
	user        => $userOmsas,
	password    => $passwdOmsas,
	master_opts => [ -o => "StrictHostKeyChecking=no" ]
);

$timeout = 7;

# this does not work due to try to copy local files
$sshOmsas->scp_put( "dirSimNetDeployer*.pem",
	"/netsim\/netsimdir\/Security\/TLS" )
  or die "scp failed: " . $sshOmsas->error;

=head
print "here";
#$cmd = "scp $dirSimNetDeployer/cert_single.pem $dirSimNetDeployer/CombinedCertCA.pem $dirSimNetDeployer/keys.pem root\@netsim:\/netsim\/netsimdir\/Security\/TLS";
$cmd = "scp $dirSimNetDeployer/*.pem root\@netsim:\/netsim\/netsimdir\/Security\/TLS";
($pty, $pid) = $sshOmsas->open2pty($cmd)
      or die "unable to run remote command $cmd";
$expect = Expect->init($pty);
$expect -> raw_pty(1);
$expect->log_file("../log/expect-copyPemFromOmsas.pm_log", "w");

# or multi-match on several spawned commands with callbacks,
# just like the Tcl version
$expect->expect($timeout,
        [ qr/\(yes\/no\)/ => sub { my $expect = shift;
                $expect->send("yes\n");
                exp_continue; } ],
        [ qr/[Pp]assword/ => sub { my $expect = shift;
                $expect->send("shroot\n");
                exp_continue; } ]
        #'-re', qr'[#>:] $' #' wait for shell prompt, then exit expect
);
$expect->soft_close();
=cut

