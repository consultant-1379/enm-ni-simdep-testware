#!/usr/bin/perl -w
use Net::FTP;
use Expect;
use Net::SSH::Expect;
use Net::OpenSSH;

print "Test dummy script to implement TLS Security\n";
print("Starting set up of TLS Security\n");

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

@cmdArrayOmsas = "
rm -rf $dirSimNetDeployer
mkdir -p $dirSimNetDeployer";

( $outputOmsas, $errputOmsas ) =
  $sshOmsas->capture2( { timeout => 3 }, "@cmdArrayOmsas" );
print "output = $outputOmsas\n";
print "errput = $errputOmsas\n";
$sshOmsas->error and die "ssh create folder failed: " . $sshOmsas->error;

my $gatewayDatOmsasPath = '/root/simnet/simdep/dat/omsas/';
`scp $gatewayDatOmsasPath/conf.txt root\@omsas:$dirSimNetDeployer`;

print(
"All security related files can be found under $dirSimNetDeployer folder on OMSAS server \n"
);
print("Generating Keys.pem file on OMSAS\n");
$timeout = 10;

$cmd =
  "/usr/sfw/bin/openssl genrsa -des3 -out $dirSimNetDeployer/keys.pem 1024";
( $pty, $pid ) = $sshOmsas->open2pty($cmd)
  or die "unable to run remote command $cmd";
$expect = Expect->init($pty);
$expect->raw_pty(1);
$expect->log_file( "../log/expect-setupTLS_log", "w" );

# or multi-match on several spawned commands with callbacks,
# just like the Tcl version
$expect->expect(
	$timeout,
	[
		qr/keys.pem/ => sub {
			my $expect = shift;
			$expect->send("eric123\n");
			exp_continue;
		  }
	],
	'-re',
	qr'[#>:] $'    #' wait for shell prompt, then exit expect
);

$expect->soft_close();

print("Creating cert.csr on OMSAS\n");
$timeout = 10;

$cmd =
"/usr/sfw/bin/openssl req -new -key $dirSimNetDeployer/keys.pem -out $dirSimNetDeployer/cert.csr -config $dirSimNetDeployer/conf.txt";
( $pty, $pid ) = $sshOmsas->open2pty($cmd)
  or die "unable to run remote command $cmd";
$expect = Expect->init($pty);
$expect->raw_pty(1);
$expect->log_file( "../log/expect-setupTLS_log", "w" );

# or multi-match on several spawned commands with callbacks,
# just like the Tcl version
$expect->expect(
	$timeout,
	[
		qr/keys.pem/ => sub {
			my $expect = shift;
			$expect->send("eric123\n");
			exp_continue;
		  }
	],
	'-re',
	qr'[#>:] $'    #' wait for shell prompt, then exit expect
);

$expect->soft_close();

#upto to now the second files intermediate file called cert.csr is created
print("Creating cert.pem on OMSAS (Would approximately take 12 seconds)\n");

$certsPath = '/opt/ericsson/csa/certs/';

@cmdArrayOmsas = "
/opt/ericsson/secinst/bin/credentialsmgr.sh -signCACertReq $dirSimNetDeployer/cert.csr ossmasterNECertCA $dirSimNetDeployer/cert.pem
cp $certsPath/ossmasterMSCertCA.pem $dirSimNetDeployer/CombinedCertCA.pem
echo '' >> $dirSimNetDeployer/CombinedCertCA.pem
cat $certsPath/ossmasterRootCA.pem >> $dirSimNetDeployer/CombinedCertCA.pem
cat $certsPath/ossmasterNECertCA.pem >> $dirSimNetDeployer/CombinedCertCA.pem
head -20 $dirSimNetDeployer/cert.pem > $dirSimNetDeployer/cert_single.pem
chmod 644 $dirSimNetDeployer/CombinedCertCA.pem";

( $outputOmsas, $errputOmsas ) =
  $sshOmsas->capture2( { timeout => 20 }, "@cmdArrayOmsas" );
print "output = $outputOmsas\n";
print "errput = $errputOmsas\n";
$sshOmsas->error and die "ssh create folder failed: " . $sshOmsas->error;

print(
"Transferring pem to netsim Server under \/netsim\/netsimdir\/Security\/TLS folder\n"
);

$timeout = 2;

$cmd =
"scp cert_single.pem CombinedCertCA.pem keys.pem root\@netsim:\/netsim\/netsimdir\/Security\/TLS";
( $pty, $pid ) = $sshOmsas->open2pty($cmd)
  or die "unable to run remote command $cmd";
$expect = Expect->init($pty);
$expect->raw_pty(1);
$expect->log_file( "../log/expect-copyPemFromOmsas.pm_log", "w" );

# or multi-match on several spawned commands with callbacks,
# just like the Tcl version
$expect->expect(
	$timeout,
	[
		qr/\(yes\/no\)/ => sub {
			my $expect = shift;
			$expect->send("yes\n");
			exp_continue;
		  }
	],
	[
		qr/[Pp]assword/ => sub {
			my $expect = shift;
			$expect->send("shroot\n");
			exp_continue;
		  }
	]

	#'-re', qr'[#>:] $' #' wait for shell prompt, then exit expect
);
$expect->soft_close();

