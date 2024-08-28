#! /bin/sh
##########################################################################################################################
# Created by  : Sneha Srivatsav Arra
# Created in  : 2015.11.25
###
### VERSION HISTORY
# Ver         : Follow up from gerrit
# Purpose     : Installs perl plugins needed for SIMDEP to run.
# Dependency  :
# Description : Installs perl plugins needed for SIMDEP to run.
# Date        : 25 NOV 2015
# Who         : Sneha Srivatsav Arra
###########################################################################################################################
#

usage() {
    echo "ERROR: Invalid arguments"
    echo "Example: $0 online GCP/no or $0 offline GCP/no"
    exit 1
}
[[ $# -ne 2 ]] && usage
#---------------------------------------------------------------------------------
#variables
#---------------------------------------------------------------------------------
install_Type=$1
rolloutType=$2
HOST='159.107.220.96'
USER='simadmin'
PASSWD='simadmin'
CWD="$(cd "$(dirname "$0")" && pwd)"
echo "Current Working Directory $CWD"
VERSION=`openssl version | awk -F " " '{print $2}'`
OpenSSHV=`rpm -qa | grep openssh | grep -v askpass |awk -F "-" '{print $2}'`
NRM=`cat /netsim/simdepContents/NRMDetails | grep -w 'RolloutNetwork' | cut -d '=' -f2`
bitVersion=`openssl version -a | grep -w 'platform:' | awk -F ': ' '{print $2}'`
LARGE_NTWK_CHECK=`ls /netsim/simdepContents/ | grep -E "GSM_30Kcells|30KGRAN|10KWCDMA|rv_4.8K_cRAN|rv_4800_cRAN"`
opensslversion=`openssl version | cut -d ' ' -f2 | sed s/.$//`
opensslversionAsInteger=$(echo ${opensslversion//./})
checkgcc=`which gcc`
checkcryptos=`ls /usr/lib | grep libcrypto.so.1.0.0 | sed 'N;s/\n/ /'`
checkcryptos64=`ls /usr/lib64 | grep libcrypto.so.1.0.0 | sed 'N;s/\n/ /'`
#
#---------------------------------------------------------------------------------
#Installing gcc package
#--------------------------------------------------------------------------------

if [ -f /etc/centos-release ]
then
if [  ! -z ${checkgcc} ] && [ -f ${checkgcc} ]
 then
     echo -e "gcc is already installed "
  else
    /usr/bin/expect -c '
    set timeout 60
    spawn yum install gcc
    expect {
          "y/n"   { send "y\r"  ; exp_continue  }
          "y/d/N" { send "y\r"  ; exp_continue  }
          "a/r/i/"  { send "a\r" ; exp_continue  }
          default { exp_continue }
    }'

  fi
 if [[ $opensslversionAsInteger != 111 ]]
then
  rm -rf /var/tmp/openssl*;
  if [[ ${install_Type} = "offline" ]]
  then
     cp /netsim/Extra/openssl-centos-1.1.1g.tar.gz /var/tmp/openssl-1.1.1g.tar.gz
  else
    if [[ ${rolloutType} = "GCP" ]]
    then
         curl --retry 5 -fsS https://www.openssl.org/source/old/1.1.1/openssl-1.1.1g.tar.gz -o /var/tmp/openssl-1.1.1g.tar.gz;
    else
         curl --retry 5 -fsS https://www.openssl.org/source/old/1.1.1/openssl-1.1.1g.tar.gz -o /var/tmp/openssl-1.1.1g.tar.gz;
    fi
  fi
  tar xvf /var/tmp/openssl-1.1.1g.tar.gz -C /var/tmp;
  cd /var/tmp/openssl-1.1.1g;
  yum -y install glibc-devel.i686 glibc-devel;
fi 
  if [ $NRM = "rvModuleGRAN_30KCells_NRM5" ] || [ $NRM = "rvModuleNRM5_5K_GSM" ] || [ ! -z $LARGE_NTWK_CHECK ]
  then
     if [ $VERSION != "1.1.1g" ] || [ $bitVersion != "linux-x86_64" ] || [ -z $checkcryptos64 ]
     then
        if [[ ${rolloutType} != "GCP" ]]
        then
            rm -rf /var/tmp/openssl*;
             curl --retry 5 -fsS https://www.openssl.org/source/old/1.1.1/openssl-1.1.1g.tar.gz -o /var/tmp/openssl-1.1.1g.tar.gz;
           tar xvf /var/tmp/openssl-1.1.1g.tar.gz -C /var/tmp;
           cd /var/tmp/openssl-1.1.1g
           yum -y install glibc-devel.i686 glibc-devel;
        fi
      ./config shared threads zlib-dynamic --prefix=/usr --openssldir=/etc/ssl;
      make;
      make install_sw;
     fi
  elif [ $VERSION != "1.1.1g" ] || [ $bitVersion == "linux-x86_64" ] || [ -z $checkcryptos ]
  then
      if [[ ${rolloutType} != "GCP" ]]
      then
          rm -rf /var/tmp/openssl*;
           curl --retry 5 -fsS https://www.openssl.org/source/old/1.1.1/openssl-1.1.1g.tar.gz -o /var/tmp/openssl-1.1.1g.tar.gz;
          tar xvf /var/tmp/openssl-1.1.1g.tar.gz -C /var/tmp;
          cd /var/tmp/openssl-1.1.1g;
          yum -y install glibc-devel.i686 glibc-devel;
       fi
      ./Configure shared threads zlib-dynamic --prefix=/usr --openssldir=/etc/ssl -m32 linux-generic32;
      make CC='gcc -m32';
      make install_sw;
  fi
else
  if [ $NRM = "rvModuleGRAN_30KCells_NRM5" ] || [ $NRM = "rvModuleNRM5_5K_GSM" ] || [ ! -z $LARGE_NTWK_CHECK ]
  then
     if [ $VERSION != "1.0.1g" ] || [ $bitVersion != "linux-x86_64" ] || [ -z $checkcryptos64 ]
     then
      zypper addrepo http://download.opensuse.org/distribution/11.4/repo/oss/ strongciphers;
      zypper --gpg-auto-import-keys refresh;
      zypper -n in zlib-devel;
      zypper rr strongciphers;
      zypper --gpg-auto-import-keys refresh;
      zypper --non-interactive install --force openssl-0.9.8j-0.26.1.x86_64
      rm -rf /var/tmp/openssl*
      if [[ ${install_Type} = "offline" ]]
      then
          cp /netsim/Extra/openssl-1.0.1g.tar.gz /var/tmp/
      else
          curl --retry 5 -fsS https://www.openssl.org/source/old/1.0.1/openssl-1.0.1g.tar.gz -o /var/tmp/openssl-1.0.1g.tar.gz;
      fi
      tar xvf /var/tmp/openssl-1.0.1g.tar.gz -C /var/tmp;
      cd /var/tmp/openssl-1.0.1g;
      ./config shared threads zlib-dynamic --prefix=/usr --openssldir=/etc/ssl;
      make install;
     fi
  elif [ $VERSION != "1.0.1g" ] || [ $bitVersion == "linux-x86_64" ] || [ -z $checkcryptos ]
  then
      zypper addrepo http://download.opensuse.org/distribution/11.4/repo/oss/ strongciphers;
      zypper --gpg-auto-import-keys refresh;
      zypper -n in zlib-devel;
      zypper rr strongciphers;
      zypper --gpg-auto-import-keys refresh;
      zypper --non-interactive install --force openssl-0.9.8j-0.26.1.x86_64
      rm -rf /var/tmp/openssl*
      if [[ ${install_Type} = "offline" ]]
      then
          cp /netsim/Extra/openssl-1.0.1g.tar.gz /var/tmp/
      else
          curl --retry 5 -fsS https://www.openssl.org/source/old/1.0.1/openssl-1.0.1g.tar.gz -o /var/tmp/openssl-1.0.1g.tar.gz;
      fi
      tar xvf /var/tmp/openssl-1.0.1g.tar.gz -C /var/tmp;
      cd /var/tmp/openssl-1.0.1g;
      ./Configure shared threads zlib-dynamic --prefix=/usr --openssldir=/etc/ssl -m32 linux-generic32;
      zypper --non-interactive in glibc-devel-32bit;
      zypper --non-interactive in gcc-32bit;
      make CC='gcc -m32';
      make install;
  fi
  
  if [  $OpenSSHV != "5.8p1" ]
  then
      zypper addrepo http://download.opensuse.org/distribution/11.4/repo/oss/ strongciphers;
      zypper --gpg-auto-import-keys refresh;
      zypper -n update openssh;
      zypper rr strongciphers;
      zypper --gpg-auto-import-keys refresh;
  fi
fi



ln -s /usr/lib64/perl5 /usr/lib/perl5
mkdir -p /usr/lib/perl5/5.10.0/x86_64-linux-thread-multi/IO/
mkdir -p /usr/lib/perl5/vendor_perl/5.10.0/
mkdir -p /usr/lib/perl5/vendor_perl/5.10.0/Net
mkdir -p /usr/lib/perl5/vendor_perl/5.10.0/Config

#
#---------------------------------------------------------------------------------
#Installing IO-Tty-1.07 package
#---------------------------------------------------------------------------------
#Path=`pwd`
IO="IO::Tty"
echo -e " checking module  $value installed or not"
package=`perl /var/simnet/enm-ni-simdep/scripts/checkInstall.pl $IO`
echo $package
if [[ $package != 1 ]]
then
cp $CWD/simdep/pkg/IO-Tty-1.07.tar.gz /usr/lib/perl5/5.10.0/x86_64-linux-thread-multi/IO/
cd /usr/lib/perl5/5.10.0/x86_64-linux-thread-multi/IO/
tar xzf IO-Tty-1.07.tar.gz
cd IO-Tty-1.07/
perl Makefile.PL
make
make test
make install
else
echo -e "####$IO module is already installed####"
fi
#
#---------------------------------------------------------------------------------
#Installing Expect-1.15 package
#---------------------------------------------------------------------------------
Expect="Expect"
package=`perl /var/simnet/enm-ni-simdep/scripts/checkInstall.pl $Expect`
echo $package
if [[ $package != 1 ]]
then
cp  $CWD/simdep/pkg/Expect-1.15.tar.gz /usr/lib/perl5/./vendor_perl/5.10.0/
cd /usr/lib/perl5/./vendor_perl/5.10.0/
tar xzf Expect-1.15.tar.gz
cd Expect-1.15/
perl Makefile.PL
make
make test
make install
else
echo -e "#### $Expect module is already installed ####"
fi
#
#---------------------------------------------------------------------------------
#Installing Net-OpenSSH-0.60 package
#---------------------------------------------------------------------------------
OpenSSH="Net::OpenSSH"
package=`perl /var/simnet/enm-ni-simdep/scripts/checkInstall.pl $OpenSSH`
echo $package
if [[ $package != 1 ]]
then
cp $CWD/simdep/pkg/Net-OpenSSH-0.60.tar.gz /usr/lib/perl5/./vendor_perl/5.10.0/Net/
cd /usr/lib/perl5/./vendor_perl/5.10.0/Net/
PWD=`pwd`
if [[ ${install_Type} = "offline" ]]
then
   cp /neitsim/Extra/Net-OpenSSH-0.60.tar.gz .
   tar xzf Net-OpenSSH-0.60.tar.gz
   cd Net-OpenSSH-0.60/
else
if [ ! -d $PWD/Net-OpenSSH-0.60 ]
  then 
  echo "file not exist"
   mkdir Net-OpenSSH-0.60; chown netsim:netsim Net-OpenSSH-0.60
  fi
cd Net-OpenSSH-0.60/	
cp /var/simnet/enm-ni-simdep/scripts/Net-OpenSSH-0.60.tar .
tar  -xvf Net-OpenSSH-0.60.tar
 if [[ $? -ne 0 ]]
        then
            echo "ERROR: Extracting Net-OpenSSH-0.60.tar failed from simdep"
            exit 201
fi
fi
perl Makefile.PL
make
/usr/bin/expect -c '
set timeout 60
spawn make test
expect {
      "*?assword:"   { send "shroot\r"  ; exp_continue  }
}
'
make install
else
echo -e  "#### $OpenSSH module already present ####"
fi
#
#---------------------------------------------------------------------------------
#Installing Config-Tiny-2.12 package
#---------------------------------------------------------------------------------
Config="Config::Tiny"
package=`perl /var/simnet/enm-ni-simdep/scripts/checkInstall.pl $Config`
echo $package
if [[ $package != 1 ]]
then
cp $CWD/simdep/pkg/Config-Tiny-2.12.tar.gz /usr/lib/perl5/./vendor_perl/5.10.0/Config/
cd /usr/lib/perl5/./vendor_perl/5.10.0/Config/
tar xzf Config-Tiny-2.12.tar.gz
cd Config-Tiny-2.12/
perl Makefile.PL
make
make test
make install
else
echo -e  "####$Config is already present #####"
fi
#
#---------------------------------------------------------------------------------
#Installing Parallel-ForkManager-0.7.5 package
#---------------------------------------------------------------------------------
parallel="Parallel::ForkManager"
package=`perl /var/simnet/enm-ni-simdep/scripts/checkInstall.pl $parallel`
echo $package
if [[ $package != 1 ]]
then
cp $CWD/simdep/pkg/Parallel-ForkManager-0.7.5.tar.gz /usr/lib/perl5/
cd /usr/lib/perl5/
tar xzf Parallel-ForkManager-0.7.5.tar.gz
cd Parallel-ForkManager-0.7.5/
perl Makefile.PL && make test && make install
else
echo -e "####$parallel is already installed####"
fi
