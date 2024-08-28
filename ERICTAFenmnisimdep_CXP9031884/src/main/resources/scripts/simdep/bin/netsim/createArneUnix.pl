#!/usr/bin/perl -w
###################################################################################
#
#     File Name : createArneUnix.pl
#
#     Version : 4.00
#
#     Author : Jigar Shah
#
#     Description : creates ARNE XML and Unix Users
#
#     Date Created : 13 January 2014
#
#     Syntax : ./createArneUnix <simName> <NeType>
#
#     Parameters : <simName> The name of the simulation that needs to be opened in NETSim
#
#     Example :  ./createArneUnix.pl CORE-K-FT-M-MGwB15215-FP2x1-vApp.zip
#
#     Dependencies : 1.
#
#     NOTE:
#
#     Return Values : N/A
#
###################################################################################
#
#----------------------------------------------------------------------------------
#Variables
#----------------------------------------------------------------------------------
my $NETSIM_INSTALL_SHELL = "/netsim/inst/netsim_pipe";

#
#----------------------------------------------------------------------------------
#Check if the scrip is executed as netsim user
#----------------------------------------------------------------------------------
#
$user = `whoami`;
chomp($user);
$netsim = 'netsim';
if ( $user ne $netsim ) {
    print "ERROR: Not netsim user. Please execute the script as netsim user\n";
    exit(201);
}

#
#----------------------------------------------------------------------------------
#Check if the script usage is right
#----------------------------------------------------------------------------------
$USAGE =
"Usage: $0 <simName> <NeTyep> \n  E.g. $0 CORE-K-FT-M-MGwB15215-FP2x1-vApp.zip CORE SGSN 13A \n";

# HELP
if ( @ARGV != 2 ) {
    print "ERROR\n$USAGE";
    exit(202);
}
print "RUNNING: $0 @ARGV \n";

#
#----------------------------------------------------------------------------------
#Environment Variable
#----------------------------------------------------------------------------------
my $simNameTemp = "$ARGV[0]";
@tempSimName = split( '\.zip', $simNameTemp );
my $simName    = $tempSimName[0];
my $arneVar    = undef;
my $NeTypeName = "$ARGV[1]";
my $selectNE   = "network ";
$PWD = `pwd`;
chomp($PWD);

#Get a list of elements in a scalar
if (! -e "$PWD/../dat/dumpNeName.txt") {
    print "ERROR: File $PWD/../dat/dumpNeName.txt doesn't exist.\n";
    exit(206);
    }
if (! open FH, "<", "$PWD/../dat/dumpNeName.txt") {
    print "ERROR: Could not open file $PWD/../dat/dumpNeName.txt.\n";
    exit(203);
    }
@neNames = <FH>;
close FH;

