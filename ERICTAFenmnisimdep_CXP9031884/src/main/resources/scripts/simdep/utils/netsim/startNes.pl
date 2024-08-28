#!/usr/bin/perl -w
use strict;
use Config::Tiny;
use Getopt::Long();
use Cwd 'abs_path';

###################################################################################
#     File Name   : startNes.pl
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
my @simDepPath = split( /startNes\.pl/, abs_path($0) );
my $simDepPath = $simDepPath[0];
chomp($simDepPath);
my $contentFile = `ls /netsim/simdepContents | grep content`;
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
Descr: Start nodes, set load balancing, remove security, set netsim user.
  Usage:
    $0 -simName <simName> [-numOfNes <number>] [-numOfIpv6Nes <number>] [--all] [[-neTypesFull <neTypeArr>] [-deploymentType <deploymentType>]]

    where:
      -s|-simName        : Specifies simulation name. Mandatory.
      -c|-numOfNes       : Specifies number of nodes to be started from the first node to the end
      -n|-numOfIpv6Nes   : Specifies number of IPV6 nodes to be started
      -l|-neTypesFull    : Sets load balancing for given ne types. Single as stand alone or multiple separated by ":"
      -d|-deploymentType : Optional: To be used with -l|neTypesFull while setting load balancing only.
                           Specifies deploymentType of the network. Possible values are mediumDeployment and largeDeployment.
      -r|-removeSec      : Specifis security type to be removed.
      -u|-setNetsimUser  : A flag to set netsim user for SGSN nodes. Default (true)
      -a|-all            : A flag to start all nodes. Default (false)
      -o|-one            : A flag to start a node at a time.
      -h|-help           : A flag to show help menu.
      -t|-setTacacs      : A flag to set tacacs support for MINILINK and Juniper nodes. Default (true)
      -f|-setRadius      : A flag to set radius support for FrontHaul 6020 and FrontHaul 6650 nodes.Default (true)

     usage examples:
       $0 -simName LTE16B-V8x160-5K-DG2-FDD-LTE07
       $0 -simName LTE16B-V8x160-5K-DG2-FDD-LTE07 -numOfNes 5 -numOfIpv6Nes 1
       $0 -simName LTE16B-V8x160-5K-DG2-FDD-LTE07 -numOfNes 5 -numOfIpv6Nes 1 -neTypesFull "LTE MSRBS-V2 16B-V6:LTE MSRBS-V2 15B-V13"
       $0 -simName LTE16B-V8x160-5K-DG2-FDD-LTE07 -l "LTE MSRBS-V2 16B-V6" -a -o
       $0 -simName LTE16B-V8x160-5K-DG2-FDD-LTE07 -r TLS -nou -deploymentType largeDeployment
       $0 -simName LTE16B-V8x160-5K-DG2-FDD-LTE07 -neTypesFull "LTE MSRBS-V2 16B-V6" -deploymentType mediumDeployment

     dependencies:
       1. Simulations must be already rolled in the netsim server.

     Return Values: 201 -> Not a netsim user.
                    202 -> Usage is incorrect.
                    207 -> Failed to execute system command.
USAGE

my $ERROR=<<ERROR;
Try "startNodes.pl -h" for more information.
ERROR

my $simName;
my $numOfNes = 0;
my $numOfIpv6Nes = 0;
my $neTypesFull = '';
my $removeSec = '';
my $setNetsimUser = 1; # default value (true)
my $setTacacs = 1; #default value (true)
my $setRadius = 1; #default value (true)
my $all = ''; # default value (false)
my $one = ''; # default value (false)
my $help = ''; # default value (false)
my @PRINT_ARGV = @ARGV;
my $deploymentType = 'mediumDeployment';
my $docker = 'docker';
my $switchToRv = 'NO';


#------------------------------------------
# Config file params
#------------------------------------------
#if (index(lc($simDepPath), lc($docker)) != -1) {
#    print "$simDepPath contains $docker\n";
#}
#else {
#my $CONFIG_FILE  = "conf.txt";
#my $CONFIG_FILE_PATH ="$simDepPath/../../conf/$CONFIG_FILE";
#my $Config = Config::Tiny->new;
#$Config = Config::Tiny->read($CONFIG_FILE_PATH);
#$switchToRv = $Config->{_}->{SWITCH_TO_RV};
#}
# Reading properties
print "INFO: SWITCH_TO_RV: ". uc($switchToRv) . "\n";


