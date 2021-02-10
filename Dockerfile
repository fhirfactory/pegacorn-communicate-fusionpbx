FROM fhirfactory/pegacorn-base-fusionpbx:1.0.0-snapshot

# Expose ports
# https://hub.docker.com/layers/sharks/fusionpbx64x/latest/images/sha256-20124991a611eb7c4145f6a8bbca8a1fda69234bf486a32613a355d73c4014e0?context=explore
EXPOSE 80
EXPOSE 443
EXPOSE 5432
EXPOSE 5060/tcp 5060/udp 5080/tcp 5080/udp
EXPOSE 5066/tcp 7443/tcp
EXPOSE 8021/tcp
EXPOSE 64535-65535/udp

# Date-time build argument
ARG IMAGE_BUILD_TIMESTAMP
ENV IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}
RUN echo IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}

USER root
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start-freeswitch.sh /usr/bin/start-freeswitch.sh
COPY modules.conf.xml /etc/freeswitch/autoload_configs/modules.conf.xml
COPY logo.png /var/www/fusionpbx/themes/default/images/logo.png

VOLUME ["/etc/freeswitch", "/var/lib/freeswitch", "/usr/share/freeswitch", "/var/www/fusionpbx"]

CMD /usr/bin/supervisord -n
