#!/bin/sh
# <bitbar.title>Show Upstream WAN Stats</bitbar.title>
# <bitbar.version>v1.0</bitbar.title>
# <bitbar.author>Edwin Steele</bitbar.author>
# <bitbar.author.github>edwinsteele</bitbar.author.github>
# <bitbar.desc>Shows WAN stats for upstream devices</bitbar.desc>

# Change this
#UPSTREAM_IP=""
UPSTREAM_IP="192.168.1.1"

if [ -z "${UPSTREAM_IP}" ]; then
  echo "WAN: Configure check";
	exit 0;
fi

# Shouldn't need to change anything below this
snmp_cmd="snmpget -c public ${UPSTREAM_IP}"
# Don't wait too long to fail, but succeed quickly"
(ping -t 5 -o ${UPSTREAM_IP} && snmpstatus -c public ${UPSTREAM_IP}) > /dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "WAN: Unreachable";
  exit 0;
fi

# Interface 10 is AAL5 interface, but it corresponds to actual ADSL speed
# Interface 9 is ATM interface, and it corresponds to attainable ADSL speed
# Interface 8 is ADSL interface, but doesn't show rates
#   94.1.1.2.1.8.1 is also ADSL upstream rate
#   94.1.1.3.1.8.1 is also ADSL downstream rate
down_rate_kbps=$($snmp_cmd transmission.97.1.1.2.1.10.1 | awk '{print $4;}')
up_rate_kbps=$($snmp_cmd transmission.97.1.1.2.1.10.2 | awk '{print $4;}')

# MacOS sed doesn't support the + operator so we use <pattern><pattern>*
uptime_str=$($snmp_cmd sysUpTimeInstance | sed 's/.*\([0-9][0-9]*\) days, \([0-9][0-9]*\):\([0-9][0-9]*\).*/\1d \2h \3m/')

echo "WAN: ${down_rate_kbps}/${up_rate_kbps} kbps"
echo "---"
echo "Manage | href=http://${UPSTREAM_IP}"
echo "Uptime ${uptime_str}"
