# NGINX reverse proxy for [SKWR](https://github.com/Roming22/skwr)

## Goal

Entry point for everything web related.
* Do not add your website to this image.
* Create a container with the website accessible through the port `8000`.
* Add `DOCKER_NETWORK="web"` to `etc/service.cfg` so that your container starts on the same network as nginx.
* The `nginx` container will automatically find containers which accept connections on the port `8000` and will add them to its configuration under `$DOMAIN/$CONTAINER_NAME`.

You can check the `skwr-python-server` for an example.


## Configuration

Run `configure.sh` before starting the container to create the secret holding your configuration and default certificates for https.


### HTTPS support

Add your certificates to `volumes/etc/secret/certs`. They should be named `$DOMAIN.crt` and `$DOMAIN.key`.
