FROM fhirfactory/pegacorn-base-fusionpbx:1.0.0-snapshot

# Expose ports
# https://freeswitch.org/confluence/display/FREESWITCH/Firewall
EXPOSE 80
EXPOSE 443
EXPOSE 5432
EXPOSE 5060/tcp 5060/udp 5070/tcp 5070/udp 5080/tcp 5080/udp
EXPOSE 5066/tcp 7443/tcp
EXPOSE 8021/tcp
EXPOSE 8081-8082/tcp
EXPOSE 64535-65535/udp
EXPOSE 16384-32768/udp
EXPOSE 2855-2856/tcp

# Date-time build argument
ARG IMAGE_BUILD_TIMESTAMP
ENV IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}
RUN echo IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}

USER root
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start-freeswitch.sh /usr/bin/start-freeswitch.sh
COPY modules.conf.xml /etc/freeswitch/autoload_configs/modules.conf.xml
COPY vars.xml /var/www/fusionpbx/resources/templates/conf/vars.xml
COPY logo.png /var/www/fusionpbx/themes/default/images/logo.png

VOLUME ["/etc/freeswitch", "/var/lib/freeswitch", "/usr/share/freeswitch", "/var/www/fusionpbx"]

CMD /usr/bin/supervisord -n
