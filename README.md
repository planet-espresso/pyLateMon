# Docker Based Latency Monitor

Docker container(s) which tracks latency of one or many hosts and reports to InfluxDBv2.

## Description

This docker container is able to track the latency of one or many targets and reports all data to a given InfluxDBv2.

It´s based on python3 an makes usage of following python libraries:

- pythonping
- influxdb_client
- threading
- sys
- os
- datetime
- configparser
- time

You can use it in *standalone* or *full stack* mode.

**Standalone:**
- Just the latency-monitor container which sends data to an external InfluxDB2 Server

**Full Stack:**
- Traefik container as Proxy (full TLS support)
- InfluxDB2 container, fully setup and ready to take data
- Grafana container, fully setup and connected (but without dashboards)
- latency-monitor container sending data to the InfluxDB2 container


## Requirements

- Docker (CE)
- Docker-Compose
- InfluxDB Version >= 2
- pythonping needs root privileges so same for the container

## Configuration (GENERAL)

Configuration can be passed via ENV **OR** configuration file.

In case of using the ENV option you are just able to monitor **ONE** target for more targets please use the configuration file. 

Also some influx connection options are just configurable via config file but normally they are not needed.


### Behaviour 

Per default the used python influxdb connector will cache all replies and sends them bundled every 30 seconds to the Influx DB.

Actually the latency-monitor container is build on demand, a dockerhub image is on the roadmap...

You can find everything under *./Docker_Build/* and in the python program itself [latency_monitor.py](./Docker_Build/latency_monitor.py)

-----

### ENV Variables

Name | Example | Usage | Option/Must
:------: | :-----: | :-----: | :-----:
INFLUX_URL | http://10.0.0.1:8086 | InfluxDB Host | must
INFLUX_TOKEN | eWOcp-MCv2Y3IJPlER7wc...ICKirhw0lwEczRNnrIoTqZAg== | InfluxDB API Token | must
INFLUX_BUCKET | latency | InfluxDB Bucket | must
INFLUX_ORG | MyOrg | InfluxDB Organization | must
TARGET_HOST | 8.8.8.8 | Monitored Host (IP/FQDN) | must
TARGET_TIMER | 3 | ping frequency in sec. | option
TARGET_LOCATION | Google | decript. location | option

-----

### Config File

**Instead** of using the ENV variables you can use a config file.

**Keep in mind it´s a OR decision not a AND**  

See [./latency-monitor/config.ini](./latency-monitor/config.ini)


#### Docker-Compose Style

uncomment: 

```
# - ./latency-monitor/config.ini:/app/config.ini:ro # UNCOMMENT IF NEEDED
```

#### Docker-CLI Style

```
docker latency-monitor -v ./latency-monitor/config.ini:/app/config.ini:ro
```

-----
-----

## Configuration (Standalone)

1st thing to do is creating the *docker-compose.yml* from [docker-compose-standalone.yml](./docker-compose-standalone.yml):

```
cp docker-compose-standalone.yml docker-compose.yml
```

### Variables

Below paragraph:

```
####################################################
# LATENCY-MONITOR
####################################################
```

in the **.env** file *(env needs to be renamed to .env)* configure following variables:

- YOUR_ORGANIZATION
- YOUR_BUCKET_NAME
- YOUR_ADMIN_TOKEN
- YOUR_MONITORED_TARGET
- YOUR_MONITORED_TARGET_TIMER
- YOUR_MONITORED_TARGET_LOCATION

### Lets go

```
docker-compose up -d latency-monitor
```

should do the job


-----
-----


## Configuration (Full-Stack)

### Easy peasy automatic mode

Have a look at [./setup-full_stack.sh](./setup-full_stack.sh)

Just create a valid *.env* File by:

```
cp env .env
```

and edit it to your needs.

After everyting within *.env* is in order just do:

```
./setup-full_stack.sh
```

Everything should be right in place now.

Just the certificates are missing look [here](#certificate)

Now run it and mybe pick a example dashboard for grafana from [here](#grafana-dashboard-examples)

-----
-----

### WTF manual mode

REALLY???

You need to set all on your own:

#### Variables

You need to configure Variables in following files to make the compose work:

- **file**
  - VARIABLE1
  - VARIABLE2
  - VARIABLE3

-----

- **docker-compose.yml** *(was docker-compose-full_stack.yml before)*
  - PLACE_YOUR_FQDN_HERE (3 times)

-----

- **.env** *(env needs to be renamed to .env)*
  - YOUR_PATH_TO_CONTAINER_STATIC_DATA
  - YOUR_ADMIN_USER
  - YOUR_ADMIN_PASSWORD
  - YOUR_ORGANIZATION
  - YOUR_BUCKET_NAME
  - YOUR_ADMIN_TOKEN
  - YOUR_MONITORED_TARGET
  - YOUR_MONITORED_TARGET_TIMER
  - YOUR_MONITORED_TARGET_LOCATION

-----

- **grafana/provisioning/datasources/grafana-datasource.yml**
  - YOUR_ADMIN_TOKEN
  - YOUR_ORGANIZATION
  - YOUR_BUCKET_NAME

-----

#### File Permissions

Because we are configuring *grafana* for permanent data storing and *grafana* actually runs with *UID* + *GID*: *472:472* it´s necessary to change permisson of die permanent storage directory we have configured.

The directory build from the following config part of grafana within the docker-compose.yml:

```
${MyPath}/grafana/var_lib
```

*MyPath* was configured earlier in the *.env* file.

so let´s assume the following:

MyPath = /opt/docker/containers/

then you have to do the following

```
chown -R 472:472 /opt/docker/containers/grafana/var_lib
```

Everything should be right in place now.

Just the certificates are missing look [here](#certificate)

Now run it and mybe pick a example dashboard for grafana from [here](#grafana-dashboard-examples)

-----
-----

## Certificate

*Traefik* will act as a proxy and ensures the usage of TLS so it needs your certificate and key file.

within the *docker-compose.yml* you will find:

```
      - ./traefik/mycert.crt:/certs/cert.crt:ro
      - ./traefik/mycert.key:/certs/privkey.key:ro
```

so please place your certificate file as *./traefik/mycert.crt* and the key file as *./traefik/mycert.key*.

Thats it






## Grafana Dashboard Examples

Within the local path [./examples/grafana/](./examples/grafana/) you can find example *.json* files which can be imported to grafana as dashboards to give you a first point to start with.


-----
-----








## Authors

Contributors names and contact info

* [Sven Holz](mailto:code+latency-monitor@planet-espresso.com)

## Version History

* v0.2b
  * cleanup

* v0.2a
  * fixed some missing variables
  * fixe a missing integer declaration in latency-monitor
  * added automatic config creation for full-stack
  * cleanups

* v0.1
    * Initial Release

## License

free to use