Getopt::Long::GetOptions(
    'simName|s=s' => \$simName,
    'numOfNes|c=i' => \$numOfNes,
    'numOfIpv6Nes|n=i' => \$numOfIpv6Nes,
    'neTypesFull|l=s' => \$neTypesFull,
    'removeSec|r=s' => \$removeSec,
    'setNetsimUser|u=s' => \$setNetsimUser,
    'setTacacs|t=s' => \$setTacacs,
    'setRadius|f=s' => \$setRadius,
    'all|a' => \$all,
    'one|o' => \$one,
    'help|h' => \$help,
    'deploymentType|d=s' => \$deploymentType,
    'switchToRv|rv=s' => \$switchToRv
) or die("ERROR: Invalid commmand line options\n$ERROR");
if ($help){print $USAGE; exit -1;}
if (not defined $simName){print ("ERROR: Sim name has to be given \n$ERROR"); exit -1;}
print "RUNNING: $0 @PRINT_ARGV \n";

substr $simName, index($simName, ".zip"), 4,"" if "$simName" =~ /\.zip/;
print "simName:$simName \n";
print "numOfNes:$numOfNes\n" unless $numOfNes eq 0;
print "numOfIpv6Nes:$numOfIpv6Nes\n" unless $numOfIpv6Nes eq 0;
print "neTypesFull:$neTypesFull\n" unless length $neTypesFull eq 0;
print "removeSec:$removeSec\n" unless length $removeSec eq 0;
print "setNetsimUser:true \n" if $setNetsimUser;
print "setTacacs:true \n" if $setTacacs;
print "deploymentType:$deploymentType \n";
print "switchToRV:$switchToRv \n";

