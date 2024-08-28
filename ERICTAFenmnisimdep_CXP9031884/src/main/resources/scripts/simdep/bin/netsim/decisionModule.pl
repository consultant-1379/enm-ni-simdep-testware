#!/usr/bin/perl -w
use strict;
use Config::Tiny;
use Storable;
###################################################################################
#     File Name    : decisionModule.pl
#     Author       : Fatih Onur, Sneha
#     Description  : See usage below.
#     Date Created : 27 Januray 2014
###################################################################################
#
#----------------------------------------------------------------------------------
#Check if the scrip is executed as netsim user
#----------------------------------------------------------------------------------
#
my $user = `whoami`;
chomp($user);
my $netsim = 'netsim';
if ( $user ne $netsim ) {
    print "ERROR: Not netsim user. Please execute the script as netsim user\n";
    exit(201);
}

#
#----------------------------------------------------------------------------------
#Check if the script usage is right
#----------------------------------------------------------------------------------
my $USAGE =<<USAGE;
Descr: Decides on the following parameters; portName, ddPort, numOfIpv4Nes, numOfIpv6Nes
    Usage:
        $0 <simName> <neTypeName> <release> <securityStatusTLS> <switchToRv>
        where:
            <simName>           : The name of the simulation that needs to be opened in NETSim
            <neTypeName>        : The name of the Ne Type
            <release>           : Specifies release version of the simulation.
            <securityStatusTLS> : Specifies if the status of TLS is on/off.
            <switchToRv>        : Specifies if the rollout is on RV or MT deployment.
            <ipv6Per>           : Specifies Ipv6 nodes need or not
        usage examples:
             $0 RNCV43070x1-FT-RBSU230x15-RXIK190x2-RNC01 RNC 15.17 on on no
             $0 RNCV43070x1-FT-RBSU230x15-RXIK190x2-RNC01 RNC 15.17 off off yes
        dependencies:
              1. The port should already be created.
        Return Values: 201 -> Not a netsim user
                       202 -> Usage is incorrect
USAGE


# HELP 
if ((@ARGV < 5) || (@ARGV > 6)) {
    print "ERROR: $USAGE";
    exit(202);
}
print "INFO: RUNNING: $0 @ARGV \n";

#
#----------------------------------------------------------------------------------
#Variables
#----------------------------------------------------------------------------------
my $PWD = `pwd`;
chomp($PWD);

my $simNameTemp       = "$ARGV[0]";
my $neTypeName        = $ARGV[1];
my $release           = "$ARGV[2]";
my $securityStatusTLS = "$ARGV[3]";
my $ipv6Per           = "$ARGV[4]";

my @tempSimName = split( '\.zip', $simNameTemp );
my $simName     = $tempSimName[0];

chomp($neTypeName);
chomp($release);

#
#----------------------------------------------------------------------------------
#Subroutine to return network code
#----------------------------------------------------------------------------------
sub getNwType{
    my $simName = $_[0];
    my $nw = "";
    
    if ( "$simName" =~ m/LTE/i || "$simName" =~ m/NRAT/i || "$simName" =~ m/MULTIRAT/i || "$simName" =~ m/5G/i || "$simName" =~m/O1/i ) {
        $nw= 'lte';
    }
    elsif ( "$simName" =~ m/RNC/i
         || "$simName" =~ m/RBS/i ) {
           $nw= 'wran';
    }
    elsif ("$simName" =~ m/GRAN/i
        || "$simName" =~ m/STN/i
        || "$simName" =~ m/MSC/i
        || "$simName" =~ m/BSC/i
        || "$simName" =~ m/TCU/i )
    {
        $nw= 'gran';
    }
    elsif ( "$simName" =~ m/CORE/i || "$simName" =~ m/ML/i || "$simName" =~ m/Transport/i || "$simName" =~ m/CRAN/i ) {
        $nw= 'core';
    }
    else {
        print("ERROR: Unknow simulations. Please contact Fatih ONUR\n");
        $nw = undef;
    }
    return $nw
}


#----------------------------------------------------------------------------------
#MAIN
#----------------------------------------------------------------------------------
my $portName ="";
my $ddPort = "";
my $IpPerNe = 1;

