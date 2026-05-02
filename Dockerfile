# LibTMail Mail Server Docker Image
# Complete mail server solution with Postfix, Dovecot, MySQL, SpamAssassin, ClamAV, OpenDKIM, and Roundcube
# Author: tda_45
# Version: 1.0

FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV MAIL_DOMAIN=example.com
ENV MAIL_HOSTNAME=mail
ENV ADMIN_EMAIL=admin@example.com
ENV MYSQL_ROOT_PASSWORD=changeme
ENV MYSQL_MAIL_PASSWORD=changeme

# Install base packages
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    wget \
    curl \
    git \
    vim \
    htop \
    unzip \
    bzip2 \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    supervisor \
    cron \
    logrotate \
    net-tools \
    openssl \
    pwgen \
    apache2 \
    php \
    php-mysql \
    php-imap \
    php-json \
    php-curl \
    php-xml \
    php-mbstring \
    php-intl \
    php-gd \
    php-zip \
    php-bz2 \
    php-ldap \
    && rm -rf /var/lib/apt/lists/*

# Install mail server packages
RUN apt-get update && \
    apt-get install -y \
    postfix \
    postfix-mysql \
    dovecot-core \
    dovecot-imapd \
    dovecot-pop3d \
    dovecot-mysql \
    mariadb-server \
    mariadb-client \
    spamassassin \
    spamc \
    clamav \
    clamav-freshclam \
    clamsmtp \
    opendkim \
    opendkim-tools \
    && rm -rf /var/lib/apt/lists/*

# Download and install Roundcube
RUN cd /tmp && \
    wget https://github.com/roundcube/roundcubemail/releases/download/1.6.2/roundcubemail-1.6.2-complete.tar.gz && \
    tar -xzf roundcubemail-1.6.2-complete.tar.gz && \
    mv roundcubemail-1.6.2 /var/www/html/webmail && \
    chown -R www-data:www-data /var/www/html/webmail && \
    chmod -R 755 /var/www/html/webmail && \
    rm -f roundcubemail-1.6.2-complete.tar.gz

# Create directories
RUN mkdir -p /var/vmail && \
    mkdir -p /etc/ssl/certs && \
    mkdir -p /etc/ssl/private && \
    mkdir -p /var/log/mail && \
    mkdir -p /var/backups/mailserver

# Create vmail user
RUN useradd -r -u 5000 -g mail -d /var/vmail -s /sbin/nologin vmail || true && \
    chown -R vmail:mail /var/vmail

# Copy configuration files
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY config-postfix.sh /usr/local/bin/config-postfix.sh
COPY config-dovecot.sh /usr/local/bin/config-dovecot.sh
COPY config-database.sh /usr/local/bin/config-database.sh
COPY config-opendkim.sh /usr/local/bin/config-opendkim.sh
COPY config-spamassassin.sh /usr/local/bin/config-spamassassin.sh
COPY config-clamav.sh /usr/local/bin/config-clamav.sh
COPY config-apache.sh /usr/local/bin/config-apache.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make scripts executable
RUN chmod +x /usr/local/bin/*.sh

# Copy management scripts
COPY mailadmin /usr/local/bin/mailadmin
COPY mailbackup /usr/local/bin/mailbackup
COPY mailmonitor /usr/local/bin/mailmonitor
COPY mailqueue /usr/local/bin/mailqueue
RUN chmod +x /usr/local/bin/mail*

# Expose ports
EXPOSE 25 587 143 993 110 995 80 443

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD netstat -tlnp | grep -E ':(25|587|143|993|110|995|80|443)\s' || exit 1

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