#----------------------------------------------------------------------------------
#Set user as a netsim for SGSN sims
#----------------------------------------------------------------------------------
sub setNetsimUser {
    my ($simName, $neType) = @_;
    my $MML = '';
    if ($simName=~ m/SGSN/i) {
        print "==simName:$simName \n";
        $MML=<<MML;
.open $simName
.select network
.stop -parallel
.setuser netsim netsim
.set save
MML
    }
    if (($simName=~ m/BSC/i || $simName=~ m/MSC/i ) && ($simName !~ m/vBSC/)) {
        print "==simName:$simName \n";
my $cmd = "echo -e '.open '$simName'\n.show simnes\n'|~/inst/netsim_shell | grep -i 'LTE BSC' | cut -d ' ' -f1 | tr '\n' ' '";
my $nodeName = `$cmd`;
        $MML=<<MML;
.open $simName
.select $nodeName
.stop -parallel
.setuser LocalCOMUser LocalCOMUser
.set save
MML
    }
    if ($simName =~ m/Yang/i) {
        if($neType =~ m/PCG/i || $neType =~ m/PCC/i || $neType =~ m/CCDM/i || $neType =~ m/CCES/i  || $neType =~ m/CCRC/i || $neType =~ m/CCSM/i || $neType =~ m/CCPC/i || $neType =~ m/LTE SC/i || $neType =~ m/WMG-OI/i || $neType =~ m/vWMG-OI/i || $neType =~ m/vDU/i || $neType =~ m/vCU-CP/i || $neType =~ m/vCU-UP/i || $neType =~ m/SMSF/i || $neType =~ m/EPG-OI/i || $neType =~ m/vEPG-OI/i || $neType =~ m/GenericADP/i || $neType =~ m/Shared-CNF/i || $neType =~ m/cIMS/i || $neType =~ m/RDM/i) {
 print "==simName:$simName \n";
        $MML=<<MML;
.open $simName
.select network
.stop -parallel
.setuser netsim netsim
.set save
MML
     }
     }

   elsif ($simName =~ m/SCEF/i || $simName =~ m/5G112/i || $simName =~ m/CORE127/i || $simName =~ m/CORE129/i || $simName =~ m/5G113/i || $simName =~ m/5G114/i || $simName =~ m/5G115/i || $simName =~ m/5G116/i || $simName =~ m/5G117/i || $simName =~ m/5G118/i || $simName =~ m/5G127/i || $simName =~ m/CORE119/i || $simName =~ m/CORE120/i || $simName =~ m/CORE125/i || $simName =~ m/5G129/i || $neType =~ m/SMSF 1-0-V1/i || $neType =~ m/CCDM 1-3-1-V1/i || $neType =~ m/CCDM 1-3-1-RI-V1/i || $neType =~ m/CCDM 1-3-1-RI-V2/i || $neType =~ m/CCDM 1-0-V1/i || $neType =~ m/CCES 1-0-V1/i || $neType =~ m/CCRC 1-0-V1/i || $neType =~ m/CCPC 1-0-V1/i || $neType =~ m/CCSM 1-0-V1/i || $neType =~ m/PCG/i || $neType =~ m/vDU 1-0-DY-V1/i   || $neType =~ m/LTE SC 1-0-V1/i || $neType =~ m/EPG-OI 3-4-DY-V1/i || $neType =~ m/EPG-OI/i || $neType =~ m/EPG-OI 3-5-DY-V3/i || $neType =~ m/vEPG-OI 3-13-V1/i || $neType =~ m/CCPC 1-0-V1/i || $neType =~ m/CCDM 1-0-V2/i || $neType =~ m/CCES 1-0-V2/i || $neType =~ m/CCRC 1-0-V2/i || $neType =~ m/CCSM 1-0-V2/i || $neType =~ m/PCG 1-0-V2/i || $neType =~ m/vDU 1-0-DY-V2/i || $neType =~ m/vDU 0-7-4-DY-V1/i || $neType =~ m/vDU 0-10-1-DY-V1/i  || $neType =~ m/LTE SC 1-0-V2/i || $neType =~ "WMG-OI 2-3-V1" || $neType =~ "vWMG-OI 2-3-V1" || $neType =~ "WMG-OI 2-3-V2" || $neType =~ "vWMG-OI 2-3-V2" || $neType =~ m/EPG-OI 3-4-DY-V2/i || $neType =~ m/EPG-OI 3-5-DY-V2/i || $neType =~ "vCU-CP 1-0-V1" || $neType =~ "vCU-UP 1-0-V1" || $neType =~ "vCU-CP 0-5-1-V1" || $neType =~ " vCU-UP 0-6-1-V1" || $simName =~ m/5G130/i || $simName =~ m/5G131/i || $neType =~ "WMG-OI 2-5-V1" || $neType =~ "vWMG-OI 2-5-V1" || $neType =~ m/PCC 1-9-V1/i || $simName =~ m/5G132/i || $neType =~ "vCU-CP 0-1-6-V1" || $neType =~ "vCU-UP 0-3-1-V1" || $neType =~ "vDU 0-11-1-DY-V1" || $neType =~ "vWMG-OI 2-6-V1"  || $neType =~ "vDU 0-12-3-V1" || $neType =~ "GenericADP 1-0-V1" || $simName =~ m/5G133/i || $simName =~ m/5G134/i || $neType =~ m/EPG-OI 3-4-DY-V3/i || $neType =~ m/EPG-OI 3-5-DY-V4/i || $neType =~ m/vEPG-OI 3-5-DY-V2/i || $neType =~ m/vEPG-OI 3-4-DY-V1/i || $simName =~ m/CORE135/i || $simName =~ m/CORE126/i || $neType =~ "vDU 0-12-3-DY-V1"  ) {
        print "==simName:$simName \n";
        $MML=<<MML;
.open $simName
.select network
.stop -parallel
.setuser netsim netsim
.set save
MML
    }
    return $MML;
}
#---------------------------------------------------------------------------------
#Tacacs support for Minilink and juniper nodes
#---------------------------------------------------------------------------------
sub setTacacsSupport {
my $simName = $_[0];
    my $MML = '';
    print "==simName:$simName \n";
    if ( ( $simName =~ m/ML/i || $simName =~ m/FrontHaul-6392/i || $simName =~ m/Switch6391/i || $simName =~ m/JUNIPER/i ) && $simName !~ m/EPG-JUNIPER/i ) {
    # if ($simName =~ m/ML6352/i || $simName =~ m/ML6351/i || $simName =~ m/Switch6391/i || $simName =~ m/FrontHaul-6392/i || $simName =~ m/MLPT2020/i || $simName =~ m/MLPT-2020/i ) {
            my $output = `echo -e '.open '$simName'\n.select network\n.start -parallel\ntacacs_server:operation="view";\n' | /netsim/inst/netsim_shell | grep -vE 'OK|>>'`;
            if ( $output =~ m/No Tacacs Users set on node/i && $contentFile =~ m/Simnet_1_8K_CXP9034760/i ) {
                 $MML=<<MML;
.open $simName
.select network
tacacs_server:operation="add",user="centralized_system_administrator",pwd="TestPassw0rd",user="centralized_administrator",pwd="TestPassw0rd",user="centralized_operator",pwd="TestPassw0rd";
tacacs_server:operation="view";
.stop -parallel
MML
            }
            elsif ( $output =~ m/No Tacacs Users set on node/i ) {
                 $MML=<<MML;
.open $simName
.select network
tacacs_server:operation="add",user="centralized_system_administrator",pwd="TestPassw0rd",user="centralized_administrator",pwd="TestPassw0rd",user="centralized_operator",pwd="TestPassw0rd";
tacacs_server:operation="view";
MML
            }
            else {
                 if ( $contentFile =~ m/Simnet_1_8K_CXP9034760/i ) {
                       $MML=<<MML;
.open $simName
.select network
tacacs_server:operation="view";
.stop -parallel
MML
                 }
                 else {
                       $MML=<<MML;
.open $simName
.select network
tacacs_server:operation="view";
MML
                 }
             }
  }
     return $MML;
}
#---------------------------------------------------------------------------------
# Radius support for FrontHaul 6020 nodes and FrontHaul 6650 nodes
# --------------------------------------------------------------------------------
sub setRadiusSupport {
my $simName = $_[0];
    my $MML = '';
    print "==simName:$simName \n";
     if ( ( $simName =~ m/FrontHaul-6020/i || $simName =~ m/FrontHaul-6650/i ) ) {
         my $output = `echo -e '.open '$simName'\n.select network\n.start -parallel\nradius_server_user:operation="view";\n' | /netsim/inst/netsim_shell | grep -vE 'OK|>>'`;
         if ( $output =~ m/No Radius Users set on node/i && $contentFile =~ m/Simnet_1_8K_CXP9034760/i ) {
              $MML=<<MML;
.open $simName
.select network
radius_server_user:operation="add",user="RadAdmin",pwd="RadAdmin\@12345",user="Admin123",pwd="Admin\@12345";
radius_server_user:operation="view";
.stop -parallel
MML
         }
         elsif ( $output =~ m/No Radius Users set on node/i ) {
               $MML=<<MML;
.open $simName
.select network
radius_server_user:operation="add",user="RadAdmin",pwd="RadAdmin\@12345",user="Admin123",pwd="Admin\@12345";
radius_server_user:operation="view";
MML
         }
         else {
               if ( $contentFile =~ m/Simnet_1_8K_CXP9034760/i ) {
                   $MML=<<MML;
.open $simName
.select network
radius_server_user:operation="view";
.stop -parallel
MML
               }
               else {
               $MML=<<MML;
.open $simName
.select network
radius_server_user:operation="view";
MML
               }
          }
      }
return $MML
}
          
