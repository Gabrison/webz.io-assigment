#!/bin/bash
set -e

# Start SSHD in the background
/usr/sbin/sshd &

# Run the original Jenkins entrypoint
exec /usr/bin/tini -- /usr/local/bin/jenkins.sh "$@" 