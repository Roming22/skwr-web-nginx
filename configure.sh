#!/bin/bash -e
SCRIPT_DIR=`cd $(dirname $0); pwd`

SECRET="$SCRIPT_DIR/etc/secret.env"
[[ -e "$SECRET" ]] && source <(sed -e 's:=:=":' -e 's:$:":' $SECRET)

set_mandatory_value(){
	PROMPT=$2
	VAR=$1
	[[ -n "${!VAR}" ]] && DEFAULT="${!VAR}" || unset DEFAULT
	read -p "$PROMPT`[[ -n "$DEFAULT" ]] && echo -e " [$DEFAULT]"`: " INPUT
	export $VAR="${INPUT:-$DEFAULT}"
	[[ -z "${!VAR}" ]] && echo "Invalid value: Do not leave blank" && exit 1
	VAR_LIST="$VAR_LIST $VAR"
	unset INPUT
}

write_secret(){
    VAR_LIST=( $VAR_LIST )
    for VAR in ${VAR_LIST[@]}; do
        echo "$VAR=${!VAR}"
    done > $SECRET
}

get_vars(){
    for VAR in DOMAIN COUNTRY; do
        set_mandatory_value $VAR "Enter the `echo $VAR | tr '[:upper:]' '[:lower:]'`"
    done
	write_secret
}

generate_certificate(){
    envsubst < $SCRIPT_DIR/docker/module/etc/certificate.cfg > $CERTIFICATE/$DOMAIN.cfg
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $CERTIFICATE/$DOMAIN.key -out $CERTIFICATE/$DOMAIN.crt -config $CERTIFICATE/$DOMAIN.cfg << EOF






EOF
}

[ -e "$SECRET" ] || get_vars
CERTIFICATE="$SCRIPT_DIR/volumes/secret/certs"
for FILE in $CERTIFICATE/$DOMAIN.crt $CERTIFICATE/$DOMAIN.key; do
	[ -e "$FILE" ] || generate_certificate
done
