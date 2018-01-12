FROM centos:7
MAINTAINER Lawrence Stubbs <technoexpressnet@gmail.com>

RUN yum install -y wget bind bind-utils iproute net-tools sysvinit-tools cronie which whois \
    && rpm -i https://nmap.org/dist/ncat-7.60-1.x86_64.rpm \
    && ln -s /usr/bin/ncat /usr/bin/nc \
    && yum update -y

# Fixes issue with running systemD inside docker builds 
# From https://github.com/gdraheim/docker-systemctl-replacement
COPY systemctl.py /usr/bin/systemctl.py
RUN cp -f /usr/bin/systemctl /usr/bin/systemctl.original \
    && chmod +x /usr/bin/systemctl.py \
    && cp -f /usr/bin/systemctl.py /usr/bin/systemctl
COPY etc /etc/   

# Install Webmin repositorie and Webmin
RUN wget http://www.webmin.com/jcameron-key.asc -q && rpm --import jcameron-key.asc \
   && yum install webmin -y && rm jcameron-key.asc

RUN yum install yum-versionlock -y && yum versionlock systemd   

RUN sed -i 's#options {#acl trusted {\n\t172.17.0.0/16;\n\tlocalhost;\n\tlocalnets;\n};\noptions {#' /etc/named.conf \
	&& sed -i 's#recursion yes;#allow-recursion {\n\ttrusted;\n};\nallow-query-cache {\n\ttrusted;\n};\nrecursion yes;#' /etc/named.conf \
    && sed -i 's#10000#9090#' /etc/webmin/miniserv.conf \
	&& systemctl.original enable named.service webmin.service containerstartup.service \
    && sed -i 's#localhost.key#localhost.key\ncat \"/etc/letsencrypt/archive/$HOSTNAME/privkey1.pem\" \"/etc/letsencrypt/archive/$HOSTNAME/cert1.pem\" >/etc/webmin/miniserv.pem#' /etc/containerstartup.sh \
    && chmod +x /etc/containerstartup.sh \
    && mv -f /etc/containerstartup.sh /containerstartup.sh \
    && echo "root:bind9" | chpasswd
    
ENV FORWARDIP 0.0.0.0  
ENV FORWARDPORT 5353  
ENV FORWARDTYPE none 
ENV WEBMINPORT 9090

EXPOSE 53/udp 53/tcp 9090/tcp 9090/udp 

ENTRYPOINT ["/usr/bin/systemctl","default","--init"]