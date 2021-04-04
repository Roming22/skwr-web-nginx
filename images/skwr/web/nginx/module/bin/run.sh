#!/bin/bash -e
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"
set -e

init(){
  source "${SCRIPT_DIR}/env"
  envsubst "\$DOMAIN" < "$MODULE_DIR/etc/nginx.conf" > /tmp/nginx.conf
  sudo cp /tmp/nginx.conf "/etc/nginx/nginx.conf"
  rm /tmp/nginx.conf
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
    NGINX_UP=$(pgrep nginx -a | grep process | wc -l)
  done
  echo
  # Let SKWR know that the container is up and running
  echo "[$(hostname -s)] Started"

  tail -f /var/log/nginx/*.log &
}

check_nginx(){
  # Exit if nginx died
  NGINX_UP=$(pgrep nginx -a | grep process | wc -l)
  if [ "$NGINX_UP" = 0 ]; then
    echo "[ERROR] nginx died"
    exit 1
  fi
}

init
start_nginx
while true; do
  $SCRIPT_DIR/discover.sh

  # Wait for the start of the next minute
  sleep "$(date +%s.%N | awk '{ print (60 - $1 % 60)}')"
done
