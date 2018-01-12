#!/bin/bash
export SSHPORT
export WEBMINPORT
export FORWARDIP  
export FORWARDPORT
export FORWARDTYPE

if [ -f "/etc/letsencrypt/archive/$HOSTNAME/cert1.pem" ]
then
    ln -sf "/etc/letsencrypt/archive/$HOSTNAME/cert1.pem" /etc/pki/tls/certs/localhost.crt
    ln -sf "/etc/letsencrypt/archive/$HOSTNAME/privkey1.pem" /etc/pki/tls/private/localhost.key
fi

source /etc/container.ini
ip_good='Connected'
if [ "$FORWARDIP" != "0.0.0.0" ] && nc -w1 -z -v "$FORWARDIP" $FORWARDPORT 2>&1 | grep -q "$ip_good"
then
    if [ "$FORWARDTYPE" == "only" ] || [ "$FORWARDTYPE" == "first" ]
    then 
        sed -i "s#recursion yes;#recursion yes;\nforwarders { //\n\t\t$FORWARDIP port $FORWARDPORT; //\n\t};\nforward $FORWARDTYPE;#" /etc/named.conf   
        sed -i "s#TYPE=none#TYPE=$FORWARDTYPE#" /etc/container.ini
    else
        sed -i "s#recursion yes;#recursion yes;\nforwarders { //\n\t\t$FORWARDIP port $FORWARDPORT; //\n\t};#" /etc/named.conf
        sed -i "s#forward only;# #" /etc/named.conf
        sed -i "s#forward first;# #" /etc/named.conf
    fi
    sed -i "s#IP=0.0.0.0#IP=$FORWARDIP#" /etc/container.ini
    sed -i "s#PORT=$PORT#PORT=$FORWARDPORT#" /etc/container.ini
    sed -i "s#FORWARDINGSET=no#FORWARDINGSET=yes#" /etc/container.ini       
    systemctl restart named  
elif [ "$FORWARDIP" == "0.0.0.0" ] && [ "$FORWARDINGSET" == "yes" ]
then
    sed -i "s#forwarders { //# #" /etc/named.conf
    sed -i "s#$IP port $PORT; //# #" /etc/named.conf
    sed -i "s#forward only;# #" /etc/named.conf
    sed -i "s#forward first;# #" /etc/named.conf
    sed -i "s#TYPE=$TYPE#TYPE=none#" /etc/container.ini
    sed -i "s#IP=$IP#IP=0.0.0.0#" /etc/container.ini
    sed -i "s#PORT=$FORWARDPORT#PORT=$PORT#" /etc/container.ini
    sed -i "s#FORWARDINGSET=yes#FORWARDINGSET=no#" /etc/container.ini       
	systemctl restart named 
fi

source <( grep listen /etc/webmin/miniserv.conf ) 
if [[ $WEBMINPORT =~ ^[0-9]+$ ]] && [ "$WEBMINPORT" != "$listen" ]
then  
    systemctl stop webmin
    sed -i "s#$listen#$WEBMINPORT#" /etc/webmin/miniserv.conf
    systemctl start webmin
elif [ "$WEBMINPORT" == "off" ]
then
    systemctl disable webmin.service   
    systemctl stop webmin    
elif [[ $WEBMINPORT =~ ^[0-9]+$ ]] && ! pgrep -x "miniserv.pl" > /dev/null
then   
    systemctl enable webmin.service 
    systemctl start webmin 
fi