open listNeName, "$PWD/../dat/dumpNeName.txt";
my @NeNames = <listNeName>;
close(listNeName);
print "neTypeName: $neTypeName \n";
if ( "$simName" =~ m/Yang/i )
    {
       if ( $neTypeName =~ m/PCG/i
       || $neTypeName =~ m/PCC/i
       || $neTypeName =~ m/Shared-CNF/i
       || $neTypeName =~ m/cIMS/i
        )
      {
  
       $portName = "YANG_SNMP_SSH_PROT";
       $ddPort   = "YANG_SNMP_SSH_PROT";
       $IpPerNe  = 1;
  
     }
      elsif  ( $neTypeName =~ m/LTE oRU/i ){

    $portName = "YANG_PROT";
    $ddPort   = "YANG_PROT";
    $IpPerNe  = 1;

}
     elsif ($neTypeName =~ m/CCDM/i
         || $neTypeName =~ m/CCES/i
         || $neTypeName =~ m/CCRC/i
         || $neTypeName =~ m/CCSM/i
         || $neTypeName =~ m/CCPC/i
         || $neTypeName =~ m/LTE SC/i
         || $neTypeName =~ m/WMG-OI/i
         || $neTypeName =~ m/vWMG-OI/i)
     {
        $portName = "YANG_SNMP_SSH_WMG_PROT";
         $ddPort =  "YANG_SNMP_SSH_WMG_PROT";
         $IpPerNe = 1;
     }
    elsif (  $neTypeName =~ m/vDU/i
         || $neTypeName =~ m/vCU/i
         || $neTypeName =~ m/vCU-CP/i
         || $neTypeName =~ m/vCU-UP/i         
	 || $neTypeName =~ m/RDM/i
     )
     {
         $portName = "YANG_SNMP_TLS_PROT";
         $ddPort   = "YANG_SNMP_TLS_PROT";
         $IpPerNe  = 1;
     }
elsif  ( $neTypeName =~ m/O1/i ){
   
    $portName = "YANG_PROT";
    $ddPort   = "YANG_PROT";
    $IpPerNe  = 1;

}
    
    elsif ( $neTypeName =~ m/SMSF/i )
    {
         $portName = "YANG_SNMP_SSH_SMSF_PROT";
         $ddPort   = "YANG_SNMP_SSH_SMSF_PROT";
         $IpPerNe  = 1;
    } 	
   elsif (  $neTypeName =~ m/EPG-OI/i
         || $neTypeName =~ m/vEPG-OI/i
         || $neTypeName =~ m/GenericADP/i )
       
    {
         $portName = "YANG_SNMP_SSH_EPG_PROT";
         $ddPort   = "YANG_SNMP_SSH_EPG_PROT";
         $IpPerNe  = 1;
      } 
   }
  
elsif ( $neTypeName =~ /^WCDMA R/i || $neTypeName =~ /^LTE ERBS/i || $neTypeName =~/mgw/i ) {
    $portName = "IIOP_PROT";
    $ddPort   = "NA";
    $IpPerNe  = 1;

}
elsif ( $neTypeName =~ /^LTE MSR/i || $neTypeName =~ m/RAN-VNFM/i || $neTypeName =~ m/EVNFM/i || $neTypeName =~ m/VNF-LCM/i || $neTypeName =~ m/CONTROLLER6610/i ) {
    if ( $simName =~ m/NRAT-SSH/i ) {
        $portName = "NETCONF_HTTP_HTTPS_SSH_PORT";
        $ddPort   = "NETCONF_HTTP_HTTPS_SSH_PORT";
        $IpPerNe  = 1;
    }
    elsif (lc "$securityStatusTLS" ne lc "OFF") {
        $portName = "NETCONF_HTTP_HTTPS_TLS_PORT";
        $ddPort   = "NETCONF_HTTP_HTTPS_TLS_PORT";
        $IpPerNe  = 1;

    } else {
        $portName = "NETCONF_HTTP_HTTPS_SSH_PORT";
        $ddPort   = "NETCONF_HTTP_HTTPS_SSH_PORT";
        $IpPerNe  = 1;
    }
}
elsif ($neTypeName =~ m/H2S/i
    || $neTypeName =~ /CSCF.*CORE/i
    || $neTypeName =~ /esapv/i
    || $neTypeName =~ /sbg/i
    || $neTypeName =~ /epdg/i)
{

    $portName = "NETCONF_PROT";
    $ddPort   = "NETCONF_PROT";
    $IpPerNe  = 1;

}
elsif ( $neTypeName =~ m/PCG 1-0-V1/i
    || $neTypeName =~ m/PCG 1-0-V2/i
    || $simName =~ m/5G118/i
    || $neTypeName =~ m/PCC 1-9-V1/i
    || $simName =~ m/5G132/i
)
{

    $portName = "YANG_SNMP_SSH_PROT";
    $ddPort   = "YANG_SNMP_SSH_PROT";
    $IpPerNe  = 1;

}
elsif ($neTypeName =~ m/CCDM 1-0-V1/i
    || $neTypeName =~ m/CCES 1-0-V1/i
    || $neTypeName =~ m/CCRC 1-0-V1/i
    || $neTypeName =~ m/CCSM 1-0-V1/i
    || $neTypeName =~ m/CCPC 1-0-V1/i
    || $neTypeName =~ m/LTE SC 1-0-V1/i
    || $neTypeName =~ m/CCDM 1-0-V2/i
    || $neTypeName =~ m/CCES 1-0-V2/i
    || $neTypeName =~ m/CCRC 1-0-V2/i
    || $neTypeName =~ m/CCSM 1-0-V2/i
    || $neTypeName =~ m/LTE SC 1-0-V2/i
    || $neTypeName =~ m/CCDM 1-3-1-V1/i
    || $neTypeName =~ m/CCDM 1-3-1-RI-V1/i
    || $neTypeName =~ m/CCDM 1-3-1-RI-V2/i
    || $simName =~ m/5G112/i
    || $simName =~ m/5G113/i
    || $simName =~ m/5G114/i
    || $simName =~ m/5G115/i
    || $simName =~ m/5G117/i
    || $simName =~ m/5G127/i
    || $neTypeName =~ m/WMG-OI 2-3-V1/i
    || $simName =~ m/CORE120/i
    || $simName =~ m/CORE125/i
    || $simName =~ m/CORE127/i
    || $simName =~ m/CORE129/i
    || $neTypeName =~ m/vWMG-OI 2-3-V1/i
    || $neTypeName =~ m/WMG-OI 2-3-V2/i
    || $neTypeName =~ m/vWMG-OI 2-3-V2/i
    || $neTypeName =~ m/WMG-OI 2-5-V1/i
    || $neTypeName =~ m/vWMG-OI 2-5-V1/i
    || $neTypeName =~ m/vWMG-OI 2-6-V1/i)
{
    $portName = "YANG_SNMP_SSH_WMG_PROT";
    $ddPort =  "YANG_SNMP_SSH_WMG_PROT";
    $IpPerNe = 1;
}

