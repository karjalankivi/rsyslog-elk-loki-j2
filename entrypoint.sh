#!/bin/bash
export PATH="/usr/local/bin:${PATH}"
# Generate configuration /etc/rsyslog.conf with tempalte rsyslog.conf.j2
j2 /etc/rsyslog.conf.j2 --format=env > /etc/rsyslog.conf

echo "Generated /etc/rsyslog.conf:"
cat /etc/rsyslog.conf

# Launch rsyslog in foreground
exec rsyslogd -n