#!/usr/bin/perl
use MIME::Lite;

$to      = 'jigar.shah@wipro.com';
$from    = 'jigar.shah@wipro.com';
$subject = 'Summary report';
open( FH, "../log/invokeSimNetDeployerLogs_2014-04-08_10:55:30.log" );
@message = <FH>;
close(FH);

$msg = MIME::Lite->new(
	From    => $from,
	To      => $to,
	Cc      => $cc,
	Subject => $subject,
	Data    => @message
);

$msg->send;
print "Email Sent Successfully\n";