#---------------------------------------------------------------------------------
#generating Backup files for MSC BSC nodes
#---------------------------------------------------------------------------------
sub generateBackUpFiles {
         my $MML = '';
         print "Generating backup files for MSC BSC nodes\n";
my $cmd = "echo -e '.showapgbackup -netype MSC-S-SPX \n' | ~/inst/netsim_shell | grep -v '>>'";
my $check = `$cmd`;
if ($check =~ m/Backup not/i) {
    if (lc "$switchToRv" eq lc "yes") {
 $MML=<<MML;
.generateapgbackup -netype BSC buinfo 2.3K ldd1 675.85M ps 140.9M rs 15.4M sdd 8.1M
.generateapgbackup -netype MSC-BC-IS buinfo 1M ldd1 716M ps 135M rs 15M
.generateapgbackup -netype MSC-S-SPX buinfo 1.2K ldd1 343M ps 141M rs 15.5M sdd 144.9M
MML
    }
    else {
$MML=<<MML;
.generateapgbackup -netype BSC buinfo 1M ldd1 1M ps 1M rs 1M sdd 1M
.generateapgbackup -netype MSC-BC-IS buinfo 1M ldd1 1M ps 1M rs 1M
.generateapgbackup -netype MSC-S-SPX buinfo 1M ldd1 1M ps 1M rs 1M sdd 1M
MML
    }
}
else {
print "backup files for MSC and BSC nodes are already present\n";
$MML=<<MML;
.showapgbackup -netype BSC
.showapgbackup -netype MSC-BC-IS
.showapgbackup -netype MSC-S-SPX
MML
}
         return $MML;
}
#----------------------------------------------------------------------------------
#Removes exisiting security definitions if any
#----------------------------------------------------------------------------------
sub removeSecurity {
    my ($simName, $secType) = @_;

    my $MML = '';
    if (-d "/netsim/netsimdir/$simName/security") {
        my @existingSecurityDefinitions = `ls /netsim/netsimdir/$simName/security`;
        foreach my $existingSecurityDefinition (@existingSecurityDefinitions) {
            chomp($existingSecurityDefinition);
            if ( $existingSecurityDefinition =~ /$secType/i ) {
                $MML=<<MML;
.open $simName
.select network
.stop -parallel
.set ssliop no $existingSecurityDefinition
.set save
.setssliop delete /netsim/netsimdir/$simName $existingSecurityDefinition
MML
           }
        }
    }
    return $MML;
}

