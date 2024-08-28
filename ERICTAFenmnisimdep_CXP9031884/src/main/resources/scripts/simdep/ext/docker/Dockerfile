FROM armdockerhub.rnd.ericsson.se/opensuse:latest
MAINTAINER BalaMounika Gamini <balamounika.gamini@tcs.com>

LABEL Description="This image is used to start NETSim" Vendor="Ericsson" Version="1.0"

# OS Installation: Getting basic tools installed
RUN zypper ar -Gf -n packman http://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Leap_42.1/ packman   \
    && zypper ar -G http://download.opensuse.org/repositories/devel:/languages:/perl/SLE_12_SP4/devel:languages:perl.repo   \
    && zypper --non-interactive install     bc     bind-utils     curl       ftp       wget     ed     kmod     less       vim     libreadline5-32bit       libz1-32bit       libopenssl0_9_8-32bit       libXtst6-32bit       libXi6-32bit       libcrypto.so.1.0.0       ncurses-32bit     net-tools     openssh     perl       "perl(Expect)"       "perl(Net::OpenSSH)"       "perl(Config::Tiny)"     sudo     tar       unzip       zip     xinetd     xterm     cron    ntp   expect    python    which     python-pip     python-mako    rsh       rsh-server    \
    && zypper clean -a

RUN echo -e "shroot\nshroot" | passwd
RUN groupadd netsim   \
    && useradd netsim -m -g netsim    \
    && usermod -m -d /netsim netsim   \
    && echo 'netsim:netsim' | chpasswd   \
    && chown -R netsim:netsim /netsim/
ARG SIMS_RELEASE_VERSION
ENV SRV=${SIMS_RELEASE_VERSION}
ARG PRODUCT_SET_VERSION
ENV PSV=${PRODUCT_SET_VERSION}
RUN echo "${SIMS_RELEASE_VERSION} ${PRODUCT_SET_VERSION}"
ENV TMP_SIMDEP_LINK=https://arm1s11-eiffel004.eiffel.gic.ericsson.se:8443/nexus/content/repositories/releases/com/ericsson/ci/simnet/ERICTAFenmnisimdep_CXP9031884/1.5.677/ERICTAFenmnisimdep_CXP9031884-1.5.677.jar
ENV SimsListLink=https://arm901-eiffel004.athtem.eei.ericsson.se:8443/nexus/content/repositories/simnet/com/ericsson/simnet/docker/requiredSims.txt
COPY requiredSims.txt /netsim/simdepContents/
COPY genstats_rollout_docker.sh /netsim/
RUN chmod 777 /netsim/simdepContents/  \
    && mkdir -p /pms_tmpfs  \
    && chown -R netsim:netsim /pms_tmpfs/  \
    && chmod -R 777 /pms_tmpfs/   \
    && sed -i '/tmpfs/d' /etc/fstab   \
    && echo "tmpfs /pms_tmpfs tmpfs rw,size=72G 0 0" >> /etc/fstab
WORKDIR /netsim/simdepContents
RUN curl -Lk ${SimsListLink} -o requiredSims.txt \
    && curl -Lk ${TMP_SIMDEP_LINK} -o ERICTAFenmnisimdep_CXP9031884.jar   \
    && unzip -j ERICTAFenmnisimdep_CXP9031884.jar "scripts/simdep/ext/docker/ci.sh" -d .   \
    && rm -rf ERICTAFenmnisimdep_CXP9031884.jar   \
    && chmod +x ci.sh   \
    && ./ci.sh $SRV $PSV > ci.txt   \
    && cat ci.txt   \
    && rm jq*.tar   \
    && chown -R netsim:netsim /netsim/simdepContents   \
    && pwd \
    && ls -la
WORKDIR /var/simnet/enm-ni-simdep/
RUN LINK=""   \
    && if [[ "${SRV/./}" -le "174" ]]; then         echo "RELEASE: Static SimDep Enabled";        LINK=${TMP_SIMDEP_LINK};      else        echo "RELEASE: Dynamic SimDep Enabled";        LINK="$(cd /netsim/simdepContents/ \
    && grep SIMDEP_ ci.txt | cut -d"=" -f 2)";      fi   \
    && curl -O "${LINK}"   \
    && pwd \
    && ls -la   \
    && unzip $(echo *.jar)   \
    && ls | grep -v scripts | xargs rm -rf   \
    && pwd \
    && ls -la
