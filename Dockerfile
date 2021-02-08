FROM debian:buster
# Reference for this build:
# https://github.com/igorolhovskiy/fusionpbx-docker/blob/4.4/Dockerfile
# https://github.com/PBXForums/fusionpbx-docker/blob/master/Dockerfile

# Expose ports
# https://hub.docker.com/layers/sharks/fusionpbx64x/latest/images/sha256-20124991a611eb7c4145f6a8bbca8a1fda69234bf486a32613a355d73c4014e0?context=explore
EXPOSE 80
EXPOSE 443
EXPOSE 5432
EXPOSE 5060/tcp 5060/udp 5080/tcp 5080/udp
EXPOSE 5066/tcp 7443/tcp
EXPOSE 8021/tcp
EXPOSE 64535-65535/udp

# Install Required Dependencies	
RUN apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install -y --allow-unauthenticated \ 		
	apt-transport-https \
	apt-utils \
	bsdmainutils \
	ca-certificates \
	curl \
	ghostscript \		
	git \
	gnupg2 \
	libtiff5-dev \
	libtiff-tools \
	lsb-release \
	mariadb-client \
	netcat \
	net-tools \
	nginx \
	openssh-server \
	ssl-cert \
	sudo \
	supervisor \
	wget	

# Install php 7.3 - PHP issues in Debian
# https://stackoverflow.com/questions/57438387/docker-php7-cli-debian-buster-how-to-install-package-php-imagick
RUN echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/php.list \
	&& curl https://packages.sury.org/php/apt.gpg | apt-key add - \
    	&& apt-get update -qq \
    	&& DEBIAN_FRONTEND=noninteractive apt-get install -y php7.3 php7.3-cli php7.3-fpm php7.3-pgsql php7.3-sqlite php7.3-odbc php7.3-curl php7.3-imap php7.3-xml
# Start php service
# https://serverfault.com/questions/786398/how-do-i-start-php7-0-fpm-with-supervisord
RUN service php7.3-fpm start

# Install Fusionpbx and keys and update fusionpbx to use fast process manager 7.3
RUN git clone https://github.com/fusionpbx/fusionpbx.git /var/www/fusionpbx \
	# Add WebRTC app --> https://docs.fusionpbx.com/en/latest/applications_optional/webrtc.html
	&& git clone https://github.com/fusionpbx/fusionpbx-apps \
	&& mv fusionpbx-apps/webrtc /var/www/fusionpbx/app
RUN chown -R www-data:www-data /var/www/fusionpbx
RUN chown -R www-data:www-data /var/www/fusionpbx/app/webrtc
RUN wget https://raw.githubusercontent.com/fusionpbx/fusionpbx-install.sh/master/debian/resources/nginx/fusionpbx -O /etc/nginx/sites-available/fusionpbx \ 
	&& find /etc/nginx/sites-available/fusionpbx -type f -exec sed -i 's/\/var\/run\/php\/php7.1-fpm.sock/\/run\/php\/php'"7.3"'-fpm.sock/g' {} \; \	
	&& ln -s /etc/nginx/sites-available/fusionpbx /etc/nginx/sites-enabled/fusionpbx \ 	
	&& ln -s /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/private/nginx.key \ 	
	&& ln -s /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/certs/nginx.crt \ 	
	&& rm /etc/nginx/sites-enabled/default