elsif (  $neTypeName =~ m/vDU 1-0-DY-V1/i
    ||  $neTypeName =~ m/vDU 1-0-DY-V2/i
    ||  $neTypeName =~ m/vDU 0-7-4-DY-V1/i
    ||  $neTypeName =~ m/vDU 0-10-1-DY-V1/i
    || $neTypeName =~ m/vDU 0-11-1-DY-V1/i
    || $neTypeName =~ m/vCU-CP 1-0-V1/i
    || $neTypeName =~ m/vCU-CP 0-1-6-V1/i
    || $neTypeName =~ m/vCU-UP 1-0-V1/i
    || $neTypeName =~ m/vCU-UP 0-3-1-V1/i
    || $neTypeName =~ m/vCU-CP 0-5-1-V1/i
    || $neTypeName =~ m/vCU-UP 0-6-1-V1/i
    || $neTypeName =~ m/vDU 0-12-3-DY-V1/i
    || $simName =~ m/5G130/i
    || $simName =~ m/5G131/i
    || $simName =~ m/5G116/i
    || $simName =~ m/5G134/i)
{
    $portName = "YANG_SNMP_TLS_PROT";
    $ddPort   = "YANG_SNMP_TLS_PROT";
    $IpPerNe  = 1;
}
elsif ($neTypeName =~ m/EPG-OI 3-4-DY-V1/i
    || $neTypeName =~ m/EPG-OI 3-5-DY-V1/i
    || $neTypeName =~ m/EPG-OI 3-4-DY-V2/i
    || $neTypeName =~ m/EPG-OI 3-5-DY-V2/i
    || $neTypeName =~ m/EPG-OI 3-5-DY-V3/i
    || $neTypeName =~ m/vEPG-OI 3-13-V1/i
    || $neTypeName =~ m/EPG-OI 3-4-DY-V3/i
    || $neTypeName =~ m/EPG-OI 3-5-DY-V4/i
    || $neTypeName =~ m/vEPG-OI 3-4-DY-V1/i
    || $neTypeName =~ m/vEPG-OI 3-5-DY-V2/i
    || $neTypeName =~ m/GenericADP 1-0-V1/i
    || $simName =~ m/CORE119/i
    || $simName =~ m/CORE135/i
    || $simName =~ m/CORE126/i
    || $simName =~ m/CORE128/i
    || $simName =~ m/5G133/i  )
  
