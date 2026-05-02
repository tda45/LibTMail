#!/bin/bash

# LibTMail Docker Apache Configuration
# Author: tda_45
# Version: 1.0

set -e

# Create Apache configuration for webmail
cat > /etc/apache2/sites-available/webmail.conf << EOF
<VirtualHost *:80>
    ServerName ${MAIL_HOSTNAME}.${MAIL_DOMAIN}
    DocumentRoot /var/www/html/webmail
    
    <Directory /var/www/html/webmail>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/webmail_error.log
    CustomLog \${APACHE_LOG_DIR}/webmail_access.log combined
</VirtualHost>

<VirtualHost *:443>
    ServerName ${MAIL_HOSTNAME}.${MAIL_DOMAIN}
    DocumentRoot /var/www/html/webmail
    
    <Directory /var/www/html/webmail>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/webmail_error.log
    CustomLog \${APACHE_LOG_DIR}/webmail_access.log combined
    
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/mailserver.crt
    SSLCertificateKeyFile /etc/ssl/private/mailserver.key
</VirtualHost>
EOF

# Enable site and modules
a2ensite webmail.conf
a2enmod rewrite
a2enmod ssl

echo "Apache configured"
