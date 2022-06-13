# Docker Based Latency Monitor

Docker container which tracks latency of one or many hosts and reports to InfluxDBv2.

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

Configuration can be passed via ENV **OR** configuration file.

In case of using the ENV option you are just able to monitor **ONE** target for more targets please use the configuration file. 

Also some influx connection options are just configurable via config file but normally they are not needed.

Per default the python influx connector will cache all replies and sends them bundled every 30 seconds to the Influx DB.

The container will be build at 1st start.

You can find everything under *./Docker_Build/* and in the python program itself [latency_monitor.py](./Docker_Build/latency_monitor.py)

## Requirements

- Docker
- Docker-Compose
- InfluxDB Version >= 2
- pythonping needs root privileges so same for the container

## ENV Variables

Name | Example | Usage | Option/Must
:------: | :-----: | :-----: | :-----:
INFLUX_URL | http://10.0.0.1:8086 | InfluxDB Host | must
INFLUX_TOKEN | eWOcp-MCv2Y3IJPlER7wc...ICKirhw0lwEczRNnrIoTqZAg== | InfluxDB API Token | must
INFLUX_BUCKET | latency | InfluxDB Bucket | must
INFLUX_ORG | MyOrg | InfluxDB Organization | must
TARGET_HOST | 8.8.8.8 | Monitored Host (IP/FQDN) | must
TARGET_TIMER | 3 | ping frequency in sec. | option
TARGET_LOCATION | Google | decript. location | option

## Config File

**Instead** of using the ENV variables you can use a config file.

**Keep in mind it´s a OR decision not a AND**  

See [template_config.ini](./Docker_Build/template_config.ini)

Rename the file to *config.ini* make your changes and add it as a volume mount to the container:

### Docker-Compose Style

```
        volumes:
            - /YOUR_PATH/config.ini:/app/config.ini
```

### Docker-CLI Style

```
            docker latency-monitor -v /YOUR_PATH/config.ini:/app/config.ini
```


-----
-----


## Compose Files

### FULL-STACK

1st thing to do is creating the *docker-compose.yml from [docker-compose-full_stack.yml](./docker-compose-full_stack.yml):

```
cp docker-compose-full_stack.yml docker-compose.yml
```

#### Certificate

*Traefik* will act as a proxy and ensures the usage of TLS so it needs your certificate and key file.

within the *docker-compose.yml* you will find:

```
      - ./traefik/mycert.crt:/certs/cert.crt:ro
      - ./traefik/mycert.key:/certs/privkey.key:ro
```

so please place your certificate file as *./traefik/mycert.crt* and the key file as *./traefik/mycert.key*.

Thats it

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

#### Lets go

```
docker-compose up -d
```

should do the job


#### Grafana Dashboard Examples

Within the local path *./examples/grafana/*  you can find example *.json* files which can be imported to grafana as dashboards to give you a first point to start with.


-----
-----


### STANDALONE

1st thing to do is creating the *docker-compose.yml from [docker-compose-standalone.yml](./docker-compose-standalone.yml):

```
cp docker-compose-standalone.yml docker-compose.yml
```


#### Variables

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


#### Lets go

```
docker-compose up -d latency-monitor
```

should do the job


## Authors

Contributors names and contact info

* [Sven Holz](mailto:code+latency-monitor@planet-espresso.com)

## Version History

* v0.1
    * Initial Release

## License

free to use

