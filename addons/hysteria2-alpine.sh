#!/bin/sh

apk add wget nftables

PASS="$(cat /proc/sys/kernel/random/uuid)"
DOMAIN="hysteria.example.com"
TYPE="server"

if [ -n "$2" ]; then
  PASS=$2
fi

if [ -n "$1" ]; then
  DOMAIN=$1
fi

if [ -n "$3" ]; then
  TYPE="client"
fi

echo_hysteria_config_yaml() {
  if [ "$TYPE" = "server" ]; then
  cat << EOF
listen: :443

acme:
  domains:
    - $DOMAIN
  email: hysteria@$DOMAIN

tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

speedTest: True

auth:
  type: password
  password: $PASS

masquerade:
  listenHTTP: :80 
  listenHTTPS: :443 
  forceHTTPS: true
  type: proxy
  proxy:
    url: https://updates.cdn-apple.com/
    rewriteHost: true
EOF
  else
  cat << EOF
server: $DOMAIN:443 

auth: $PASS

bandwidth: 
  up: 200 mbps
  down: 200 mbps

socks5:
  listen: 127.0.0.1:1080 

tcpForwarding:
  - listen: 127.0.0.1:6600 
    remote: 127.0.0.1:6600 

udpForwarding:
  - listen: 127.0.0.1:5300 
    remote: 127.0.0.1:5300 
    timeout: 20s 
EOF
  fi
}

echo_hysteria_autoStart(){
  cat << EOF
#!/sbin/openrc-run

name="hysteria"

command="/usr/local/bin/hysteria"
command_args="$TYPE --config /etc/hysteria/config.yaml"

pidfile="/var/run/${name}.pid"

command_background="yes"

depend() {
        need networking
}

EOF
}


wget -O /usr/local/bin/hysteria https://download.hysteria.network/app/latest/hysteria-linux-amd64-avx  --no-check-certificate
chmod +x /usr/local/bin/hysteria

mkdir -p /etc/hysteria/

echo_hysteria_config_yaml > "/etc/hysteria/config.yaml"

echo_hysteria_autoStart > "/etc/init.d/hysteria"
chmod +x /etc/init.d/hysteria

echo "Hysteria2安装完成"
echo "密码: $PASS"
echo "域名: $DOMAIN"
echo "类型: $TYPE"
echo "请修改 /etc/hysteria/config.yaml 配置文件"
