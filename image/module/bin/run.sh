#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`
set -e

init(){
  CONF_DIR="/etc/nginx/conf.d"
  IP_RANGE=`ip addr | grep eth0 | grep inet | awk '{print $2}' | sed 's:/[0-9]*$:/24:'`
  TMP_CONF_DIR="/tmp/conf.d"
  envsubst \$DOMAIN < $SCRIPT_DIR/../etc/nginx.conf > /tmp/nginx.conf
  sudo cp /tmp/nginx.conf /etc/nginx/nginx.conf
  rm /tmp/nginx.conf
  mkdir -p $TMP_CONF_DIR
}

start_nginx(){
  sudo nginx -v
  sudo nginx -T
  sudo nginx

  NGINX_UP="0"
  echo -n "Waiting for nginx to be online "
  while [ "$NGINX_UP" = "0" ]; do
    echo -n "."
    sleep 5
    NGINX_UP=`ps -ef | grep nginx | grep process | wc -l`
  done
  echo
  # Let SKWR know that the container is up and running
  echo "[`hostname -s`] Started"
}

check_nginx(){
  # Exit if nginx died
  NGINX_UP=`ps -ef | grep nginx | grep process | wc -l`
  if [ "$NGINX_UP" = 0 ]; then
    echo "[ERROR] nginx died"
    exit 1
  fi
}

clean_servers(){
  for SERVER in `ls $TMP_CONF_DIR | sed "s:\.[^.]*$::"`; do
    unset RM
    curl -s -o /dev/null http://$SERVER:8000 || RM="1"
    if [ -n "$RM" ]; then
      echo "Removing $SERVER: unreachable"
      rm -f $TMP_CONF_DIR/$SERVER.conf
      touch $TMP_CONF_DIR/reload
    fi
  done
}

discover_servers(){
  nmap -p 8000 $IP_RANGE | egrep 'Nmap scan report for |8000/tcp ' | grep -B1 'open' | grep ' for ' | awk '{print $5}' | grep -v "\.0\.1" | while read FQDN; do
    export FQDN
    export SERVER=`echo $FQDN | cut -d. -f1`
    export NAME=`echo $SERVER | sed -e "s:^web-::" -e "s:-server$::"`
    CONFIG_FILE="$TMP_CONF_DIR/$SERVER.conf"
    if [ ! -e "$CONFIG_FILE" ]; then
      echo "Adding $SERVER"
      envsubst \$FQDN,\$NAME < $SCRIPT_DIR/../etc/server.conf > $CONFIG_FILE
      touch $TMP_CONF_DIR/reload
    fi
  done
}

update_services(){
  clean_servers
  discover_servers
  reload_conf
}

reload_conf(){
  if [ ! -e "$TMP_CONF_DIR/reload" ]; then
	  return
  fi
  rm "$TMP_CONF_DIR/reload"
  sudo rsync --archive --delete $TMP_CONF_DIR/ $CONF_DIR
  echo "Change in the configuration detected"
  if sudo nginx -T >/dev/null 2>&1; then
    echo "Reloading the configuration"
    sudo nginx -T
    sudo nginx -s reload || exit 1
  else
    echo "Cannot load the new configuration: configuration invalid"
  fi
}

init
start_nginx
while true; do
  check_nginx
  update_services

  # Wait for the start of the next minute
  sleep `date +%s.%N | awk '{ print (60 - $1 % 60)}'`
done
