#!/bin/bash

# Debug: Print environment variables
echo "CRON_SCHEDULE=${CRON_SCHEDULE}"
echo "CRON_COMMAND=${CRON_COMMAND}"
echo "PUID=${PUID}"
echo "PGID=${PGID}"

# Terminate any existing cron processes
if pgrep -x cron >/dev/null; then
    echo 'Stopping existing cron process...'
    pkill -x cron
fi

# Validate CRON_SCHEDULE and CRON_COMMAND
if [[ -z "${CRON_SCHEDULE}" || -z "${CRON_COMMAND}" ]]; then
    echo 'Error: CRON_SCHEDULE or CRON_COMMAND is not set.'
    exit 1
fi

echo "No PUID or PGID set. Running as root..."
echo "${CRON_SCHEDULE} ${CRON_COMMAND} >/proc/1/fd/1 2>/proc/1/fd/2" | crontab -
if [[ $? -ne 0 ]]; then
    echo 'Error: Failed to configure crontab for root.'
    exit 1
fi
echo 'Crontab configured for root:'
crontab -l

# Start the cron daemon in the foreground
echo 'Starting cron...'
exec cron -f
