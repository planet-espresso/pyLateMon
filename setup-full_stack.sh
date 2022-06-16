#!/bin/bash

Date=`date +%Y%m%d_%H%M%s`

# locate my path
MyScriptPath=`dirname $0`
MyScriptPathContainer="$MyScriptPath/CONTAINER/"

# Check if .env allready exists
if ! test -e $MyScriptPath/.env; then
    echo "FAIL: You need to copy file env to .env and edit it!!!"
    exit 1
fi

# backup old compose files
cp -f $MyScriptPath/docker-compose.yml $MyScriptPath/docker-compose-$Date.backup
# copy compose template to final compose file (OVERWRITTEN!!!) 
cp -f $MyScriptPath/docker-compose-full_stack.yml $MyScriptPath/docker-compose.yml

# Make relevant grafana templating direcotries
echo "MKDIR: creating $MyScriptPath/grafana/provisioning/datasources"
mkdir -p $MyScriptPath/grafana/provisioning/datasources
# backup old grafana datasource file
cp -f $MyScriptPath/grafana/provisioning/datasources/grafana-datasource.yml $MyScriptPath/grafana/grafana-datasource-$Date.backup
# copy grafana datasource file template to grafana datasource file
cp -f $MyScriptPath/grafana/grafana-datasource-template.yml $MyScriptPath/grafana/provisioning/datasources/grafana-datasource.yml


# Replace .env MyPath Path with local path if NOT changed
sed -i -e "s#/YOUR_PATH_TO_CONTAINER_STATIC_DATA#$MyScriptPathContainer#g" $MyScriptPath/.env


# Read variables from .env file
source $MyScriptPath/.env

echo "INFO: MyPath is $MyPath"

# Make relevant direcotries
echo "MKDIR: creating $MyPath"
mkdir -p $MyPath
echo "MKDIR: creating $MyPath/influxdb/"
mkdir -p $MyPath/influxdb/
echo "MKDIR: creating $MyPath/grafana/var_lib"
mkdir -p $MyPath/grafana/var_lib

# Changes in docker-compose.yml
echo "CHANGE: replace PLACE_YOUR_FQDN_HERE with $MyFQDN in $MyScriptPath/docker-compose.yml"
sed -i -e "s/PLACE_YOUR_FQDN_HERE/$MyFQDN/g" $MyScriptPath/docker-compose.yml

# Changes in grafana/provisioning/datasources/grafana-datasource.yml
echo "CHANGE: replace YOUR_INFLUXDB_URL with $INFLUX_URL in $MyScriptPath/grafana/provisioning/datasources/grafana-datasource.yml"
sed -i -e "s#YOUR_INFLUXDB_URL#$INFLUX_URL#g" $MyScriptPath/grafana/provisioning/datasources/grafana-datasource.yml
echo "CHANGE: replace YOUR_ADMIN_TOKEN with $INFLUX_TOKEN in $MyScriptPath/grafana/provisioning/datasources/grafana-datasource.yml"
sed -i -e "s/YOUR_ADMIN_TOKEN/$INFLUX_TOKEN/g" $MyScriptPath/grafana/provisioning/datasources/grafana-datasource.yml
echo "CHANGE: replace YOUR_ORGANIZATION with $INFLUX_ORG in $MyScriptPath/grafana/provisioning/datasources/grafana-datasource.yml"
sed -i -e "s/YOUR_ORGANIZATION/$INFLUX_ORG/g" $MyScriptPath/grafana/provisioning/datasources/grafana-datasource.yml
echo "CHANGE: replace YOUR_BUCKET_NAME with $INFLUX_BUCKET in $MyScriptPath/grafana/provisioning/datasources/grafana-datasource.yml"
sed -i -e "s/YOUR_BUCKET_NAME/$INFLUX_BUCKET/g" $MyScriptPath/grafana/provisioning/datasources/grafana-datasource.yml

# Correct owner and permissions to satisfy the containers
echo "CHMOD: chmod -R 755 $MyPath"
chmod -R 755 $MyPath
echo "CHMOD: chmod -R 755 $MyScriptPath/grafana/provisioning"
chmod -R 755 $MyScriptPath/grafana/provisioning 
echo "CHMOD: chmod 644 $MyScriptPath/grafana/provisioning/datasources/grafana-datasource.yml"
chmod 644 $MyScriptPath/grafana/provisioning/datasources/grafana-datasource.yml
echo "CHOWN: chown -R 472.472 $MyPath/grafana/var_lib"
chown -R 472.472 $MyPath/grafana/var_lib

echo "OK: All done"

