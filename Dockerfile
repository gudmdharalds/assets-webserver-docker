
# Use CentOS 7.1 as base
FROM centos:7.1.1503

VOLUME [ "/var/www/static-webserver/webroot/" ]

MAINTAINER Gudmundur Haraldsson <gudm.d.haralds@gmail.com> 

# Needed to make things work
RUN yum swap -y fakesystemd systemd && \
    yum install -y systemd-devel

# Get newest caches, install utilities,
# and install EPEL-repo. Then install
# security updates.
RUN yum makecache fast &&	\
    yum install -y		\
      iputils			\
      iproute			\
      net-utils			\
      hostname			\
      unzip			\
      zip			\
      httpd			\
      epel-release &&		\
    yum update -y &&		\
    yum clean all 


# Install security updates -- do not skip this.
ADD dontcache.txt /tmp/

RUN yum makecache fast                                          && \
    yum update -y                                               && \
    yum clean all

#
# Configure Apache a bit: Remove stuff we do not need
# and might only cause performance or security issues.
#
# Make sure Sendfile is turned ON as this is a webserver
# delivering static content.

RUN rm -f /etc/httpd/conf.d/welcome.conf											&& \
    rm -f /etc/httpd/conf.modules.d/00-dav.conf											&& \
    rm -f /etc/httpd/conf.modules.d/00-lua.conf											&& \
    rm -f /etc/httpd/conf.modules.d/00-proxy.conf										&& \
    rm -f /etc/httpd/conf.modules.d/01-cgi.conf											&& \
    rm -f /etc/httpd/conf.d/autoindex.conf											&& \
    rm -f /etc/httpd/conf.d/userdir.conf											&& \
    sed 's/Listen 80$/Listen 8080/'							-i /etc/httpd/conf/httpd.conf			&& \
    sed 's/EnableMMAP on/EnableMMAP off/'     	                                  	-i /etc/httpd/conf/httpd.conf			&& \
    sed 's/EnableSendfile off/EnableSendfile on/'	                               	-i /etc/httpd/conf/httpd.conf			&& \
    sed 's/LoadModule actions_module modules\/mod_actions.so//'				-i /etc/httpd/conf.modules.d/00-base.conf	&& \
    sed 's/LoadModule authn_dbd_module modules\/mod_authn_dbd.so//'             	-i /etc/httpd/conf.modules.d/00-base.conf	&& \
    sed 's/LoadModule authn_dbm_module modules\/mod_authn_dbm.so//'             	-i /etc/httpd/conf.modules.d/00-base.conf	&& \
    sed 's/LoadModule authn_socache_module modules\/mod_authn_socache.so//'		-i /etc/httpd/conf.modules.d/00-base.conf	&& \
    sed 's/LoadModule authz_dbd_module modules\/mod_authz_dbd.so//'             	-i /etc/httpd/conf.modules.d/00-base.conf	&& \
    sed 's/LoadModule authz_dbm_module modules\/mod_authz_dbm.so//'             	-i /etc/httpd/conf.modules.d/00-base.conf	&& \
    sed 's/LoadModule authz_groupfile_module modules\/mod_authz_groupfile.so//' 	-i /etc/httpd/conf.modules.d/00-base.conf	&& \
    sed 's/LoadModule authz_owner_module modules\/mod_authz_owner.so//'         	-i /etc/httpd/conf.modules.d/00-base.conf	&& \
    sed 's/LoadModule autoindex_module modules\/mod_autoindex.so//'			-i /etc/httpd/conf.modules.d/00-base.conf	&& \
    sed 's/LoadModule cache_module modules\/mod_cache.so//'				-i /etc/httpd/conf.modules.d/00-base.conf	&& \
    sed 's/LoadModule cache_disk_module modules\/mod_cache_disk.so//'			-i /etc/httpd/conf.modules.d/00-base.conf	&& \
    sed 's/LoadModule data_module modules\/mod_data.so//'                       	-i /etc/httpd/conf.modules.d/00-base.conf	&& \
    sed 's/LoadModule dbd_module modules\/mod_dbd.so//'					-i /etc/httpd/conf.modules.d/00-base.conf	&& \
    sed 's/LoadModule echo_module modules\/mod_echo.so//'                       	-i /etc/httpd/conf.modules.d/00-base.conf	&& \
    sed 's/LoadModule include_module modules\/mod_include.so//'                 	-i /etc/httpd/conf.modules.d/00-base.conf	&& \
    sed 's/LoadModule logio_module modules\/mod_logio.so//'				-i /etc/httpd/conf.modules.d/00-base.conf	&& \
    sed 's/LoadModule slotmem_plain_module modules\/mod_slotmem_plain.so//'		-i /etc/httpd/conf.modules.d/00-base.conf	&& \
    sed 's/LoadModule slotmem_shm_module modules\/mod_slotmem_shm.so//'			-i /etc/httpd/conf.modules.d/00-base.conf	&& \
    sed 's/LoadModule socache_dbm_module modules\/mod_socache_dbm.so//'			-i /etc/httpd/conf.modules.d/00-base.conf	&& \
    sed 's/LoadModule socache_memcache_module modules\/mod_socache_memcache.so//'	-i /etc/httpd/conf.modules.d/00-base.conf	&& \
    sed 's/LoadModule socache_shmcb_module modules\/mod_socache_shmcb.so//'		-i /etc/httpd/conf.modules.d/00-base.conf	&& \
    sed 's/LoadModule status_module modules\/mod_status.so//'				-i /etc/httpd/conf.modules.d/00-base.conf	&& \
    sed 's/LoadModule substitute_module modules\/mod_substitute.so//'			-i /etc/httpd/conf.modules.d/00-base.conf	&& \
    sed 's/LoadModule suexec_module modules\/mod_suexec.so//'				-i /etc/httpd/conf.modules.d/00-base.conf	&& \
    sed 's/LoadModule userdir_module modules\/mod_userdir.so//'				-i /etc/httpd/conf.modules.d/00-base.conf	&& \
    sed 's/LoadModule version_module modules\/mod_version.so//'				-i /etc/httpd/conf.modules.d/00-base.conf	


# Add our own Apache configuration files
ADD apache*.conf /etc/httpd/conf.d/


# Let apache-user own /var/www, so we
# can write into it later on
RUN chown -R apache:apache /var/www/ && \
    chown -R apache:apache /var/log/httpd && \
    chown -R apache:apache /run/httpd


# From here on, we run as the apache-user
USER apache


# Apache will listen on this port
EXPOSE 8080


# Let httpd be launched when 'docker run'-ed
ENTRYPOINT /usr/sbin/httpd -DFOREGROUND