#
$_ = $NeTypeName;
if ( $_ =~ /mgw/i ) {
    $arneVar =
".createarne R6 $simName MGW %nename secret IP secure sites no_external_associations no_value ";

}
elsif ( $_ =~ m/LTE PRBS/i ) {

    $prbsSubNetwork = "PRBS";
    $arneVar =
".createarne R12.2 $simName $prbsSubNetwork %nename secret IP secure sites no_external_associations ftp";

}
elsif (( $_ =~ m/erbs/i ) || ( $neNames[0]=~ m/LTE/i )){
    $var = $neNames[0];
    chomp($var);
    $varGroup = "null";
    foreach $arr (@neNames) {
        chomp($arr);
        if ( "$varGroup" eq "null" ) {
            $varGroup = $arr;
        }
        else {
            $varGroup = "$varGroup" . "|" . "$arr";
        }
    }

    #This is not scalable and only valid for 1 - 99.
    $count = substr( "$var",   3, 2 );
    $zero  = substr( "$count", 0, 1 );
    if ( $zero eq "0" ) { $count = substr( $count, 1, 1 ) }
    $lte = substr( "$var", 0, 3 );
    if ( $lte eq "LTE" ) {

        #print "lte word exist";
        $erbsSubNetwork = "ERBS-SUBNW-" . "$count";
    }
    else {
        $erbsSubNetwork = "ERBS-SUBNW-" . "DEFAULT";
    }

    #print "Substring valuye is $count\n";
    print "The subNetwork is $erbsSubNetwork \n";

    $arneVar =
".createarne R12.2 $simName LTE %nename secret IP secure sites no_external_associations ftp $erbsSubNetwork $varGroup";

}
elsif ( $_ =~ m/stn/i ) {
    $var = $neNames[0];
    chomp($var);
    $varGroup = "null";
    foreach $arr (@neNames) {
        chomp($arr);
        if ( "$varGroup" eq "null" ) {
            $varGroup = $arr;
        }
        else {
            $varGroup = "$varGroup" . "|" . "$arr";
        }
    }

    $arneVar =
".createarne R12.2 $simName NETSim %nename secret IP secure sites no_external_associations ftp  STN-SUBNW-1 $varGroup ";

}
elsif ( $_ =~ /rxi/i || /rnc/i || /rbs/i ) {
    $var = $neNames[0];
    chomp($var);
    $varGroup = "null";
    foreach $arr (@neNames) {
        chomp($arr);
        if ( ( "$arr" eq "$var" ) || ( "$arr" =~ /rxi/i ) ) {
            next;
        }
        if ( "$varGroup" eq "null" ) {
            $varGroup = $arr;
        }
        else {
            $varGroup = "$varGroup" . "|" . "$arr";
        }
    }

    $arneVar =
".createarne R12.2 $simName RNC %nename secret IP secure sites no_external_associations ftp defaultgroups";

}
elsif ( $_ =~ m/WPP SGSN/i ) {
    $arneVar =
".createarne R6 $simName SGSN %nename secret IP secure sites no_external_associations ftp ";

}
elsif ( $_ =~ m/SGSN SPP/i ) {
    $arneVar =
".createarne R6 $simName SGSN %nename secret IP secure sites no_external_associations no_value ";
}
elsif ( $_ =~ m/SGSN/i ) {

    if ( $_ =~ m/^((?!SGSN.*CS).)*$/i ) {
        $arneVar =
".createarne R6 $simName SGSN %nename secret IP secure sites no_external_associations no_value ";
        $selectNE = &manipulateSGSN();
    }
    else {
        $arneVar =
".createarne R6 $simName SGSN %nename secret IP secure sites no_external_associations no_value ";
    }
}
elsif ( $_ =~ m/PGM/i ) {
    $arneVar =
".createarne R6 $simName PGM %nename secret IP secure sites no_external_associations ftp ";

}
elsif ($_ =~ m/esapc/i
    || /dsc/i
    || /dua-s/i
    || /WCG/i
    || /vNSDS/i
    || /esasn/i )
{
    $arneVar =
".createarne R6 $simName IMS %nename secret IP secure sites no_external_associations ftp ";

}
elsif ($_ =~ m/cscf/i
    || /H2S/i
    || /MTAS/i
    || /epg/i
    || /esapv/i
    || /BBSC.*CORE/i
    || /sapc/i
    || /HSS/i
    || /cudb/i
    || /epdg/i )
{
    $arneVar =
".createarne R6 $simName IMS %nename secret IP secure sites no_external_associations no_value ";

}
elsif ( $_ =~ m/sasn/i ) {
    $arneVar =
".createarne R6 $simName SASN %nename secret IP secure sites no_external_associations no_value ";

}
elsif ( $_ =~ m/sbg/i ) {
    $arneVar =
".createarne R6 $simName SBG %nename secret IP secure sites no_external_associations no_value ";
}

