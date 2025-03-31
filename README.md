# rsyslog-elk-loki-j2

**Centralized Log Collection from Docker Containers**

The Rsyslog-server project is maked for centralized collection of syslog logs from Docker containers, local log storage, and forwarding logs to ELK and Loki.

- [Features](#features)
- [Default Configuration and Customization](#default-configuration-and-customization)
- [Docker Daemon Settings](#docker-daemon-settings)
- [Building and Running the Project](#building-and-running-the-project)
  - [Building the Image](#building-the-image)
  - [Running via docker run](#running-via-docker-run)
  - [Running via docker-compose](#running-via-docker-compose)
- [Post-Launch Verification](#post-launch-verification)
- [Important](#important)


# Features

- **Log Reception:**  
  The server listens on UDP/TCP port 514 and accepts syslog messages sent by Docker containers.

- **Dynamic File Storage:**  
  When the environment variable `SAVE_TO_FILE=true` is set, logs are stored in files at
  ```bash
  /var/log/rsyslog/docker/containers/<container_name>.log
  ```

The filename is generated dynamically based on the Docker container's name.

## **ELK Integration**  
When ENABLE_ELK is enabled, logs are converted to JSON and sent to Elasticsearch using the `omelasticsearch` module.
Configuration:
- Environment variables: `ELK_ADDRESS, ELK_USER, ELK_PASSWORD`
- The index is generated following the template `rsyslog-YYYY.MM.DD`.

## **Loki Integration**  
When ENABLE_LOKI is enabled, logs are converted to JSON (including additional fields such as host and container_ip) and forwarded to Loki using the **omhttp** module.
Configuration:
- Environment variables: `LOKI_ADDRESS, LOKI_PORT, LOKI_HTTPS`.
- If the environment variable `HOST_NAME` is not provided, the default value `rsyslog-server` is used.

## **Flexible Configuration**
- All key parameters (ports, addresses, authentication, operational modes, etc.) are set via environment variables, making it easy to adapt the configuration to any requirements.

# Default Configuration and Customization

All values in the `rsyslog.conf.j2` template are set to defaults using **Jinja2**'s default filter. This means that if you do not pass a corresponding environment variable, the default value will be used. You can:

- Override standard values by providing the necessary environment variables when launching the container.
- Add additional variables or modify the template if more detailed configuration is needed.

Example snippet from the `rsyslog.conf.j2` template:

```jinja
...
# Listen for UDP and TCP syslog messages, with ports set via environment variables (default is 514)
input(type="imudp" port="{{ PUBLISHED_PORT_UDP|default('514') }}") 
input(type="imtcp" port="{{ PUBLISHED_PORT_TCP|default('514') }}")```
...
```

# Docker Daemon Settings

To have Docker containers send logs to rsyslog-server, you must change the logging driver settings. This can be done in three ways:

**1. Global Docker Daemon Settings**
Modify the file `/etc/docker/daemon.json` by adding the following parameters:
```bash
{
  "log-driver": "syslog",
  "log-opts": {
    "syslog-address": "udp://localhost:514",
    "tag": "{{.Name}}"
  }
}
```
After making changes, restart unit:

```bash
sudo systemctl restart docker
```
:warning: **Warning: Restart all running containers so that the new settings take effect.**

**2. docker-compose.yml Settings**
For each container, you can specify logging options:

```yaml
services:
  your_service:
    image: your_image
    logging:
      driver: syslog
      options:
        syslog-address: "udp://localhost:514"
        tag: "{{.Name}}"

```
:exclamation: **Note: If your rsyslog server is on a different host, specify the server’s IP address or DNS name.**

**3. Using docker run Options**
Run the container with the specified options:
```bash
docker run --log-driver=syslog \
  --log-opt syslog-address=udp://localhost:514 \
  --log-opt tag="{{.Name}}" \
  your_image
```
# Building and Running the Project
## Building the Image
You can build the Docker image in two ways:

1. **Automatic Build via Docker Compose**
The docker-compose.yml file includes the build: . option, which allows Docker Compose to automatically build the image from the Dockerfile located in the current directory.

If you prefer to build the image manually first (e.g., using docker build -t rsyslog:latest .) and then run the container with docker-compose, comment out the build: . line in docker-compose.yml.

**2. Manual Build**
Execute the following command:
```bash
docker build -t rsyslog:latest .
```
Once the image is built successfully, you can run the container using `docker run` or `docker-compose`.

## Running via docker run
To run the container manually using docker run, use the following command:
```bash
docker run -d --name rsyslog-server-elk \
  -p 514:514/udp -p 514:514/tcp \
  -e SAVE_TO_FILE="true" \
  -e ENABLE_ELK="true" \
  -e ELK_ADDRESS="http://elasticsearch:9200" \
  -e ELK_USER="your_elk_user" \
  -e ELK_PASSWORD="your_elk_password" \
  -e ENABLE_LOKI="true" \
  -e HOST_NAME="rsyslog-server" \
  -e LOKI_ADDRESS="loki" \
  -e LOKI_PORT="3100" \
  -e LOKI_HTTPS="false" \
  -e PUBLISHED_PORT_UDP="514" \
  -e PUBLISHED_PORT_TCP="514" \
  rsyslog:latest
```

**Note**:
All the environment variables specified in this command have default values in the template. You may omit them if the default settings are sufficient for your configuration.

## Running via docker-compose

Below is an example 
[docker-compose](./docker-compose.yaml) file with comments

# Post-Launch Verification
After launching the rsyslog server, perform the following checks:

Verify Log Driver Changes:
Ensure that the changes to the log driver have taken effect by running:

```bash
docker inspect <container_id_or_name> | grep LogConfig -A05
```
Look for the log configuration settings in the output.

## Check rsyslog Server Logs:

- Verify that the rsyslog server is receiving logs.

- Check that logs are forwarded to Loki and Elasticsearch by examining their respective dashboards or log indexes.

- Finally, access the container's log storage (e.g., /var/log/rsyslog/ or /var/log/rsyslog/docker/containers/) to confirm that logs are being written locally.

# Important
Since rsyslog runs inside a container, the values for `host_name` or `fromhost-ip` will be determined by the container, not by the host.
For correct display, you can statically set the hostname using the following example used in the Loki configuration. Use it or modify it as needed:
```jinja
{% if HOST_NAME is defined and HOST_NAME != "" %}
set $!host_name = '{{ HOST_NAME }}';
{% else %}
set $!host_name = 'rsyslog-server';
{% endif %}
```

```jinja
set $!hostname = 'rsyslog-server';
```
