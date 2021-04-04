#!/bin/bash -e
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"

init(){
  source "${SCRIPT_DIR}/env"
  mkdir -p "${TMP_CONF_DIR}"
}

clean_conf(){
  find "${TMP_CONF_DIR}" -name \*.conf -delete
}

generate_conf(){
  for SVC_FQDN in $(list_services); do
    export SVC_NAME=$(echo "$SVC_FQDN" | cut -d. -f1)
    CONFIG_FILE="${TMP_CONF_DIR}/${SVC_NAME}.conf"
    envsubst \$SVC_FQDN,\$SVC_NAME < "$SCRIPT_DIR/../etc/server.conf" > "$CONFIG_FILE"
  done
}

get_md5sum(){
  md5sum $1 | cut -d" " -f1
}

list_services(){
  echo "photostream.web.svc.node0.local"
}

reload_conf(){
  if sudo nginx -T >/dev/null 2>&1; then
    echo "Reloading the configuration"
    sudo nginx -T
    sudo nginx -s reload || exit 1
  else
    echo "Cannot load the new configuration: configuration invalid"
  fi
}

update_conf(){
  RELOAD="${TMP_CONF_DIR}/reload"
  for NEW_CONF in $(find "${TMP_CONF_DIR}" -name \*.conf); do
    FILENAME="$(basename "$NEW_CONF")"
    OLD_CONF="${CONF_DIR}/${FILENAME}"
    if [[ -e "${OLD_CONF}" ]]; then
      if [[ "$(get_md5sum "${NEW_CONF}")" != "$(get_md5sum "${OLD_CONF}")" ]]; then
        echo "Modifying $(echo "$FILENAME" | cut -d. -f1)"
        touch "${RELOAD}"
      fi
    else
      echo "Adding $(echo "$FILENAME" | cut -d. -f1)"
      touch "${RELOAD}"
    fi
  done

  for OLD_CONF in $(find "${CONF_DIR}" -name \*.conf); do
    FILENAME="$(basename "$OLD_CONF")"
    NEW_CONF="${TMP_CONF_DIR}/${FILENAME}"
    if [[ ! -e "${NEW_CONF}" ]]; then
      echo "Removing $(echo "$FILENAME" | cut -d. -f1)"
      touch "${RELOAD}"
    fi
  done

  if [[ -e "${RELOAD}" ]]; then
    echo "Change in the configuration detected."
    rm "${RELOAD}"
    sudo rsync --archive --checksum --delete "$TMP_CONF_DIR/" "$CONF_DIR"
    reload_conf
  fi
}

init
clean_conf
generate_conf
update_conf