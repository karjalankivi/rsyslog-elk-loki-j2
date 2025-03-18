# Use Debian 11 as the base image
FROM debian:11

#Update packages and unstall neces. tools
RUN apt-get update && \
    apt-get install -y \
    curl \
    gpg && \
# Add the official rsyslog repo and its GPG key
    echo 'deb http://download.opensuse.org/repositories/home:/rgerhards/Debian_11/ /' > /etc/apt/sources.list.d/home:rgerhards.list && \
    curl -fsSL https://download.opensuse.org/repositories/home:rgerhards/Debian_11/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/home_rgerhards.gpg > /dev/null && \
    apt-get update && \
# Install rsyslog and its modules for Elasticsearch and Loki (via HTTP output)
    apt-get install -y rsyslog rsyslog-elasticsearch rsyslog-omhttp && \
    # Clean package cache to reduce image size
    rm -rf /var/lib/apt/lists/*
# Copy the main rsyslog configuration file
COPY rsyslog.conf /etc/rsyslog.conf

# Expose ports for receiving syslog messages over UDP and TCP
EXPOSE 514/udp 514/tcp

# Start rsyslog in the foreground
CMD ["rsyslogd", "-n"]