elsif ( $_ =~ m/afg/i ) {
    $arneVar =
".createarne R6 $simName AFG %nename secret IP secure sites no_external_associations no_value ";

}
elsif ( $_ =~ m/ecm/i ) {
    $arneVar =
".createarne R6 $simName ECM %nename secret IP secure sites no_external_associations no_value ";

}
elsif ( $_ =~ m/FrontHaul/i ) {
    $arneVar =
".createarne R6 $simName FrontHaul %nename secret IP secure sites no_external_associations no_value ";

}
elsif ( $_ =~ m/ML-PT/i ) {
    $arneVar =
".createarne R6 $simName ML-PT %nename secret IP secure sites no_external_associations no_value ";

}
elsif ( $_ =~ m/ML-TN/i ) {
    $arneVar =
".createarne R12.2 $simName ML-TN %nename secret IP secure sites no_external_associations no_value ";

}
elsif ( $_ =~ m/ML-CN/i ) {
    $arneVar =
".createarne R12.2 $simName ML-CN %nename secret IP secure sites no_external_associations no_value ";

}
elsif ( $_ =~ m/ML-LH/i ) {
    $arneVar =
".createarne R12.2 $simName ML-LH %nename secret IP secure sites no_external_associations no_value ";

}
elsif ( $_ =~ m/ML 6691/i ) {
    $arneVar =
".createarne R12.2 $simName ML 6691 %nename secret IP secure sites no_external_associations no_value ";

}
elsif( $_ =~ m/CISCO ASR/i ) {
    $arneVar =
".createarne R12.2 $simName CISCO ASR %nename secret IP secure sites no_external_associations no_value ";

}
elsif( $_ =~ m/JUNIPER MX/i ) {
    $arneVar =
".createarne R12.2 $simName JUNIPER MX %nename secret IP secure sites no_external_associations no_value ";

}
elsif ( $_ =~ m/MSC-S-DB/i
    || /cpg/i )
{
    $var = $neNames[0];
    chomp($var);

    # cut ne name up to find a digit 0
    my $groupName = substr( "$var", 0, index( $var, '0' ) );

    $varGroup = "null";
    foreach $arr (@neNames) {
        chomp($arr);
        if ( "$varGroup" eq "null" ) {
            $varGroup = $arr;
        }
        else {
            $varGroup = "$varGroup" . "|" . "$arr";
        }
    }

    $arneVar =
".createarne R6 $simName IMS %nename secret IP secure sites no_external_associations no_value $groupName $varGroup";

}
elsif ( $_ =~ m/bsp/i )
{
    $var = $neNames[0];
    chomp($var);

    # cut ne name up to find a digit 0
    my $groupName = substr( "$var", 0, index( $var, '0' ) );

    $varGroup = "null";
    foreach $arr (@neNames) {
        chomp($arr);
        if ( "$varGroup" eq "null" ) {
            $varGroup = $arr;
        }
        else {
            $varGroup = "$varGroup" . "|" . "$arr";
        }
    }

    $arneVar =
".createarne R6 $simName IMS %nename secret IP secure sites no_external_associations ftp $groupName $varGroup";

}
elsif ( $_ =~ m/sdnc-p/i ) {
    $arneVar =
".createarne R12.2 $simName NETSim %nename secret IP secure sites no_external_associations no_value";
}
elsif ( $_ =~ m/MSC-S/i ) {
    $var = $neNames[0];
    chomp($var);
    my $groupName = substr( "$var", 0, index( $var, '0' ) );
    $varGroup = "null";
    foreach $arr (@neNames) {
        chomp($arr);
        if ( "$varGroup" eq "null" ) {
            $varGroup = $arr;
        }
        else {
            if ( $arr =~ m/MSC-S-BSP/i ) {
                $varGroup = "$varGroup" . "|" . "$arr";
            }
        }
    }

    if ( $simNameTemp =~ m/TELNET/i ) {
        $arneVar =
".createarne R6 $simName  NETSim %nename secret IP insecure sites no_external_associations no_value";
    }
    else {
        $arneVar =
".createarne R6 $simName  NETSim %nename secret IP secure sites no_external_associations no_value $groupName $varGroup";
    }
}
elsif ( $_ =~ m/MSC/i || m/bsc/i ) {
    $varGroup = "null";
    foreach $arr (@neNames) {
        chomp($arr);
        if ( "$arr" =~ /SIU/i ) {
            if ( "$varGroup" eq "null" ) {
                $varGroup = "defaultgroups";
            }
        }
    }
    my $ftp = "ftp";
    if ( "$varGroup" ne "null" ) {
        $ftp = "$ftp" . " " . "$varGroup";
    }
    if ( $simNameTemp =~ m/TELNET/i ) {
        $arneVar =
".createarne R12.2 $simName NETSim %nename secret IP insecure sites no_external_associations $ftp";
    }
    else {
        $arneVar =
".createarne R12.2 $simName NETSim %nename secret IP secure sites no_external_associations $ftp";
    }

}
elsif ( $_ =~ m/TCU/i ) {
    $arneVar =
".createarne R12.2 $simName NETSim %nename secret IP secure sites no_external_associations ftp";

}
elsif ( $_ =~ m/upg/i ) {
    $arneVar =
".createarne R6 $simName UPG  %nename secret IP secure sites no_external_associations no_value ";

}
elsif ( $_ =~ m/hlr/i ) {
    $arneVar =
".createarne R12.2 $simName NETSim %nename secret IP secure sites no_external_associations no_value";

}
elsif ( $_ =~ m/EIR-FE/i ) {
    $arneVar =
".createarne R6 $simName NETSim %nename secret IP secure sites no_external_associations no_value";

}
else {
    print "ERROR - Could not create ARNE XML, support not provided. \n";
    exit;
}

