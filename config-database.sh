#!/bin/bash

# LibTMail Docker Database Configuration
# Author: tda_45
# Version: 1.0

set -e

# Wait for MySQL to be ready
while ! mysqladmin ping --silent 2>/dev/null; do
    echo "Waiting for MySQL to start..."
    sleep 2
done

echo "MySQL is ready"