{
    $portName = "YANG_SNMP_SSH_EPG_PROT";
    $ddPort   = "YANG_SNMP_SSH_EPG_PROT";
    $IpPerNe  = 1;
    
} 
elsif ( $neTypeName =~ m/SMSF 1-0-V1/i )
{
    $portName = "YANG_SNMP_SSH_SMSF_PROT";
    $ddPort   = "YANG_SNMP_SSH_SMSF_PROT";
    $IpPerNe  = 1;
} 
elsif ($neTypeName =~ /^LTE PRBS/i
    || $neTypeName =~ /TCU03/i
    || $neTypeName =~ /TCU04/i
    || $neTypeName =~ /^WCDMA PRBS/i
    || $neTypeName =~ /STN.*ECIM/i
    || $neTypeName =~ m/esapc/i
    || $neTypeName =~ m/vsapc/i
    || $neTypeName =~ m/C608/i
    || ($neTypeName =~ /^LTE RNNODE/i && $simName =~ m/TLS/i)
    || ($neTypeName =~ /^LTE vPP/i && $simName =~ m/TLS/i)
    || ($neTypeName =~ /^LTE vRC/i && $simName =~ m/TLS/i)
    || $neTypeName =~ /VTFRadioNode/i
    || $neTypeName =~ /5GRadioNode/i
    || $neTypeName =~ /VTIF/i
    || $neTypeName =~ /vSD/i
    || ($neTypeName =~ /^LTE vRM/i )
    || ($neTypeName =~ /^LTE vRSM/i ) )
{
    if (lc "$securityStatusTLS" ne lc "OFF") {
        $portName = "NETCONF_PROT_TLS";
        $ddPort   = "NETCONF_PROT_TLS";
        $IpPerNe  = 1;
    } else {
        $portName = "NETCONF_PROT_SSH_DG2";
        $ddPort   = "NETCONF_PROT_SSH_DG2";
        $IpPerNe  = 1;
    }
}
elsif ($neTypeName =~ m/epg-ssr/i
    || $neTypeName =~ m/epg-evr/i
    || $neTypeName =~ m/PCC/i
    || $neTypeName =~ m/PCG/i
    || $neTypeName =~ m/CCDM/i
    || $neTypeName =~ m/CCPC/i
    || $neTypeName =~ m/CCRC/i
    || (($neTypeName =~ m/LTE SC/i) && ( $neTypeName !~ m/LTE SCU/i ))
    || $neTypeName =~ m/CCSM/i
    || $neTypeName =~ m/CCES/i
    || $neTypeName =~ m/vDU/i
    || $neTypeName =~ m/EDA/i
    || $neTypeName =~ m/esasn/i
    || (($neTypeName =~ m/bsp/i) && ( $neTypeName !~ m/hlr/i ))
    || $neTypeName =~ m/dsc/i
    || $neTypeName =~ m/WCDMA CCN/i
    || $neTypeName =~ m/dua-s/i
    || $neTypeName =~ m/WCG/i
    || $neTypeName =~ m/vNSDS/i
    || $neTypeName =~ m/PGM.*CORE/i
    || $neTypeName =~ m/BBSC/i
    || $neTypeName =~ m/sdnc-p/i
    || $neTypeName =~ m/upg/i
    || $neTypeName =~ m/afg/i
    || $neTypeName =~ m/cudb/i
    || (( $neTypeName =~ m/HSS-FE/i ) && ( $neTypeName !~ m/HSS-FE-TSP/i ))
    || $neTypeName =~ m/MRFv/i
    || $neTypeName =~ m/MRSv/i
    || (($neTypeName =~ m/EME/i) && ($neTypeName !~ m/LANSWITCH/i))
    || $neTypeName =~ m/IPWORKS/i
    || $neTypeName =~ m/WMG/i 
    || $neTypeName =~ m/NeLS/i 
    || $neTypeName =~ m/SCEF/i
    || $neTypeName =~ m/EIR/i )
{

    $portName = "NETCONF_PROT_SSH";
    $ddPort   = "NETCONF_PROT_SSH";
    $IpPerNe  = 1;

}
elsif ($neTypeName =~ m/MTAS.*CORE/i )
{
     $portName = "NETCONF_PROT_SSH_MTAS";
     $ddPort   = "NETCONF_PROT_SSH_MTAS";
     $IpPerNe  = 1;
}
elsif ($neTypeName =~ m/epg-oi/i )
{
    $portName = "NETCONF_PROT_EPG";
    $ddPort   = "NETCONF_PROT_EPG";
    $IpPerNe  = 1;

}
elsif ($neTypeName =~ /^LTE RNNODE/i
    || $neTypeName =~ /^LTE vPP/i
    || $neTypeName =~ /^LTE vRC/i ) {
    $portName = "NETCONF_PROT_SSH";
    $ddPort   = "NETCONF_PROT_SSH";
    $IpPerNe  = 1;
}
elsif ($neTypeName =~ m/NRF/i
    || $neTypeName =~ m/NSSF/i
    || $neTypeName =~ m/UDR/i
    || $neTypeName =~ m/AUSF/i ) {
    $portName = "NETCONF_PROT_SSH";
    $ddPort   = "NETCONF_PROT_SSH";
    $IpPerNe  = 1;
}
elsif ($neTypeName =~ /SpitFire/i
    || $neTypeName =~ /R6274/i
    || $neTypeName =~ /R6273/i
    || $neTypeName =~ /R6672/i
    || $neTypeName =~ /R6675/i
    || $neTypeName =~ /R6371/i
    || $neTypeName =~ /R6471-1/i
    || $neTypeName =~ /R6471-2/i
    || $neTypeName =~ /R6673/i
    || $neTypeName =~ /R6676/i
    || $neTypeName =~ /R6678/i
    || $neTypeName =~ /R6671/i)
{
   if ( lc "$securityStatusTLS" ne lc "OFF" && $neTypeName =~ m/R6274/i) {
       $portName  = "NETCONF_PROT_TLS_SNMPV3";
        $ddPort   = "NETCONF_PROT_TLS_SNMPV3";
        $IpPerNe  = 1;
  }
  elsif ( lc "$securityStatusTLS" ne lc "OFF" ) {
        $portName  = "NETCONF_PROT_TLS";
        $ddPort   = "NETCONF_PROT_TLS";
        $IpPerNe  = 1;
  }
  else {
    $portName = "NETCONF_PROT_SSH_SPITFIRE";
    $ddPort   = "NETCONF_PROT_SSH_SPITFIRE";
    $IpPerNe  = 1;
  }
}
elsif ( $neTypeName =~ m/SGSN/i ) {

    if ( $neTypeName =~ m/SGSN.*CS/i ) {
        $portName = "SGSN_PROT";
        $ddPort   = "SGSN_PROT";
        $IpPerNe  = 1;
    }
    elsif ($neTypeName =~ m/WPP/i || $neTypeName =~ m/SGSN.*CP/i ) {
           $portName = "NETCONF_PROT_SSH_MME_ECIM";
           $ddPort = "NETCONF_PROT_SSH_MME_ECIM";
           $IpPerNe  = 1;
    }
    else{
        $portName = "SGSN";
        $ddPort   = "SGSN";
        $IpPerNe  = 1;
    }
}
elsif ($neTypeName =~ m/sasn/i
    || $neTypeName =~ m/epg-juniper/i
    || $neTypeName =~ m/cpg/i
    || $neTypeName =~ m/PGM/i
    || $neTypeName =~ m/TCU02/i
    || $neTypeName =~ m/SIU02/i )
{

    $portName = "SNMP_SSH_PROT";
    $ddPort   = "SNMP_SSH_PROT";
    $IpPerNe  = 1;

}
elsif ( $neTypeName =~ m/HSS-FE-TSP/i || $neTypeName =~ m/CCN/i || $neTypeName =~ m/CSCF/i
    || $neTypeName =~ m/MTAS/i || $neTypeName =~ m/SAPC/i || $neTypeName =~ m/VPN/i)
{
    $portName = "TSP_SSH_PROT";
    $ddPort   = "TSP_SSH_PROT";
    $IpPerNe  = 1;

}
elsif ( $neTypeName =~ m/ECM/i ||  $neTypeName =~ m/ECEE/i ||  $neTypeName =~ m/CCD/i || $neTypeName =~ m/OpenMano/i || $neTypeName =~ m/RNFVO/i || $neTypeName =~ m/HDS/i || $neTypeName =~ m/HP-NFVO/i || $neTypeName =~ m/SDI/i ) {
    $portName = "HTTP_HTTPS_PORT";
    $ddPort   = "HTTP_HTTPS_PORT";
    $IpPerNe  = 1;

}
elsif (  $neTypeName =~ m/ECEE/i ) {
    $portName = "HTTP_HTTPS_PORT";
    $ddPort   = "HTTP_HTTPS_PORT";
    $IpPerNe  = 3;
}
elsif ($neTypeName =~ m/msc/i
    || $neTypeName =~ m/bsc/i
    || $neTypeName =~ m/hlr/i
    || $neTypeName =~ m/IS IS/i )
{
    if ( $neTypeName =~ m/bsc.*apg43l/i
           || $neTypeName =~ m/msc-s-apg43l*/i ) {
        $portName = "APG43L_APGTCP";
        $ddPort   = "APG43L_APGTCP";
    }
    elsif("$NeNames[0]" =~ m/TEL/i) {
                $portName = "APG_TELNET_APGTCP";
                $ddPort   = "APG_TELNET_APGTCP";
    }
    elsif ( $neTypeName =~ m/bsc.*/i ) {
        $portName = "NETCONF_PROT_SSH";
        $ddPort   = "NETCONF_PROT_SSH";
    }
    elsif ( $neTypeName =~ m/MSC-BC-IS/i) {
        $portName = "MSC_BC_IS_TLS_PROT";
        $ddPort   = "MSC_BC_IS_TLS_PROT";
    }
    elsif ($neTypeName =~ m/IS IS/i) {
        $portName = "IS_PROT";
        $ddPort   = "IS_PROT";
        $IpPerNe  = 1;
    }
    elsif ( $neTypeName =~ m/MSC-DB/i
         || $neTypeName =~ m/MSC-IP-STP/i
         || $neTypeName =~ m/MSC-BC-BSP/i
         || $neTypeName =~ m/MSC-vIP-STP/i
         || $neTypeName =~ m/MSCv/i
	 || $neTypeName =~ m/vMSC/i
         || $neTypeName =~ m/HLR-FE/i
         ||$neTypeName =~ m/vHLR-BS/i ) {
        $portName = "APG_NETCONF_HTTP_HTTPS_TLS_PROT";
        $ddPort   = "APG_NETCONF_HTTP_HTTPS_TLS_PROT";
    }
else{
        $portName = "APG_APGTCP";
        $ddPort   = "APG_APGTCP";
    }
    $IpPerNe = 3;
}



    #INSERT HERE NE TYPE TO ADD NEW NE TYPE SUPPPORT
