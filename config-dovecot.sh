#!/bin/bash

# LibTMail Docker Dovecot Configuration
# Author: tda_45
# Version: 1.0

set -e

# Create Dovecot configuration
cat > /etc/dovecot/dovecot.conf << EOF
!include conf.d/*.conf

protocols = imap pop3 lmtp
listen = *
base_dir = /var/run/dovecot/

instance_name = dovecot

login_greeting = Dovecot ready.

mail_location = maildir:/var/vmail/%d/%n

mail_privileged_group = mail

auth_mechanisms = plain login

passdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf.ext
}

userdb {
  driver = static
  args = uid=vmail gid=mail home=/var/vmail/%d/%n
}

service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0666
    user = postfix
    group = postfix
  }
}

ssl = required
ssl_cert = </etc/ssl/certs/mailserver.crt
ssl_key = </etc/ssl/private/mailserver.key
EOF

# Configure SQL authentication
cat > /etc/dovecot/dovecot-sql.conf.ext << EOF
driver = mysql
connect = host=localhost dbname=mailserver user=mailuser password=$MYSQL_MAIL_PASSWORD
default_pass_scheme = SHA512-CRYPT
password_query = SELECT email as user, password FROM users WHERE email='%u';
EOF

# Set permissions
chmod 640 /etc/dovecot/dovecot-sql.conf.ext
chown root:dovecot /etc/dovecot/dovecot-sql.conf.ext

echo "Dovecot configured"
