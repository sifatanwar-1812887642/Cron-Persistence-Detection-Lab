#!/usr/bin/env bash
set -euo pipefail

# Safe lab simulation: writes only a harmless timestamped message to /tmp.
CRON_FILE="/etc/cron.d/poc_persistence"
LOG_FILE="/tmp/cron_test.log"

echo '*/2 * * * * root echo "Cron persistence test executed" >> /tmp/cron_test.log' | sudo tee "$CRON_FILE" >/dev/null
sudo chmod 644 "$CRON_FILE"

echo "Created: $CRON_FILE"
ls -l "$CRON_FILE"
echo "Wait at least two minutes, then check: $LOG_FILE"
