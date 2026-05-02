#!/bin/bash

# LibTMail Docker OpenDKIM Configuration
# Author: tda_45
# Version: 1.0

set -e

# Create directories
mkdir -p /etc/opendkim/keys/$MAIL_DOMAIN

# Generate keys
opendkim-genkey -s mail -d $MAIL_DOMAIN -D /etc/opendkim/keys/$MAIL_DOMAIN
chown opendkim:opendkim /etc/opendkim/keys/$MAIL_DOMAIN/mail.private
chmod 600 /etc/opendkim/keys/$MAIL_DOMAIN/mail.private

# Configure OpenDKIM
cat > /etc/opendkim.conf << EOF
# OpenDKIM configuration
Syslog yes
UMask 002
Mode sv
Canonicalization relaxed/simple
ExternalIgnoreList refile:/etc/opendkim/TrustedHosts
InternalHosts refile:/etc/opendkim/TrustedHosts
KeyTable refile:/etc/opendkim/KeyTable
SigningTable refile:/etc/opendkim/SigningTable
PidFile /var/run/opendkim/opendkim.pid
Socket inet:12301@localhost
EOF

# Create TrustedHosts file
cat > /etc/opendkim/TrustedHosts << EOF
127.0.0.1
localhost
192.168.0.0/16
10.0.0.0/8
172.16.0.0/12
*.$MAIL_DOMAIN
EOF

# Create KeyTable file
cat > /etc/opendkim/KeyTable << EOF
mail._domainkey.$MAIL_DOMAIN $MAIL_DOMAIN:mail:/etc/opendkim/keys/$MAIL_DOMAIN/mail.private
EOF

# Create SigningTable file
cat > /etc/opendkim/SigningTable << EOF
*@$MAIL_DOMAIN mail._domainkey.$MAIL_DOMAIN
EOF

echo "OpenDKIM configured"
echo "DKIM DNS record:"
cat /etc/opendkim/keys/$MAIL_DOMAIN/mail.txt