#elsif  ( $neTypeName =~ m/O1/i ){
   
   # $portName = "YANG_PROT";
  #  $ddPort   = "YANG_PROT";
 #   $IpPerNe  = 1;

#}

elsif ( ( $neTypeName =~ m/LTE SCU/i ) || ( $neTypeName =~ m/LTE ESC/i ) ) {
   
    $portName = "NETCONF_HTTP_HTTPS_TLS_PORT";
    $ddPort   = "NETCONF_HTTP_HTTPS_TLS_PORT";
    $IpPerNe  = 1;
}


elsif ( $neTypeName =~ m/ESC/i || $neTypeName =~ m/SCU/i || $neTypeName =~ m/ERS/i ) {

    $portName = "LANSWITCH_PROT";
    $ddPort   = "LANSWITCH_PROT";
    $IpPerNe  = 1;

}

elsif ( $neTypeName =~ m/SSR/i ||  $neTypeName =~ m/vBNG/i ||  $neTypeName =~ m/Router 8801/i ) {

    $portName = "LANSWITCH_PROT_SNMPV3";
    $ddPort   = "LANSWITCH_PROT_SNMPV3";
    $IpPerNe  = 1;

}
elsif ( $neTypeName =~ m/ECI-Optical/i || $neTypeName =~ m/ECI-LightSoft/i || $neTypeName =~ m/ECAS/i || $neTypeName =~ m/DSE/i ) {

    $portName = "SNMP";
    $ddPort = "SNMP";
    $IpPerNe  = 1;

}
elsif ( $neTypeName =~ m/FrontHaul/i) {

    if ( $neTypeName =~ m/FrontHaul.*6020/i || $neTypeName =~ m/FrontHaul.*6650/i  || $neTypeName =~ m/FrontHaul.*6000/i ) {
        my $nodeVersion =` echo $neTypeName | cut -d ' ' -f3 | sed 's/[A-Z]//g' | sed 's/-//g'`;
        if ( $nodeVersion > 2021 ) {
            $portName = "NETCONF_HTTP_HTTPS_TLS_SNMPV3_FRONTHAUL_PORT";
            $ddPort   = "NETCONF_HTTP_HTTPS_TLS_SNMPV3_FRONTHAUL_PORT";
            $IpPerNe  = 1;
        }
        else {
         $portName = "NETCONF_HTTP_HTTPS_SSH_FRONTHAUL_PORT";
         $ddPort   = "NETCONF_HTTP_HTTPS_SSH_FRONTHAUL_PORT";
         $IpPerNe  = 1;
        }
    }
    elsif ( $neTypeName =~ m/FrontHaul.*6080/i ) {
	 $portName = "LANSWITCH_PROT_SNMPV3";
         $ddPort   = "LANSWITCH_PROT_SNMPV3";
         $IpPerNe  = 1;
    }
    elsif ( $neTypeName =~ m/FrontHaul.*6392/i ) {
         $portName = "ML6352_PORT";
         $ddPort   = "ML6352_PORT";
         $IpPerNe  = 1;
    }
    elsif ( $neTypeName =~ m/LTE.*FrontHaul/i ) {
        $portName = "NETCONF_HTTP_HTTPS_SSH_FRONTHAUL_PORT";
        $ddPort   = "NETCONF_HTTP_HTTPS_SSH_FRONTHAUL_PORT";
        $IpPerNe  = 1;

    }
    else {
      $portName = "LANSWITCH_PROT";
      $ddPort   = "LANSWITCH_PROT";
      $IpPerNe  = 1;
}
}
elsif ( $neTypeName =~ m/ML-TN/i
    || $neTypeName =~ m/ML-CN/i
    || $neTypeName =~ m/ML 6691/i
    || $neTypeName =~ m/HSM/i
    || $neTypeName =~ m/ML 6692/i
    || $neTypeName =~ m/ML 6693/i
    || $neTypeName =~ m/ML 6651/i
    || $neTypeName =~ m/ML 6654/i
    || $neTypeName =~ m/ML 6366/i
    || $neTypeName =~ m/ML 6200/i
    || $neTypeName =~ m/ML-LH/i
    || $neTypeName =~ m/ML 6371/i ) {

    $portName = "SNMP_TELNET_PROT";
    $ddPort   = "SNMP_TELNET_PROT";
    $IpPerNe  = 1;

}
elsif ( $neTypeName =~ m/BB IC 8855/i ) {
    $portName = "SNMP_TELNET_IC8855_PROT";
    $ddPort   = "SNMP_TELNET_IC8855_PROT";
    $IpPerNe  = 1;
}     
elsif ( $neTypeName =~ m/JUNIPER MX/i || $neTypeName =~ m/CISCO ASR900/i || $neTypeName =~ m/CISCO ASR9000/i ) {

    $portName = "SNMP_SSH_TELNET_PROT";
    $ddPort   = "SNMP_SSH_TELNET_PROT";
    $IpPerNe  = 1;

}
elsif ($neTypeName =~ m/LANSWITCH/i || $neTypeName =~ m/JUNIPER PTX/i || $neTypeName =~ m/JUNIPER SRX/i || $neTypeName =~ m/JUNIPER VSRX/i || $neTypeName =~ m/JUNIPER VMX/i)
{
    $portName = "LANSWITCH_SNMP_SSH_TELNET_PORT";
    $ddPort   = "LANSWITCH_SNMP_SSH_TELNET_PORT";
    $IpPerNe  = 1;
}
elsif ( $neTypeName =~ m/EIR-FE/i ) {

    $portName = "SNMP";
    $ddPort   = "SNMP";
    $IpPerNe  = 1;

}
elsif (( $neTypeName =~ m/ML-PT/i ) && ($neTypeName !~  m/ML-PT.*2020/i)) {

    $portName = "MLPT_PORT";
    $ddPort   = "NA";
    $IpPerNe  = 1;

}
elsif ( $neTypeName =~ m/ML 6352/i ) {
    $portName = "ML6352_PORT_SNMPV3";
    $ddPort   = "ML6352_PORT_SNMPV3";
    $IpPerNe  = 1;

}
elsif ( $neTypeName =~ m/ML 6351/i || $neTypeName =~ m/ML-SWITCH 6391/i || $neTypeName =~ m/ML-PT.*2020/i) {
    $portName = "ML6352_PORT";
    $ddPort   = "ML6352_PORT";
    $IpPerNe  = 1;

}
else {
    print
"ERROR: Support for $neTypeName is not available. Please contact fatih.onur\@ericsson.com for adding support \n";
    exit;
}