#
#----------------------------------------------------------------------------------
#SubRoutine as a workaround for SGSN XML generation
#----------------------------------------------------------------------------------
sub manipulateSGSN {
    if (! -e "$PWD/../dat/dumpNeName.txt") {
        print "ERROR: File $PWD/../dat/dumpNeName.txt doesn't exist.\n";
        exit(206);
    }
    if (! open listNeName, "<", "$PWD/../dat/dumpNeName.txt") {
        print "ERROR: Could not open file $PWD/../dat/dumpNeName.txt.\n";
        exit(203);
    }
    my @NeName = <listNeName>;
    close(listNeName);
    my $count      = @NeName;
    my $tempString = "";
    for ( $i = 0 ; $i < $count / 2 ; $i++ ) {
        chomp( $NeName[$i] );
        $tempString = "$tempString" . "$NeName[$i] ";
    }
    return $tempString;
}

#
#----------------------------------------------------------------------------------
#Define NETSim MO file and Open file in append mode
#----------------------------------------------------------------------------------
$MML_MML = "MML.mml";
open MML, "+>>$MML_MML";

#
#----------------------------------------------------------------------------------
#Create ARNE XML and UNIX User
#----------------------------------------------------------------------------------
print MML ".open $simName \n";
print MML ".selectnocallback $selectNE\n";

#print MML ".selectnocallback network \n";
print MML ".arneconfig rootmo ONRM_ROOT_MO \n";
print MML "$arneVar\n";
print MML ".selectnocallback network\n";

#print MML ".createusersdialog\n";
print MML
".createusers /netsim/netsimdir/exported_items/create_users_for_$simName %nename secret .login\n";

#
system("$NETSIM_INSTALL_SHELL < $MML_MML");
if ($? != 0)
{
    print "ERROR: Failed to execute system command ($NETSIM_INSTALL_SHELL < $MML_MML)\n";
    exit(207);
}
close MML;
system("rm $MML_MML");
if ($? != 0)
{
    print "INFO: Failed to execute system command (rm $MML_MML)\n";
}

#-------------------------------------------------------------------------------------
#Exception block for SGSN
#-------------------------------------------------------------------------------------
