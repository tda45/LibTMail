#!/bin/bash

# LibTMail Docker SpamAssassin Configuration
# Author: tda_45
# Version: 1.0

set -e

# Configure SpamAssassin
cat > /etc/spamassassin/local.cf << EOF
# SpamAssassin configuration
rewrite_header Subject [SPAM]
required_score 5.0
use_bayes 1
bayes_auto_learn 1
bayes_auto_expire 1
bayes_min_spam_num 200
bayes_min_ham_num 200
use_dcc 1
use_pyzor 1
use_razor2 1
use_dkim 1
score SPF_FAIL 10.0
score SPF_HELO_FAIL 8.0
score DKIM_VERIFICATION_FAILED 5.0
score DKIM_ADSP_NXDOMAIN 5.0
score RAZOR2_CHECK 2.5
score PYZOR_CHECK 2.5
score DCC_CHECK 2.5
score BAYES_99 4.0
score BAYES_00 -3.0
EOF

# Create spamd user
useradd -r -s /bin/false spamd || true

echo "SpamAssassin configured"