#
#-----------------------------------------------------------------------------------
# IPV6-EXTRA NUMBER OF IPS for IPV4 AND IPV6
#----------------------------------------------------------------------------------
open listNeType, "$PWD/../dat/dumpNeType.txt";
my @NeType = <listNeType>;
close(listNeType);

#
#-----------------------------------------------------------------------------------
# IPV6 Parameters
#----------------------------------------------------------------------------------
my $IPV6_CONFIG_FILE  = "conf.txt";
my $IPV6_CONFIG_FILE_PATH ="$PWD/../conf/$IPV6_CONFIG_FILE";


#----------------------------------------------------------------------------------
# Defines number of ip per for exceptional nodes
#----------------------------------------------------------------------------------
my %neTypesIpMultiplier = (
    "TimeServer"       => 0,
    "MSC"              => 3,
    "BSC"              => 3,
    "vBSC"             => 3,
    "MSC-S-DB-APG43L"  => 3,
    "MSC-DB"           => 3,
    "MSC-IP-STP"       => 3,
    "MSC-BC-IS"        => 6,
    "MSC-BC-BSP"       => 6,
    "CTC-MSC-BC-BSP"   => 3,
    "MSC-vIP-STP"      => 3,
    "MSCv"             => 3,
    "vMSC-HC"          => 3,
    "MSC-S-APG"        => 3,
    "HLR-FE"           => 3,
    "HLR-FE-BSP"       => 3,
    "HLR-FE-IS"        => 3,
    "vHLR-BS"          => 3,
    "MSC-S-CP"         => 0,
    "MSC-S-TSC"        => 0,
    "MSC-S-SPX"        => 0,
    "MSC-S-APG43L"     => 3,
    "MSC-S-CP-APG43L"  => 0,
    "MSC-S-TSC-APG43L" => 0,
    "MSC-S-SPX-APG43L" => 0,
    "GSN"              => 0,
    "BSP"              => 1,
    "ECEE"             => 3
);

