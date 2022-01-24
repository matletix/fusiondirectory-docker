FROM debian:10

ARG SLAPD_PASSWORD
ARG SLAPD_ORGANIZATION
ARG SLAPD_DOMAIN

# Create necessary directories
RUN mkdir -p /etc/fusiondirectory /etc/ldap/schema/fusiondirectory /usr/local/share/fusiondirectory /var/cache/fusiondirectory/template

# Install dependencies
RUN apt-get update && \
    apt-get install -y git rsync man-db build-essential locales unzip smarty3 \
    apache2 libapache2-mod-php7.3 php php-cas php-common php-curl php-fpdf php-gd php-imagick php-imap php-ldap \
    php-mbstring php-recode php-xml php7.3 php7.3-cli php7.3-common php7.3-curl php7.3-gd php7.3-imap \
    php7.3-json php7.3-ldap php7.3-mbstring php7.3-opcache php7.3-readline php7.3-recode php7.3-xml smarty-gettext \
    smarty3 ssl-cert ttf-dejavu-core libjs-prototype libjs-scriptaculous libpath-class-perl libnet-ldap-perl \
    libcrypt-cbc-perl libarchive-extract-perl libfile-copy-recursive-perl libxml-twig-perl libterm-readkey-perl \
    dirmngr gnupg apt-transport-https ca-certificates libbytes-random-secure-perl && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install slapd ldap-utils && \
    apt-get clean

WORKDIR /usr/src

# Clone fusiondirectory repositories
RUN GIT_SSL_NO_VERIFY=true git clone https://gitlab.fusiondirectory.org/fusiondirectory/schema2ldif.git && \
    GIT_SSL_NO_VERIFY=true git clone https://gitlab.fusiondirectory.org/fusiondirectory/fd.git && \
    GIT_SSL_NO_VERIFY=true git clone https://gitlab.fusiondirectory.org/fusiondirectory/fd-plugins.git

# Install binaries
RUN cp ./fd/contrib/bin/* /usr/local/bin/ && \
    cp -r ./schema2ldif/bin/* /usr/local/bin/ && \
    chmod u+x /usr/local/bin/*

# Install man pages of the binaries
RUN mkdir -p /usr/local/man/man1 && \
    rsync -v ./schema2ldif/man/*.1 /usr/local/man/man1 && \
    mandb

# Copy core LDAP schemas, smarty3 plugin, source files
RUN cp ./fd/contrib/openldap/* /etc/ldap/schema/fusiondirectory/ && \
    cp ./fd/contrib/smarty/plugins/* /usr/share/php/smarty3/plugins/ && \
    cp -r ./fd/html /usr/local/share/fusiondirectory/ && \
    cp -r ./fd/ihtml /usr/local/share/fusiondirectory/ && \
    cp -r ./fd/locale /usr/local/share/fusiondirectory/ && \
    cp -r ./fd/plugins /usr/local/share/fusiondirectory/ && \
    cp -r ./fd/setup /usr/local/share/fusiondirectory/ && \
    cp -r ./fd/include /usr/local/share/fusiondirectory/ && \
    cp -r ./fd/contrib/fusiondirectory.conf /var/cache/fusiondirectory/template/

# Install scriptaculous javascript assets
RUN curl -o /tmp/scriptaculous.zip https://script.aculo.us/dist/scriptaculous-js-1.9.0.zip && \
    unzip /tmp/scriptaculous.zip -d /tmp/scriptaculous && \
    find /tmp/scriptaculous -name \*.js -exec cp -v {} /usr/local/share/fusiondirectory/html/include \; && \
    rm -rf /tmp/scriptaculous*

# Verify directories, update the cache and locale files
RUN yes | /usr/local/bin/fusiondirectory-setup --set-fd_home=/usr/local/share/fusiondirectory --check-directories && \
    /usr/local/bin/fusiondirectory-setup --set-fd_home=/usr/local/share/fusiondirectory --update-cache --update-locales --write-vars && \
    sed -i s/\#\ fr_FR\.UTF-8\ UTF-8/fr_FR\.UTF-8\ UTF-8/g /etc/locale.gen && \
    locale-gen

# Configure apache to serve fusiondirectory
COPY fd.conf /etc/apache2/sites-available/fd.conf
RUN a2dissite 000-default && a2ensite fd
RUN cat /etc/apache2/apache2.conf

# Configure OpenLDAP
RUN bash -c "echo -e 'slapd slapd/no_configuration boolean false\n\
    slapd slapd/password1 password $SLAPD_PASSWORD\n\
    slapd slapd/password2 password $SLAPD_PASSWORD\n\
    slapd shared/organization string $SLAPD_ORGANIZATION\n\
    slapd slapd/domain string $SLAPD_DOMAIN\n\
    slapd slapd/backend select MDB\n\
    slapd slapd/allow_ldap_v2 boolean false\n\
    slapd slapd/purge_database boolean false\n\
    slapd slapd/move_old_database boolean true\n'"\
    | debconf-set-selections && \
    dpkg-reconfigure -f noninteractive slapd && \
    slapcat

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80 389
ENTRYPOINT /entrypoint.sh

