#!/bin/bash

# LibTMail Docker Postfix Configuration
# Author: tda_45
# Version: 1.0

set -e

# Create Postfix configuration
cat > /etc/postfix/main.cf << EOF
# Basic settings
myhostname = ${MAIL_HOSTNAME}.${MAIL_DOMAIN}
mydomain = $MAIL_DOMAIN
myorigin = \$mydomain
inet_interfaces = all
inet_protocols = all
mydestination = localhost, localhost.\$mydomain

# Virtual domains and users
virtual_mailbox_domains = mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf
virtual_mailbox_maps = mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf
virtual_alias_maps = mysql:/etc/postfix/mysql-virtual-alias-maps.cf

# Mailbox location
virtual_mailbox_base = /var/vmail
virtual_minimum_uid = 5000
virtual_uid_maps = static:5000
virtual_gid_maps = static:5000

# SMTP authentication
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes
smtpd_recipient_restrictions = permit_sasl_authenticated, permit_mynetworks, reject_unauth_destination

# TLS settings
smtpd_tls_cert_file = /etc/ssl/certs/mailserver.crt
smtpd_tls_key_file = /etc/ssl/private/mailserver.key
smtpd_use_tls = yes
smtpd_tls_auth_only = yes

# SpamAssassin integration
content_filter = spamassassin
spamassassin unix -     n       n       -       -       pipe
    user=spamd argv=/usr/bin/spamc -f -e /usr/sbin/sendmail -oi -f \${sender} \${recipient}

# ClamAV integration
content_filter = scan:[127.0.0.1]:10026
receive_override_options = no_address_mappings

# OpenDKIM integration
milter_protocol = 2
milter_default_action = accept
smtpd_milters = inet:localhost:12301
non_smtpd_milters = inet:localhost:12301

# Message size limit
message_size_limit = 52428800
mailbox_size_limit = 0

# Network settings
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
EOF

# Create MySQL configuration files
cat > /etc/postfix/mysql-virtual-mailbox-domains.cf << EOF
user = mailuser
password = $MYSQL_MAIL_PASSWORD
hosts = localhost
dbname = mailserver
query = SELECT 1 FROM domains WHERE name='%s'
EOF

cat > /etc/postfix/mysql-virtual-mailbox-maps.cf << EOF
user = mailuser
password = $MYSQL_MAIL_PASSWORD
hosts = localhost
dbname = mailserver
query = SELECT 1 FROM users WHERE email='%s'
EOF

cat > /etc/postfix/mysql-virtual-alias-maps.cf << EOF
user = mailuser
password = $MYSQL_MAIL_PASSWORD
hosts = localhost
dbname = mailserver
query = SELECT destination FROM aliases WHERE source='%s'
EOF

# Set proper permissions
chmod 640 /etc/postfix/mysql-*.cf
chown postfix:postfix /etc/postfix/mysql-*.cf

# Create master.cf additions
cat >> /etc/postfix/master.cf << EOF

# SpamAssassin
spamassassin unix -     n       n       -       -       pipe
    user=spamd argv=/usr/bin/spamc -f -e /usr/sbin/sendmail -oi -f \${sender} \${recipient}

# ClamAV
scan      unix  -       -       n       -       16      smtp
    -o smtp_send_xforward_command=yes
    -o smtp_enforce_tls=no

127.0.0.1:10025 inet   n       -       n       -       16      smtpd
    -o content_filter=
    -o receive_override_options=no_unknown_recipient_checks,no_header_body_checks,no_milters
    -o smtpd_helo_restrictions=
    -o smtpd_client_restrictions=
    -o smtpd_sender_restrictions=
    -o smtpd_recipient_restrictions=permit_mynetworks,reject
    -o mynetworks=127.0.0.0/8
    -o smtpd_authorized_xforward_hosts=127.0.0.0/8
EOF

echo "Postfix configured"