#----------------------------------------------------------------------------------
#Loads balancing setting
#----------------------------------------------------------------------------------
sub setLoadBalancing {
    my ($simName, $neTypesFull) = @_;
    my @mmlArr = ();

    #--------------------------------------------------------------------------------
    # Creating ne type array and map
    #--------------------------------------------------------------------------------
    my @neTypesFullArr = split(/:/, $neTypesFull);
    my %neTypesFullMap =  map { $_ => 1 } @neTypesFullArr;

    #print Dumper(\@neTypesFullArr);
    #print Dumper(\%neTypesFullMap);

    foreach my $neTypeFull (keys %neTypesFullMap) {
        push  @mmlArr, ".show serverloadconfig";

        #--------------------------------------------------------------------------------
        # Get neType in simple format. From "LTE MSRBS-V2 16B-V6" to "MSRBS-V2 16B-V6"
        #--------------------------------------------------------------------------------
        my @neTypeFullPieces = split( / / , $neTypeFull );
        my $neTypeName = join(' ', @neTypeFullPieces[1..2]);
        chomp($neTypeName);
        print "setLoadBalancing_neTypeName:$neTypeName\n";
        if($neTypeName =~ m/MSRBS-V2/i && lc "$switchToRv" eq lc "yes" && "$simName" =~ m/GSM/i ) {
            push @mmlArr, ".set nodeserverload $neTypeName 5";
        }
        elsif($neTypeName =~ m/MSRBS-V2/i && lc "$switchToRv" eq lc "yes" && "$simName" =~ /^((?!RNC).)*$/i ) {
            push @mmlArr, ".set nodeserverload $neTypeName 2";
        }
        elsif($neTypeName =~ m/ERBS/i && lc "$switchToRv" eq lc "yes") {
            push @mmlArr, ".set nodeserverload $neTypeName 3";
        }
        elsif ($neTypeName =~ m/ERBS/i || $neTypeName =~ m/VTIF/i) {
            push @mmlArr, ".set nodeserverload $neTypeName 4";
        }
        elsif ($neTypeName =~ m/PRBS/i || $neTypeName =~ m/PICO/i || $neTypeName =~ m/MSRBS-V1/i) {
            push @mmlArr, ".set nodeserverload $neTypeName 12";
        }
        elsif ($neTypeName=~ m/MSRBS-V2/i) {
            push @mmlArr, ".set nodeserverload $neTypeName 4";
        }
        elsif ($neTypeName=~ m/VTFRadioNode/i) {
            push @mmlArr, ".set nodeserverload $neTypeName 10";
        }
        elsif ($neTypeName =~ m/RBS/i && lc "$switchToRv" eq lc "yes") {
            push @mmlArr, ".set nodeserverload $neTypeName 4";
        }
	elsif ($neTypeName =~ m/O1/i ) {
            push @mmlArr, ".set nodeserverload $neTypeName 4";
        }
        elsif ($neTypeName =~ m/RBS/i) {
            push @mmlArr, ".set nodeserverload $neTypeName 4";
        }
        elsif ($neTypeName =~ m/RNC/i) {
            push @mmlArr, ".set nodeserverload $neTypeName 1";
        }
        elsif ($neTypeName=~ m/SGSN/i && lc "$switchToRv" eq lc "yes") {
            push @mmlArr, ".set nodeserverload $neTypeName 1";
        }
        elsif ($neTypeName=~ m/SGSN/i && lc "$deploymentType" eq lc "mediumDeployment") {
            push @mmlArr, ".set nodeserverload $neTypeName 4";
        }
        elsif ($neTypeName =~ m/MGw/i && lc "$switchToRv" eq lc "yes") {
            push @mmlArr, ".set nodeserverload $neTypeName 6";
        }
        elsif ($neTypeName =~ m/MGw/i) {
            push @mmlArr, ".set nodeserverload $neTypeName 10";
        }
        elsif ( $neTypeName =~ m/vCU-UP/i) {
            if ( $simName =~ m/Scale-20K/i ) {
               push @mmlArr, ".set nodeserverload $neTypeName 4";
            }
            elsif ( $simName =~ m/Scale-30K/i ) {
               push @mmlArr, ".set nodeserverload $neTypeName 2";
            }
        }
        elsif ( $neTypeName =~ m/vCU-CP/i) {
            if ( $simName =~ m/Scale-60K/i ) {
               push @mmlArr, ".set nodeserverload $neTypeName 2";
            }
            elsif ( $simName =~ m/Scale-100K/i ) {
               push @mmlArr, ".set nodeserverload $neTypeName 1";
            }
        }
        elsif ( ($neTypeName =~ m/PCG/i || $neTypeName =~ m/EPG-OI/i) && ( lc "$switchToRv" eq lc "yes") ) {
            push @mmlArr, ".set nodeserverload $neTypeName 1";
        }
        elsif ($neTypeName =~ m/EPG/i && lc "$switchToRv" eq lc "yes") {
            push @mmlArr, ".set nodeserverload $neTypeName 1";
        }
        elsif ($neTypeName =~ m/MTAS/i && lc "$switchToRv" eq lc "yes") {
            push @mmlArr, ".set nodeserverload $neTypeName 2";
        }
        elsif ($neTypeName =~ m/SpitFire/i && lc "$switchToRv" eq lc "yes") {
            push @mmlArr, ".set nodeserverload $neTypeName 10";
        }
        elsif ($neTypeName =~ m/CISCO/i && lc "$switchToRv" eq lc "yes") {
            push @mmlArr, ".set nodeserverload $neTypeName 4";
        }
        elsif ($neTypeName =~ m/ML/i && lc "$switchToRv" eq lc "yes" && lc "$deploymentType" eq lc "smallDeployment") {
            push @mmlArr, ".set nodeserverload $neTypeName 1";
        }
        elsif ($neTypeName =~ m/ML/i && lc "$switchToRv" eq lc "yes") {
            if ($neTypeName =~ m/ML-TN/i || $neTypeName =~ m/ML 6691/i) {
            push @mmlArr, ".set nodeserverload $neTypeName 2";
               }
               else {
             push @mmlArr, ".set nodeserverload $neTypeName 4";
               }
           }
        elsif ($neTypeName =~ m/FrontHaul/i && lc "$switchToRv" eq lc "yes") {
            push @mmlArr, ".set nodeserverload $neTypeName 15";
        }
        elsif ($neTypeName =~ m/TCU04/i && lc "$switchToRv" eq lc "yes") {
            push @mmlArr, ".set nodeserverload $neTypeName 15";
        }
        elsif ($neTypeName =~ m/TCU02/i && lc "$switchToRv" eq lc "yes") {
            push @mmlArr, ".set nodeserverload $neTypeName 4";
        }
        elsif ($neTypeName =~ m/JUNIPER/i && lc "$switchToRv" eq lc "yes") {
            push @mmlArr, ".set nodeserverload $neTypeName 1";
        }
        elsif ($neTypeName =~ m/SIU02/i && lc "$switchToRv" eq lc "yes") {
            push @mmlArr, ".set nodeserverload $neTypeName 4";
        }
        elsif (($neTypeName =~ m/BSC/i && $neTypeName !~ m/APG43L/i) && lc "$switchToRv" eq lc "yes") {
            push @mmlArr, ".set nodeserverload $neTypeName 1";
        }
        elsif (($neTypeName =~ m/MSC/i && $neTypeName !~ m/APG43L/i) && lc "$switchToRv" eq lc "yes") {
            push @mmlArr, ".set nodeserverload $neTypeName 1";
        }
        
        elsif (($neTypeName =~ m/HDS/i) && lc "$switchToRv" eq lc "yes") {
            push @mmlArr, ".set nodeserverload $neTypeName 1";
        }
        elsif ($neTypeName =~ m/HSS-FE/i && lc "$switchToRv" eq lc "yes") {
            push @mmlArr, ".set nodeserverload $neTypeName 4";
        }
        elsif ($neTypeName =~ m/vDU/i && lc "$switchToRv" eq lc "yes") {
            push @mmlArr, ".set nodeserverload $neTypeName 4";
        }
        elsif ($neTypeName =~ m/SCEF/i && lc "$switchToRv" eq lc "yes") {
            push @mmlArr, ".set nodeserverload $neTypeName 4";
        }
        elsif ($neTypeName =~ m/vDU/i && lc "$switchToRv" eq lc "yes") {
            push @mmlArr, ".set nodeserverload $neTypeName 4";
        }
        elsif ($neTypeName =~ m/vCU-CP/i && lc "$switchToRv" eq lc "yes") {
            push @mmlArr, ".set nodeserverload $neTypeName 1";
        }
        elsif ($neTypeName =~ m/vCU-UP/i && lc "$switchToRv" eq lc "yes") {
            push @mmlArr, ".set nodeserverload $neTypeName 1";
        }

       
    }
    return join("\n",@mmlArr) . "\n"; # return all lines in a separate line
}

