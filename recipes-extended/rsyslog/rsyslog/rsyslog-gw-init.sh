#!/bin/sh
# Setup gateway configuration for rsyslog
#
# This script is not power cut save as it is supposed to run on each startup
# before rsyslog gets started.
# Running on reach start up ensures that environment changes are reflected
# properly.

set -eu -o pipefail

RSYSLOG_CONFIG_DIR='/etc/rsyslog.d'
SELUXIT_ENV="$(fw_printenv -n "seluxit_env" 2>/dev/null || echo prod)"
GATEWAY_ID="$(fw_printenv -n gatewayid)"

# Configure gateway id as LocalHostName
RSYSLOG_CONFIG_FILE="${RSYSLOG_CONFIG_DIR}/01-gateway-id.conf"
RSYSLOG_CONFIG_FILE_CONTENT="\$LocalHostName ${GATEWAY_ID}"
grep -q ^"${RSYSLOG_CONFIG_FILE_CONTENT}"$ "${RSYSLOG_CONFIG_FILE}" 2>/dev/null || echo "${RSYSLOG_CONFIG_FILE_CONTENT}" > "${RSYSLOG_CONFIG_FILE}"

# Configure variables for use in other config files
RSYSLOG_METADATA_CONFIG_FILE="${RSYSLOG_CONFIG_DIR}/02-gateway-metadata.conf"
RSYSLOG_METADATA_CONFIG_FILE_CONTENT_ENV="set \$!gw.env = '${SELUXIT_ENV}';"
# shellcheck disable=SC1091
RSYSLOG_METADATA_CONFIG_FILE_CONTENT_VERSION="set \$!gw.swVersion = '$(. /etc/os-release; echo "$VERSION")';"
if ! grep -q ^"${RSYSLOG_METADATA_CONFIG_FILE_CONTENT_ENV}"$ "${RSYSLOG_METADATA_CONFIG_FILE}" || \
   ! grep -q ^"${RSYSLOG_METADATA_CONFIG_FILE_CONTENT_VERSION}"$ "${RSYSLOG_METADATA_CONFIG_FILE}"; then
    echo "${RSYSLOG_METADATA_CONFIG_FILE_CONTENT_ENV}" > "${RSYSLOG_METADATA_CONFIG_FILE}"
    echo "${RSYSLOG_METADATA_CONFIG_FILE_CONTENT_VERSION}" >> "${RSYSLOG_METADATA_CONFIG_FILE}"
fi

# Configure diagnostics based on environment
DIAGNOSTICS_CONFIG_FILE="${RSYSLOG_CONFIG_DIR}/20-diagnostics.conf"
if [ "${SELUXIT_ENV}" = prod ]; then
    cmp "${DIAGNOSTICS_CONFIG_FILE}.prod" "${DIAGNOSTICS_CONFIG_FILE}" || cp "${DIAGNOSTICS_CONFIG_FILE}.prod" "${DIAGNOSTICS_CONFIG_FILE}"
else
    cmp "${DIAGNOSTICS_CONFIG_FILE}.dev" "${DIAGNOSTICS_CONFIG_FILE}" || cp "${DIAGNOSTICS_CONFIG_FILE}.dev" "${DIAGNOSTICS_CONFIG_FILE}"
fi

# Disable verbose logging on prod
FILTER_CONFIG_FILE="${RSYSLOG_CONFIG_DIR}/90-severity-forward-filter.conf"
if [ "${SELUXIT_ENV}" = prod ]; then
    cmp "${FILTER_CONFIG_FILE}.prod" "${FILTER_CONFIG_FILE}" || cp "${FILTER_CONFIG_FILE}.prod" "${FILTER_CONFIG_FILE}"
else
    rm -f "${FILTER_CONFIG_FILE}"
fi

# The following lines are for development purposes. On changes to the relevant
# U-Boot variables, either restart the gateway or run this script and then
# restart rsyslogd.

# Create temporary copy of the (vanilla) rsyslog.conf to work on
cp /etc/rsyslog.conf.prod /tmp/rsyslog.conf

# Configure unencrypted logging to local server
if DEV_RSYSLOG_SERVER="$(fw_printenv -n "dev_rsyslog_server" 2>/dev/null)"; then
    sed -i "s/Target=.*$/Target=\"${DEV_RSYSLOG_SERVER}\"/" /tmp/rsyslog.conf
    sed -i 's/StreamDriverMode="1"$/StreamDriverMode=\"0\"/' /tmp/rsyslog.conf
fi

# Disable rate limiting
if DEV_RSYSLOG_DISABLE_RATE_LIMIT="$(fw_printenv -n "dev_rsyslog_disable_rate_limit" 2>/dev/null)"; then
    if [ "${DEV_RSYSLOG_DISABLE_RATE_LIMIT}" -eq "1" ]; then
        sed -i 's/SysSock\.RateLimit\.Interval=/# SysSock\.RateLimit\.Interval=/' /tmp/rsyslog.conf
    fi
fi

# Update configuration (only) if changed
if cmp /tmp/rsyslog.conf /etc/rsyslog.conf; then
    rm /tmp/rsyslog.conf
else
    mv /tmp/rsyslog.conf /etc/rsyslog.conf
fi
