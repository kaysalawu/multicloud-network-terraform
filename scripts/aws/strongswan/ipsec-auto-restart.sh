#!/bin/bash

LOG_FILE="/var/log/ipsec-auto-restart.log"

echo "$(date): Restarting IPsec service..." >> "$LOG_FILE"
systemctl restart ipsec
echo "$(date): IPsec service restarted." >> "$LOG_FILE"
