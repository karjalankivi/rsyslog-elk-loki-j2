# Use Debian 11 as the base image
FROM debian:11

#Update packages and unstall neces. tools
RUN apt-get update && \
    apt-get install -y \
      curl \
      gpg \
      python3 \
      python3-pip \
    && pip3 install setuptools j2cli \
    && echo 'deb http://download.opensuse.org/repositories/home:/rgerhards/Debian_11/ /' > /etc/apt/sources.list.d/home:rgerhards.list \
    && curl -fsSL https://download.opensuse.org/repositories/home:rgerhards/Debian_11/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/home_rgerhards.gpg > /dev/null \
    && apt-get update \
    && apt-get install -y rsyslog rsyslog-elasticsearch rsyslog-omhttp \
    && rm -rf /var/lib/apt/lists/*

# Copy the main Jinja2-template configuration file for rsyslog
COPY rsyslog.conf.j2 /etc/rsyslog.conf.j2

# Copy the entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose ports for receiving syslog messages over UDP and TCP
EXPOSE 514/udp 514/tcp

# Start entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