# Begin freeswitch software install
# https://freeswitch.org/confluence/display/FREESWITCH/Debian+10+Buster
RUN wget -O - https://files.freeswitch.org/repo/deb/debian-release/fsstretch-archive-keyring.asc | apt-key add - \
	&& echo "deb http://files.freeswitch.org/repo/deb/debian-release/ `lsb_release -sc` main" > /etc/apt/sources.list.d/freeswitch.list \
	&& echo "deb-src http://files.freeswitch.org/repo/deb/debian-release/ `lsb_release -sc` main" >> /etc/apt/sources.list.d/freeswitch.list \
	&& apt-get update \
	&& apt-get install -y \
	memcached \
	freeswitch-meta-bare \
	freeswitch-conf-vanilla \
	freeswitch-mod-commands \
	freeswitch-mod-console \
	freeswitch-mod-logfile \
	freeswitch-lang-en \
	freeswitch-mod-say-en \
	freeswitch-sounds-en-us-callie \
	freeswitch-mod-enum \
	freeswitch-mod-cdr-csv \
	freeswitch-mod-event-socket \
	freeswitch-mod-sofia \
	freeswitch-mod-loopback \
	freeswitch-mod-conference \
	freeswitch-mod-db \
	freeswitch-mod-dptools \
	freeswitch-mod-expr \
	freeswitch-mod-fifo \
	freeswitch-mod-httapi \
	freeswitch-mod-hash \
	freeswitch-mod-esl \
	freeswitch-mod-esf \
	freeswitch-mod-fsv \
	freeswitch-mod-valet-parking \
	freeswitch-mod-dialplan-xml \
	freeswitch-mod-sndfile \
	freeswitch-mod-native-file \
	freeswitch-mod-local-stream \
	freeswitch-mod-tone-stream \
	freeswitch-mod-lua \
	freeswitch-meta-mod-say \
	freeswitch-mod-xml-cdr \
	freeswitch-mod-verto \
	freeswitch-mod-callcenter \
	freeswitch-mod-rtc \
	freeswitch-mod-png \
	freeswitch-mod-json-cdr \
	freeswitch-mod-shout \
	freeswitch-mod-sms \
	freeswitch-mod-sms-dbg \
	freeswitch-mod-cidlookup \
	freeswitch-mod-memcache \
	freeswitch-mod-imagick \
	freeswitch-mod-tts-commandline \
	freeswitch-mod-directory \
	freeswitch-mod-flite \
	freeswitch-mod-distributor \
	freeswitch-meta-codecs \
	freeswitch-music-default \
	&& usermod -a -G freeswitch www-data \
	&& usermod -a -G www-data freeswitch \
	&& chown -R freeswitch:freeswitch /var/lib/freeswitch \
	&& chmod -R ug+rw /var/lib/freeswitch \
	&& find /var/lib/freeswitch -type d -exec chmod 2770 {} \; \
	&& mkdir /usr/share/freeswitch/scripts \
	&& chown -R freeswitch:freeswitch /usr/share/freeswitch \
	&& chmod -R ug+rw /usr/share/freeswitch \
	&& find /usr/share/freeswitch -type d -exec chmod 2770 {} \; \
	&& chown -R freeswitch:freeswitch /etc/freeswitch \
	&& chmod -R ug+rw /etc/freeswitch \
	&& mkdir -p /etc/fusionpbx \
	&& chmod 777 /etc/fusionpbx \
	&& find /etc/freeswitch -type d -exec chmod 2770 {} \; \
	&& chown -R freeswitch:freeswitch /var/log/freeswitch \
	&& chmod -R ug+rw /var/log/freeswitch \
	&& find /var/log/freeswitch -type d -exec chmod 2770 {} \; \
	&& find /etc/freeswitch/autoload_configs/event_socket.conf.xml -type f -exec sed -i 's/::/127.0.0.1/g' {} \; \
	&& mkdir -p /run/php/ \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*
    
# Postgres database configuration <TD: separate for scalability>
ENV PSQL_PASSWORD="psqlpass"  
RUN wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add - \
	&& sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main" >> /etc/apt/sources.list.d/pgdg.list' \
	&& sudo apt-get update \
	&& sudo apt-get install -y postgresql postgresql-contrib \
	&& find /etc/postgresql/13/main/postgresql.conf -type f -exec sed -i 's/#listen_addresses/listen_addresses/g' {} \; \
	&& find /etc/postgresql/13/main/postgresql.conf -type f -exec sed -i 's/''localhost''/''*''/g' {} \; \
	&& service postgresql start \
	&& sleep 10 \
	&& echo "psql -c \"CREATE DATABASE fusionpbx\";" | su - postgres \
	&& echo "psql -c \"CREATE DATABASE freeswitch\";" | su - postgres \
	&& echo "psql -c \"CREATE ROLE fusionpbx WITH SUPERUSER LOGIN PASSWORD '$PSQL_PASSWORD'\";" | su - postgres \
	&& echo "psql -c \"CREATE ROLE freeswitch WITH SUPERUSER LOGIN PASSWORD '$PSQL_PASSWORD'\";" | su - postgres \
	&& echo "psql -c \"GRANT ALL PRIVILEGES ON DATABASE fusionpbx to fusionpbx\";"  | su - postgres \
	&& echo "psql -c \"GRANT ALL PRIVILEGES ON DATABASE freeswitch to fusionpbx\";" | su - postgres \
	&& echo "psql -c \"GRANT ALL PRIVILEGES ON DATABASE freeswitch to freeswitch\";" | su - postgres
        
# Date-time build argument
ARG IMAGE_BUILD_TIMESTAMP
ENV IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}
RUN echo IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}

USER root
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start-freeswitch.sh /usr/bin/start-freeswitch.sh
COPY modules.conf.xml /etc/freeswitch/autoload_configs/modules.conf.xml
COPY logo.png /var/www/fusionpbx/themes/default/images/logo.png

VOLUME ["/var/lib/postgresql", "/etc/freeswitch", "/var/lib/freeswitch", "/usr/share/freeswitch", "/var/www/fusionpbx"]

CMD /usr/bin/supervisord -n