# Create a config
my $Config = Config::Tiny->new;

# Open the config
$Config = Config::Tiny->read($IPV6_CONFIG_FILE_PATH);
my $deploymentType = $Config->{_}->{DEPLOYMENT_TYPE};
print "INFO: Deployment Type is $deploymentType \n";
my $switchToRv= $Config->{_}->{SWITCH_TO_RV};
my $serverType= $Config->{_}->{SERVER_TYPE};
if ( @ARGV == 6 ) {
   #print "Taking parameter from arguments";
   $switchToRv= "$ARGV[5]";
}
#print "**********************switchtoRv is $switchToRv**********************\n";
# Root name, is the nework type
my $nw = &getNwType($simName);

my %simNesCountMap = ();
my @simNesArr      = ();
my $count          = 0;
for my $line (@NeType) {
    my @columns = split( /\s+/, $line );
    my $NE_TYPE = 1;
    #print "-------$columns[$NE_TYPE]" . "\n";
    push( @simNesArr, $columns[$NE_TYPE] );
    $simNesCountMap{ $columns[$NE_TYPE] }++;
}

my %ipv4Map  = ();
my %ipv6Map  = ();
my %ipv6Perc = ();

my $numOfIpv6Nes = 0;
my $numOfIpv4Nes = 0;

if ( defined $Config ) {
    print "-- ipv6 & ipv4 setup starting.. \n";
    my $count = 1;
    if (($release =~ m/15.17/i) && ($simName =~ m/LTE64/i)) {
        foreach my $neType ( keys %simNesCountMap ) {
            $ipv6Map{$neType} = 160;
            #$ipv4Map{$neType} = 0;
        }
        $numOfIpv4Nes = 0;
        $numOfIpv6Nes = 160;
    }
    elsif (($release =~ m/16.2/i) && ($simName =~ m/LTE16A-V17x160-5K-DG2-FDD-LTE07/i)) {
         foreach my $neType ( keys %simNesCountMap ) {
             $ipv4Map{$neType} = 140;
             $ipv6Map{$neType} = 20;
        }
        $numOfIpv4Nes = 140;
        $numOfIpv6Nes = 20;
    }
    elsif ($simName =~ m/MSC-S-BC-APG43L-IS/i) {
        if ( $simName =~ m/MSC18/i 
        || $simName =~ m/GSM18/i ) {
            $numOfIpv4Nes = 14;
            $numOfIpv6Nes = 6;
        }
        else { 
            $numOfIpv4Nes = 20;
            $numOfIpv6Nes = 0;
        }
    }
    elsif ($simName =~ m/HLR-FE-IS/i) {
        $numOfIpv4Nes = 20;
        $numOfIpv6Nes = 0;
    }
    elsif ($simName =~ m/MSC-S-BC-APG43L-BSP/i) {
        if ( $simName =~ m/MSC17/i
        || $simName =~ m/GSM17/i ) {
            $numOfIpv4Nes = 14;
            $numOfIpv6Nes = 6;
        }
        else {
            $numOfIpv4Nes = 20;
            $numOfIpv6Nes = 0;
        }
    }
    else {
        foreach my $neType ( keys %simNesCountMap ) {
            my $perc = 0;
            #print "neType-" .$count++ . ": $neType \n";
            if ( $ipv6Per =~ m/no/i )
            {
                $perc = 0;
            }
            elsif (($release =~ m/16.2/i) && ($simName =~ m/LTE/i) && ($simName !~ m/LTE08/i) && ($simName !~ m/LTE100/i) && ($simName !~ m/LTE101/i) && ($simName !~ m/LTE102/i) && ($simName !~ m/LTE103/i))
            {
                $perc = 37.5;
            }
            elsif (( lc "$switchToRv" eq "yes") && ($simName !~ m/GSM/i) && ($simName !~ m/ML6352/i) && ($simName !~ m/TCU02/i) && ($simName !~ m/SIU02/i) && ($simName !~ m/MGw/i)) {
                $perc = 20;
            }
            elsif (($release =~ m/16.2/i) && ($simName =~ m/SGSN/i) && ($simName !~ m/ST/i ))
            {
                $perc = 10;
            }
            elsif (($neType =~ m/STN/i ||$neTypeName =~ m/ERS/i || $neTypeName =~ m/AFG/i || $neTypeName =~ m/ML 6366/i || $neTypeName =~ m/ML 6651/i || $neTypeName =~ m/ML 6371/i || $neTypeName =~ m/ML 6654/i || $neTypeName =~ m/SCU/i ) && ( lc "$switchToRv" eq "no"))
            {
                $perc = 50;
            }
            elsif (($neTypeName =~ m/ML 6352/i ) && ( lc "$switchToRv" eq "no"))
            {
                $perc = 33;
            }
            elsif (($neTypeName =~ m/FrontHaul.*6392/i) && ( lc "$switchToRv" eq "no"))
            {
                if ( ("$deploymentType" eq lc "mediumDeployment" ) && ("$serverType" eq lc "VAPP" )) {
                    $perc = 50;
                }
                else {
                    $perc = 20;
                }
            }
            elsif ( ($neTypeName =~ m/vDU/i) && ( $simName =~ m/5G116/i) ) {
                $perc = 40;
            }
            elsif ( ($release !~ m/16.2/i) && (defined $Config->{$nw}->{$neType})) {
                if ( lc "$deploymentType" eq lc "largeDeployment" ) {
                    $perc = 20;
                } else {
                    $perc = $Config->{$nw}->{$neType};
                }
            }
            my $numOfNes = $simNesCountMap{$neType};
            $ipv6Perc{$neType} = $perc;
            my $numIpv6 = ( $numOfNes * ( $perc / 100 ) + 0.5 );
            my $resIpv6 = 0;
            if( ( $numOfNes == 1 ) && (( $perc == 50) || ( $perc == 20)) ) {
               $resIpv6 = 0;
            }
            elsif( ( $numIpv6>0 && $numIpv6<1 ) && ($perc!=0) ) {
               if ( $neTypeName =~ m/SGSN.*RUI/i || $neTypeName =~ m/SGSN.*UPGIND/i ) {
                   $resIpv6 = 0;
               }
               else {
                 $resIpv6 = 1;
               }
            }
            else {
                if ( ( $simName =~ m/MSC10/i || $simName =~ m/MSC11/i || $simName =~ m/MSC12/i || $simName =~ m/MSC13/i || $simName =~ m/MSC14/i || $simName =~ m/MSC15/i || $simName =~ m/MSC16/i || $simName =~ m/MSC17/i || $simName =~ m/MSC18/i || $simName =~ m/GSM18/i || $simName =~ m/GSM10/i || $simName =~ m/GSM11/i || $simName =~ m/GSM12/i || $simName =~ m/GSM13/i || $simName =~ m/GSM14/i || $simName =~ m/GSM15/i || $simName =~ m/GSM16/i || $simName =~ m/GSM17/i ) && ( $neType =~ m/MSC/i ) && ( lc "$switchToRv" eq "no" ) && ( lc "$ipv6Per" eq "yes") ) 
                {
                    $resIpv6 = 1
                }
               elsif( ( lc "$switchToRv" eq "no" ) && ( $simName =~ m/Transport77/i ) && ( $neTypeName =~ m/ML 6691/i ) && ( $simName =~ m/HSM/i ) && ( lc "$ipv6Per" eq "yes") )
                 {
                    $resIpv6 = 1
                 }
                else { 
                    $resIpv6 = int ( $numIpv6 );
                }
            }
            if ( $resIpv6 != 0 ) {
                my $mulresIpv6 = $resIpv6 * $neTypesIpMultiplier{$neType}
                if exists $neTypesIpMultiplier{$neType};
                if ( defined $mulresIpv6 ) {
                    $numOfIpv6Nes += $mulresIpv6;
                    $ipv6Map{$neType} = $mulresIpv6;
                }
                else {
                    $numOfIpv6Nes += $resIpv6;
                    $ipv6Map{$neType} = $resIpv6;
                }
            }
            my $resIpv4 = $numOfNes - $resIpv6;
            if ( $resIpv4 != 0 ) {
                $resIpv4 *= $neTypesIpMultiplier{$neType}
                if exists $neTypesIpMultiplier{$neType};
                $numOfIpv4Nes += $resIpv4;
                $ipv4Map{$neType} = $resIpv4;
            }
        }
    }
}
else {
    # default ipv4
    print "FILE_NAME=$IPV6_CONFIG_FILE_PATH doesn't exist \n";
    print "--ipv4 setup starting..\n";
    my $count = 1;
    foreach my $neType ( keys %simNesCountMap ) {

        #print "neType-" .$count++ . ": $neType \n";
        my $numOfNes = $simNesCountMap{$neType};
        my $resIpv4  = $numOfNes;
        $resIpv4 *= $neTypesIpMultiplier{$neType}
          if exists $neTypesIpMultiplier{$neType};
        $numOfIpv4Nes += $resIpv4;
        $ipv4Map{$neType} = $resIpv4;
    }
}

