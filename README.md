# BIND-9

Passing the following environment options at run time controls operations:
```
-e FORWARDIP=0.0.0.0  
-e FORWARDPORT=5353  
-e FORWARDTYPE=none 
-e WEBMINPORT=9090
```

```
docker run -d --name bind \
-p 53:53/tcp -p 53:53/udp -p 82:80/tcp -p 9090:9090/tcp -p 9090:9090/udp \
-v bind-etc:/etc -v bind-log:/var/log -v bind-lib:/var/lib/named \
-v /etc/resolv.conf:/etc/resolv.conf:ro \
--restart=always --dns=127.0.0.1 --hostname=dns.bind.host technoexpress/bind-9
```

This build also assume reverse proxy is setup. 
This build setup to use https://github.com/adi90x/rancher-active-proxy

```
-v /nginx/rancher-active-proxy/letsencrypt/archive/dns.bind.host:/etc/letsencrypt/archive/dns.bind.host \
-l rap.host=dns.bind.host \
-l rap.le_host=dns.bind.host \
-l rap.https_method=noredirect \
```

