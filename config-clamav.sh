#!/bin/bash

# LibTMail Docker ClamAV Configuration
# Author: tda_45
# Version: 1.0

set -e

# Configure ClamAV
cat > /etc/clamav/clamd.conf << EOF
# ClamAV configuration
LogFile /var/log/clamav/clamd.log
LogTime yes
DatabaseDirectory /var/lib/clamav
PidFile /var/run/clamav/clamd.pid
TemporaryDirectory /tmp
LocalSocket /var/run/clamav/clamd.sock
User clamav
ScanMail yes
ScanArchive yes
ArchiveBlockEncrypted no
MaxScanSize 100M
MaxFileSize 25M
EOF

# Configure freshclam
cat > /etc/clamav/freshclam.conf << EOF
# Freshclam configuration
DatabaseDirectory /var/lib/clamav
UpdateLogFile /var/log/clamav/freshclam.log
PidFile /var/run/clamav/freshclam.pid
DatabaseOwner clamav
DatabaseMirror database.clamav.net
Checks 24
EOF

# Configure ClamSMTP
cat > /etc/clamav/clamsmtpd.conf << EOF
# ClamSMTP configuration
OutAddress 10025
Listen 127.0.0.1:10026
ClamAddress /var/run/clamav/clamd.sock
Header X-Virus-Scanned: ClamAV using ClamSMTP
TempDirectory /var/tmp
Action quarantine
User clamav
EOF

# Update virus definitions
freshclam

echo "ClamAV configured"
