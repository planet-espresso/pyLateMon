#!/bin/bash

# Check if .env allready exists
if ! test -e .env; then
    echo "FAIL: You need to copy file env to .env and edit it!!!"
    exit 1
fi

# copy compose template to final compose file (OVERWRITTEN!!!) 
cp -f ./docker-compose-full_stack.yml ./docker-compose.yml

# locate my path
MyScriptPath=`dirname $0`
MyScriptPathContainer="$MyScriptPath/CONTAINER/"

# Replace .env MyPath Path with local path if NOT changed
echo "CHANGE: while not set, changing MyPath in .env to $MyScriptPathContainer"
sed -i -e "s#/YOUR_PATH_TO_CONTAINER_STATIC_DATA#$MyScriptPathContainer#g" .env

# Read variables from .env file
source .env

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
echo "CHANGE: replace YOUR_ADMIN_TOKEN with $INFLUX_TOKEN in $MyScriptPath/grafana/provisioning/datasources/grafana-datasource.yml"
sed -i -e "s/YOUR_ADMIN_TOKEN/$INFLUX_TOKEN/g" $MyScriptPath/grafana/provisioning/datasources/grafana-datasource.yml
echo "CHANGE: replace YYOUR_ORGANIZATION with $INFLUX_ORG in $MyScriptPath/grafana/provisioning/datasources/grafana-datasource.yml"
sed -i -e "s/YOUR_ORGANIZATION/$INFLUX_ORG/g" $MyScriptPath/grafana/provisioning/datasources/grafana-datasource.yml
echo "CHANGE: replace YOUR_BUCKET_NAME with $INFLUX_BUCKET in $MyScriptPath/grafana/provisioning/datasources/grafana-datasource.yml"
sed -i -e "s/YOUR_BUCKET_NAME/$INFLUX_BUCKET/g" $MyScriptPath/grafana/provisioning/datasources/grafana-datasource.yml

# Correct owner and permissions to satisfy the containers
echo "CHMOD: chmod -R 755 $MyPath"
chmod -R 755 $MyPath
echo "CHMOD: chmod 644 $MyScriptPath/grafana/datasources/grafana-datasource.yml"
chmod 644 $MyScriptPath/grafana/datasources/grafana-datasource.yml
echo "CHOWN: chown -R 472.472 $MyPath/grafana/var_lib"
chown -R 472.472 $MyPath/grafana/var_lib

echo "OK: All done"

