#!/bin/sh

CWD="/var/simnet/enm-ni-simdep/scripts"
ln -s /usr/lib64/perl5 /usr/lib/perl5
mkdir -p /usr/lib/perl5/5.10.0/x86_64-linux-thread-multi/IO/
mkdir -p /usr/lib/perl5/vendor_perl/5.10.0/
mkdir -p /usr/lib/perl5/vendor_perl/5.10.0/Net
mkdir -p /usr/lib/perl5/vendor_perl/5.10.0/Config

#
#---------------------------------------------------------------------------------
#Installing IO-Tty-1.07 package
#---------------------------------------------------------------------------------

IO="IO::Tty"
cp $CWD/simdep/pkg/IO-Tty-1.07.tar.gz /usr/lib/perl5/5.10.0/x86_64-linux-thread-multi/IO/
cd /usr/lib/perl5/5.10.0/x86_64-linux-thread-multi/IO/
tar xzf IO-Tty-1.07.tar.gz
cd IO-Tty-1.07/
perl Makefile.PL
make
make test
make install
#
#---------------------------------------------------------------------------------
#Installing Expect-1.15 package
#---------------------------------------------------------------------------------

cp  $CWD/simdep/pkg/Expect-1.15.tar.gz /usr/lib/perl5/./vendor_perl/5.10.0/
cd /usr/lib/perl5/./vendor_perl/5.10.0/
tar xzf Expect-1.15.tar.gz
cd Expect-1.15/
perl Makefile.PL
make
make test
make install

#
#---------------------------------------------------------------------------------
#Installing Net-OpenSSH-0.60 package
#---------------------------------------------------------------------------------

cp $CWD/simdep/pkg/Net-OpenSSH-0.60.tar.gz /usr/lib/perl5/./vendor_perl/5.10.0/Net/
cd /usr/lib/perl5/./vendor_perl/5.10.0/Net/
PWD=`pwd`
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
#
#---------------------------------------------------------------------------------
#Installing Config-Tiny-2.12 package
#---------------------------------------------------------------------------------

cp $CWD/simdep/pkg/Config-Tiny-2.12.tar.gz /usr/lib/perl5/./vendor_perl/5.10.0/Config/
cd /usr/lib/perl5/./vendor_perl/5.10.0/Config/
tar xzf Config-Tiny-2.12.tar.gz
cd Config-Tiny-2.12/
perl Makefile.PL
make
make test
make install

#
#---------------------------------------------------------------------------------
#Installing Parallel-ForkManager-0.7.5 package
#---------------------------------------------------------------------------------

cp $CWD/simdep/pkg/Parallel-ForkManager-0.7.5.tar.gz /usr/lib/perl5/
cd /usr/lib/perl5/
tar xzf Parallel-ForkManager-0.7.5.tar.gz
cd Parallel-ForkManager-0.7.5/
perl Makefile.PL && make test && make install

