FROM   balenalib/raspberrypi3

# Make sure we don't get notifications we can't answer during building.
ENV    DEBIAN_FRONTEND noninteractive

#
# Default skwr config
#
RUN groupadd -g 9999 skwr \
 && useradd -r -u 9999 -g skwr skwr
ENV PATH="/opt/module/bin:$PATH"
ENTRYPOINT ["run.sh"]
HEALTHCHECK --start-period=30s --interval=60s --timeout=5s --retries=3 \
    CMD healthcheck.sh || exit 1

#
# Add module and packages
#
RUN apt-get update \
 && apt-get install -y nmap gettext-base nginx rsync \
 && apt-get clean
RUN mkdir -p /run/nginx \
 && echo 'skwr	ALL=(root) NOPASSWD: /bin/cp /tmp/nginx.conf /etc/nginx/nginx.conf' > /etc/sudoers.d/nginx \
 && echo 'skwr	ALL=(root) NOPASSWD: /usr/sbin/nginx' >> /etc/sudoers.d/nginx \
 && echo 'skwr  ALL=(root) NOPASSWD: /usr/bin/rsync --archive --delete /tmp/conf.d/ /etc/nginx/conf.d' >> /etc/sudoers.d/nginx

# Add module
COPY module /opt/module
RUN chmod +x /opt/module/bin/*.sh

EXPOSE 80
EXPOSE 443

USER skwr

