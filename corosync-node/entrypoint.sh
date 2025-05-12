#!/bin/bash
set -e

# SSHD
echo "Starting sshd..."
service ssh start

# Corosync
echo "Starting corosync..."
service corosync start

# Pacemaker
echo "Starting pacemaker..."
service pacemaker start

# Apache2
echo "Starting apache2..."
service apache2 start

# inject message on apache homepage
HOMEPAGE="/var/www/html/index.html"
if ! grep -q "Junior DevOps Engineer" "$HOMEPAGE" 2>/dev/null; then
  echo "Junior DevOps Engineer - Home Task" > "$HOMEPAGE"
fi

# Keep the container running
tail -F /var/log/syslog 