#----------------------------------------------------------------------------------
#Start node related subroutines
#----------------------------------------------------------------------------------
sub startNesTemplate() {
    my ($simName, $selectedNes, $selectedNesIpv6) = @_;

    my $startOption = '';
    if ( $one ) {
        $startOption = $startOption . ".start";
    } elsif ( $simName =~ m/NR22-Q2-V3/i || $simName =~ m/LTE22-Q2-V3/i || $simName =~ m/NR22-Q1-V4/i || $simName =~ m/LTE22-Q1-V4/i || $simName =~ m/BSC_22-Q1_V4/i ) {
        $startOption = $startOption . ".start";
    } elsif ( $simName =~ m/SGSN/i || $simName =~ m/MSRBS/i || $simName =~ m/EPG/i ) {
        $startOption = $startOption . ".start";
    } elsif ( $simName =~ m/DG2/i ) {
        $startOption = $startOption . ".start";
    } elsif ( $simName =~ m/LTE/i || $simName =~ m/MGW/i ) {
        $startOption = $startOption . ".start";
    } else {
        $startOption = $startOption . ".start";
    }

    my $MML=<<MML;
.open $simName
.select $selectedNes $selectedNesIpv6
$startOption
MML
    return $MML;
}

sub startNumOfNes(){
    my ($simName, $numOfNes, $numOfIpv6Nes) = @_;

    print "INFO: Starting numOfNes:" . ($numOfNes + $numOfIpv6Nes) . " on $simName \n";

    my $netsimDir = "/netsim/netsim_dbdir/simdir/netsim/netsimdir/";
    my $filePath = $netsimDir . "$simName";
    opendir  (DIR, $filePath) || die "Can't open directory $filePath: $!";
    my @nes = sort grep { (!/^\./) &&  "$filePath/$_" } readdir(DIR);
    my $numOfExistentNes = @nes;
    closedir DIR;

    my $selectedNes = '';
    my ( $selectedNesIpv6 , $numOfExistentipV6nes ) = &getIpv6Nodes($simName, $numOfIpv6Nes);
       if ($numOfExistentNes <= $numOfNes) {
        if ( $selectedNesIpv6 ne '' ) {
            $numOfNes = $numOfExistentNes - $numOfExistentipV6nes;
        } else {
            $numOfNes = $numOfExistentNes;
        }
    }
    for ( my $i = 0; $i < $numOfNes; $i++ ) {
        $selectedNes = $selectedNes . "$nes[$i] ";
    }
    if ( "$selectedNes $selectedNesIpv6" ne ' ' ) {
        return &startNesTemplate($simName, $selectedNes, $selectedNesIpv6);
    } else {
        print "INFO: No nodes found for selected option! ($simName)\n";
        return "";
    }

}

