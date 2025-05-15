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

# inject message on apache homepage with hostname
HOMEPAGE="/var/www/html/index.html"
echo "Junior DevOps Engineer - Home Task" > "$HOMEPAGE"

# Only configure the floating IP resource and constraints on 1 server: webz-001
if [ "$(hostname)" = "webz-001" ]; then
  echo "wiating for corosync nodes to be ready..."
  sleep 20
  if ! crm status | grep -q ClusterIP; then
    echo "Disabling STONITH in Pacemaker..."
    crm configure property stonith-enabled=false
    echo "Configuring Pacemaker floating IP resource..."
    crm configure primitive ClusterIP ocf:heartbeat:IPaddr2 \
      params ip=172.28.1.100 cidr_netmask=24 \
      op monitor interval=30s
    echo "Setting resource stickiness and location constraints..."
    crm configure rsc_defaults resource-stickiness=50
    crm configure location prefer-webz-001 ClusterIP 200: webz-001
    crm configure location prefer-webz-002 ClusterIP 50: webz-002
    crm configure location prefer-webz-003 ClusterIP 0: webz-003
  fi
fi

# Keep the container running
tail -F /dev/null 