RUN chmod -R +x /var/simnet/enm-ni-simdep/scripts/*   \
    && ssh-keygen -A   \
    && /usr/sbin/sshd   \
    && cd /var/simnet/enm-ni-simdep/scripts/netsim_install/bin/    \
    && mkdir /var/netsim/ \ # put in simdep   \
    && readonly NETSIM_VERSION=$(cd /netsim/simdepContents/ \
    && grep NETSIM_ ci.txt | cut -d"=" -f 2)   \
    && time ./install_netsim.sh -r $NETSIM_VERSION -n portal -e yes -p yes   \
    && su netsim -c "/netsim/inst/stop_netsim fast"   \
    && /netsim/inst/bin/setup_fd_server.sh   \
    && chown -R netsim:netsim /netsim/netsimdir   \
    && rm -rf /netsim/R29D/saveinstallation/*   \
    && rm -rf /var/netsim/*.zip   \
    && pwd \
    && ls -la /netsim
RUN sed -i s/^LC_CTYPE=/#LC_CTYPE=/ /netsim/inst/netsimgui/jsrc/runNetsim
RUN chmod u+s /bin/ping
RUN echo 'UseDNS no' >> /etc/ssh/sshd_config
RUN ln -s /lib/libreadline.so.5.2 /lib/libreadline.so.6
RUN ln -s /lib/libhistory.so.5.2 /lib/libhistory.so.6
RUN mkdir -p /netsim/docker   \
    && mv /var/simnet/enm-ni-simdep/scripts/simdep/ext/docker /netsim/   \
    && cp /var/simnet/enm-ni-simdep/scripts/simdep/utils/netsim/startNes.pl /netsim/docker   \
    && cp /netsim/docker/avail_IpAddr_IPv4.txt /var/simnet/enm-ni-simdep/scripts/simdep/dat/  \
    && cp /netsim/docker/avail_IpAddr_IPv6.txt /var/simnet/enm-ni-simdep/scripts/simdep/dat/  \
    && chown -R netsim:netsim /netsim/docker   \
    && chmod -R +x /netsim/docker   \
    && pwd \
    && ls -la
RUN /usr/sbin/sshd    \
    && time xinetd -stayalive   \
    && time su netsim -c /netsim/inst/start_netsim   \
    && if [[ "${RELEASE}" == "" ]]; then        ls -la /netsim/docker        \
    && time (cd /netsim/docker \
    && ./downloadSims.sh "${SRV}" "${PSV}") ;      fi   \
    && time su netsim -c "echo '.show allsimnes' | /netsim/inst/netsim_shell"
RUN HSRV=`echo "${SRV}" | perl -lne 'if(/(\d+).(\d+)/){print $1}'`   \
    && echo "HSRV=${HSRV}"
WORKDIR /netsim/simdepContents/
RUN  /usr/sbin/sshd   \
      && time xinetd -stayalive \
      && time su netsim -c /netsim/inst/start_netsim \
      && LTE=$( cat ci.txt | grep "LTE=" | cut -d "=" -f 2)  \
      && CORE=$( cat ci.txt | grep "CORE=" | cut -d "=" -f 2) \
      && SIMS="$(echo ${LTE}:${CORE} | sed -e 's/.zip//g;s/:/|/g')" \
      && cd /var/simnet/enm-ni-simdep/scripts/simdep/bin/  \
      && echo $LTE \
      && echo $CORE \
      && echo $SIMS \
      && LTE_SIMS=$(echo $LTE | sed -e 's/.zip//g') \
      && CORE_SIMS=$(echo $CORE|sed -e 's/.zip//g') \
      && echo "./rollout.py -overwrite -release ${SRV} -serverType VM -deploymentType mediumDeployment -simLTE ${LTE_SIMS} -simWRAN NO_NW_AVAILABLE -simCORE ${CORE_SIMS} '-LTE /sims/O17/ENM/18.10/mediumDeployment/LTE/5KLTE -CORE /sims/O17/ENM/18.10/mediumDeployment/CORE -WRAN /sims/O17/ENM/18.10/mediumDeployment/WRAN/5KWRAN' -securityTLS off -securitySL2 off -masterServer 172.17.0.2 -ciPortal yes -docker yes -switchToRv no -IPV6Per yes -installType online" \
      && time ./rollout.py -overwrite -release ${SRV} -serverType VM -deploymentType mediumDeployment -simLTE ${LTE_SIMS} -simWRAN NO_NW_AVAILABLE -simCORE ${CORE_SIMS} '-LTE /sims/O17/ENM/18.10/mediumDeployment/LTE/5KLTE -CORE /sims/O17/ENM/18.10/mediumDeployment/CORE -WRAN /sims/O17/ENM/18.10/mediumDeployment/WRAN/5KWRAN' -securityTLS off -securitySL2 off -masterServer 172.17.0.2 -ciPortal yes -docker yes -switchToRv no -IPV6Per yes -installType online  \
      && echo "SIMS=${SIMS}" \
RUN chmod 755 /netsim/docker/entrypoint.sh
RUN chmod 755 /netsim/docker/avail_IpAddr_IPv6.txt
ENTRYPOINT ["/netsim/docker/entrypoint.sh"]
CMD ["-regExp" "LTE02" "-numOfNes" "1" "-numOfIpv6Nes" "0"]
EXPOSE 22
#/tcp
#RUN mkdir /netsim/scripts
#COPY setPort.sh /netsim/scripts/
#RUN chmod 777 /netsim/scripts/setPort.sh