sub startAllNes() {
    my ($simName) = @_;
    my $selectedNes = "network";
    my $selectedNesIpv6 = "";
    return &startNesTemplate($simName, $selectedNes, $selectedNesIpv6);
}

#---------------------------------------------------------------------------------
#subroutine to get ipv6 nodes
#---------------------------------------------------------------------------------
sub getIpv6Nodes {
    my ($simName, $numOfIpv6Nes) = @_;
    my $selectedNesIpv6 = "";
    return $selectedNesIpv6 if ($numOfIpv6Nes < 1);

    my $simNesIpv6=`echo -e ".open $simName\n .show simnes" | /netsim/inst/netsim_shell | grep "::" | sort | awk -F" " '{print \$1}'`;
    my @simNesIpv6Arr= split "\n", $simNesIpv6;
    my $maxNumOfIpv6Nes = scalar @simNesIpv6Arr;
    $numOfIpv6Nes = $maxNumOfIpv6Nes if ( $numOfIpv6Nes > $maxNumOfIpv6Nes);
    for(my $i=0; $i < $numOfIpv6Nes; $i++){
       $selectedNesIpv6.="$simNesIpv6Arr[$i] ";
    }
    return ( $selectedNesIpv6 , $maxNumOfIpv6Nes );
}

sub mySystem(@)
{
    my $pid = open(KID, '-|');
    die "fork: $!" unless defined($pid);
    if ($pid) {
        my $output;
        while (<KID>) {
            print STDOUT $_;
            $output .= $_; # could be improved...
        }
        close(KID);
        return $output;
    } else {
        exec @_;
    }
}


