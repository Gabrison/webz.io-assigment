#!/bin/bash
LOGFILE="/var/log/webz/cluster_monitor.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
RESPONSE=$(curl -s http://172.28.1.100/)
echo "$TIMESTAMP | $RESPONSE" >> "$LOGFILE"