print "-------------------------------\n";
print "numOfIpv6Nes= $numOfIpv6Nes \n";
print "numOfIpv4Nes= $numOfIpv4Nes \n";
print "-------------------------------\n";


#------------------------------------------------
# Store ip maps into a file
#------------------------------------------------
my @ipVars = ();
$ipVars[0] = \%ipv4Map;
$ipVars[1] = \%ipv6Map;
my $file_ipVars = "$PWD/../dat/ipVars.dat";
store \@ipVars, $file_ipVars || die "ERROR: Can not store $file_ipVars \n";
print "INFO: $file_ipVars stored succesfully \n";


#----------------------------------------------------------------------------------

#@dumpDecisionParams = ( $portName, $ddPort, $IpPerNe );
my @dumpDecisionParams = ( $portName, $ddPort, $numOfIpv4Nes, $numOfIpv6Nes );
print @dumpDecisionParams;
open DUMPDECISIONPARAMS, ">$PWD/../dat/dumpDecisionParams.txt"
  or die "ERROR: Could not open $PWD../dat/dumpDecisionParams.txt";
print DUMPDECISIONPARAMS "$portName\n";
print DUMPDECISIONPARAMS "$ddPort\n";
print DUMPDECISIONPARAMS "$numOfIpv4Nes\n";
print DUMPDECISIONPARAMS "$numOfIpv6Nes\n";
close DUMPDECISIONPARAMS;

#------------------------------------------------
#Updating IPs details in sim folder
#------------------------------------------------
#
open IPDETAILS, ">/netsim/netsimdir/$simName/IP_Details.txt"
    or die "ERROR: Could not open /netsim/netsimdir/$simName/IP_Details.txt";
print IPDETAILS "NO.OF IPV4 NEs=$numOfIpv4Nes\n";
print IPDETAILS "NO.OF IPV6 NEs=$numOfIpv6Nes\n";
close IPDETAILS;
