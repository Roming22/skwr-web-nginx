FROM   alpine

#
# Default skwr config
#
RUN addgroup -g 9999 skwr \
    && adduser -G skwr -S -u 9999 skwr
ENV PATH="/opt/module/bin:$PATH"
HEALTHCHECK --start-period=10s --interval=30s --timeout=5s --retries=3 \
    CMD healthcheck.sh || exit 1

#
# Add packages
#
RUN apk add bash bind-tools curl gettext nginx nmap rsync sudo

RUN mkdir -p /run/nginx \
    && echo 'skwr	ALL=(root) NOPASSWD: /bin/cp /tmp/nginx.conf /etc/nginx/nginx.conf' > /etc/sudoers.d/nginx \
    && echo 'skwr	ALL=(root) NOPASSWD: /usr/sbin/nginx' >> /etc/sudoers.d/nginx \
    && echo 'skwr	ALL=(root) NOPASSWD: /usr/bin/rsync --archive --checksum --delete /tmp/conf.d/ /etc/nginx/conf.d' >> /etc/sudoers.d/nginx \
    && addgroup skwr nginx


# Add module
COPY module /opt/module
RUN cd /opt/module/bin \
    && chmod +x *.sh \
    && rm -rf /var/lib/nginx/html \
    && ln -s /opt/module/data/html /var/lib/nginx/html

ENTRYPOINT ["run.sh"]

EXPOSE 80
EXPOSE 443

USER skwr