#----------------------------------------------------------------------------------
#Define NETSim MO file and Open file in append mode
#----------------------------------------------------------------------------------
my $cmd = "ls /netsim/netsimdir | grep -E 'BSC|MSC|GSM' | wc -l";
my $cmd1 = "echo -e '.show simulations\n' | /netsim/inst/netsim_shell | grep -E 'ML|Switch6391|FrontHaul-6392|JUNIPER' | grep -v 'EPG-JUNIPER' | wc -l";
my $generateBackUp = `$cmd`;
my $TacacsSupport = `$cmd1`;
my $MML_MML = "/var/${simName}_start.mml";
my $Tacacs_MML = "/var/Tacacs_$simName.mml";

if (index(lc($simDepPath), lc($docker)) != -1) {
    print "$simDepPath contains $docker\n";
    $MML_MML = "${simName}." . time() . "_" . rand() . ".mml";
    $Tacacs_MML = "${simName}.Tacacs." . time() . "_" . rand() . ".mml";
}

open MML, "+>>$MML_MML";

if (defined $neTypesFull and length $neTypesFull gt 0) {
   print MML &setLoadBalancing($simName, $neTypesFull);
}

if (defined $removeSec and length $removeSec gt 0) {
    print MML &removeSecurity($simName,$removeSec);
}

if ($setNetsimUser) {
    print MML &setNetsimUser($simName,$neTypesFull);
}

if ($generateBackUp > 0) {
    print MML &generateBackUpFiles();
}

if (defined $numOfNes and ( $numOfNes gt 0 || $numOfIpv6Nes gt 0) ) {
    print MML &startNumOfNes($simName, $numOfNes, $numOfIpv6Nes);
}

if ($all) {
    print MML &startAllNes($simName);
}

#print MML ".stjkasj";
#my $output = mySystem("mmm < $MML_MML 2>&1");

my $output = mySystem("$NETSIM_INSTALL_SHELL < $MML_MML 2>&1");

open tacacs_MML, "+>>$Tacacs_MML" or die "cann't open the file";
if ($setTacacs and $TacacsSupport > 0) {
        print tacacs_MML &setTacacsSupport($simName);
}
if ($setRadius) {
    print tacacs_MML &setRadiusSupport($simName);
}
my $output1 = mySystem("$NETSIM_INSTALL_SHELL < $Tacacs_MML 2>&1");
