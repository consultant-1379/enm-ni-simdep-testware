#!/usr/bin/perl -w
use strict;
use Getopt::Long();
use Parallel::ForkManager;

###################################################################################
#     File Name   : startSims.pl
#     Version     : 2016_04_16
#     Author      : Fatih ONUR
#     Description : See usage.
###################################################################################
#
#----------------------------------------------------------------------------------
#Variables
#----------------------------------------------------------------------------------
my $NETSIM_INSTALL_SHELL = "/netsim/inst/netsim_pipe";
my $NETSIM_DIR = "/netsim/netsimdir";

#
#----------------------------------------------------------------------------------
#Check if the scrip is executed as netsim user
#----------------------------------------------------------------------------------
#
my $user = `whoami`;
chomp($user);
my $expUser = 'netsim';
if ( $user ne $expUser ) {
    print "ERROR: Not $expUser user. Please execute the script as $expUser user\n";
    exit(201);
}

#
#----------------------------------------------------------------------------------
#Check if the script usage is right
#----------------------------------------------------------------------------------
my $USAGE =<<USAGE;
Descr: Start nodes. By default, one node of regexp matched sim started.
  Usage:
    $0 -simName [<regExp>] [-numOfNes <number>] [-numOfIpv6Nes <number>] [-all] [-stop]

    where:
      -e|-regexp         : Specifies regexp pattern for simulation types matching. Otherwise all sims selected.
      -c|-numOfNes       : Specifies number of nodes to be started from the first node to the end
      -n|-numOfIpv6Nes   : Specifies number of IPV6 nodes to be started
      -a|-all            : A flag to start all nodes. Should be used with -regexp. Default (false)
      -o|-one            : A flag to start a node at a time. Should be used with -regexp.
      -h|-help           : A flag to show help menu.
      -s|-stop           : A flag to stop all sims. Should be used with -regexp. Default (false)
      -m|-msg            : A flag to display container specific msg to keep conatiner alive. Default (true)

     usage examples: outside container
       $0 -regExp CORE-ST-4.5K-SGSN-16A-CP01-V1x5 --all
       $0 -regExp "LTE|CORE" -numOfNes 5 -numOfIpv6Nes 1
       $0 -e "SGSN.*CP01|LTE.*DG2" -a -o
       $0 -e "SGSN.*CP01|LTE.*DG2" -stop
       $0 -e "" -stop # Stop all sims

     usage examples: inside container
       $0 -nom -e "" -stop # Stop all sims
       $0 -nom -e "SGSN.*CP01|LTE.*DG2" -a -o

     dependencies:
       1. Simulations must be already rolled in the netsim server.

     Return Values: 201 -> Not a netsim user.
                    202 -> Usage is incorrect.
                    207 -> Failed to execute system command.

     Dies: If cannot fork.
USAGE

my $ERROR=<<ERROR;
Try "startNodes.pl -h" for more information.
ERROR

my $regExp;
my $numOfNes = 1;
my $numOfIpv6Nes = 0;
my $all = ''; # default value (false)
my $one = ''; # default value (false)
my $stop= ''; # default value (false)
my $msg= '1'; # default value (true)
my $help = ''; # default value (false)
my @PRINT_ARGV = @ARGV;


Getopt::Long::GetOptions(
    'regExp|e=s' => \$regExp,
    'numOfNes|c=i' => \$numOfNes,
    'numOfIpv6Nes|n=i' => \$numOfIpv6Nes,
    'all|a' => \$all,
    'one|o' => \$one,
    'stop|s' => \$stop,
    'msg|m!' => \$msg,
    'help|h' => \$help,
) or die("ERROR: Invalid commmand line options\n$ERROR");
if ($help ne '' || (($#PRINT_ARGV + 1) < 1)){print $USAGE; exit -1;}
if (not defined $regExp){print ("ERROR: Regexp has to be given \n$ERROR"); exit -1;}
print "RUNNING: $0 @PRINT_ARGV \n";
print "regExp:$regExp\n" unless $regExp eq "";
print "numOfNes:$numOfNes\n" unless $numOfNes eq 0;
print "numOfIpv6Nes:$numOfIpv6Nes\n" unless $numOfIpv6Nes eq 0;

sub fork_child {
    my ($child_process_code) = @_;

    my $pid = fork;
    die "Failed to fork: $!\n" if !defined $pid;

    return $pid if $pid != 0;

# Now we're in the new child process
    $child_process_code->();
    exit;
}
#----------------------------------------------------------------------------------
#Start node related subroutines
#----------------------------------------------------------------------------------

sub startSims() {
    print "INFO: Started submodule: startSims()\n";
    my ($regex, $numOfNes, $numofIpv6Nes, $all) = @_;

    my $cmdSims="cd /netsim/netsimdir/ && \
        echo [[:alnum:]]*[!.zip] | xargs -n 1 | grep -v '^[a-z]' | \
        perl -lne \'print if!/^Re|^Se/i\' | (egrep -i \"$regex\" || true)";

    my $runRef = \&run;
    my %pids = ();
    my @sims = `$cmdSims`;
        print "****************Selected sims @sims\n************************";
	my $manager = Parallel::ForkManager->new( 10 );
    foreach my $sim (@sims){
        chomp($sim);
		my $pid = $manager->start and next;
        print "sim=$sim\n";
            my @params = ();
            push @params, "--numOfNes=$numOfNes";
            push @params, "--numOfIpv6Nes=$numOfIpv6Nes" unless $numOfIpv6Nes eq 0;
            push @params, "--all" if $all ;
			exec '/netsim/docker/startNes.pl', "--sim=$sim", @params
                or die "Failed to exec startSims: $!\n";
				
			$pids{$pid} = $sim;	
			$manager->finish;
	}
	
        while (keys %pids) {
         my $pid = waitpid -1, 0;
          warn "Failed to start $pids{$pid}\n" if $? != 0;
         delete $pids{$pid};
      }
        
		 

    
    
    print "INFO: Ended submodule: startSims()\n";
}

sub stopSims(){
    print "INFO: Started submodule: stopSims()\n";
    my ($regex) = @_;

    my $cmdSims="cd /netsim/netsimdir/ && \
        echo [[:upper:]]*[!.zip] | xargs -n 1 | \
        perl -lne \'print if!/^Re|^Se|up|Eric/i\' | (egrep -i \"$regex\" || true)";

    my %pids = ();
    my @sims = `$cmdSims`;
    foreach my $sim (@sims){
    chomp($sim);
    # print "sim=$sim\n";
    my $pid = fork_child(sub {
        # echo .open sim\n.select network\n.stop -parallel
        exec 'echo -e ".open ' . $sim . '\n.select network\n.stop -parallel" | /netsim/inst/netsim_shell'
        or die "Failed to exec startSims: $!\n";
    });
        $pids{$pid} = $sim;
    }

    while (keys %pids) {
        my $pid = waitpid -1, 0;
        warn "Failed to stop $pids{$pid}\n" if $? != 0;
        delete $pids{$pid};
    }
print "INFO: Ended submodule: stopSims()\n";
}

#----------------------------------------------------------------------------------
# Main
#----------------------------------------------------------------------------------
&startSims($regExp, $numOfNes, $numOfIpv6Nes, $all) if not $stop;
&stopSims($regExp) if $stop;

if($msg) {
    print "\n";
    print "INFO: [press Ctrl+C to exit] or run 'docker stop <container>'\n";
    system("tail -f /dev/null");
    print "INFO: stopping netsim \n";
    print "INFO: exited $0 \n";
}



