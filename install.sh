#!/usr/bin/env bash

set -e
set -x

SCRIPT_DIR=$(dirname $(readlink -f $BASH_SOURCE[0]))

HOST=${1:-root@kac-abri-001}

INSTALL_DIR="/var/lib/zabbix/externalscripts/"

cd $SCRIPT_DIR

#Install jq if not already there
ssh $HOST "jq --version || sudo yum -y install jq"

#Install scripts
chmod a+x *.sh
scp -p ambari_lld.py ambari.alert.sh ambari.alerts.update.sh "$HOST:$INSTALL_DIR"

#Ensure that zabbix own all
ssh $HOST chown zabbix:zabbix "$INSTALL_DIR/*"

#Install zabbix user params
scp -p userparameter_ambari_alerts.conf $HOST:/etc/zabbix/zabbix_agentd.d/

#Create a file `/var/lib/zabbix/.netrc` with this content and set permissions to 0700
grep zambarix ~/.netrc | xargs -r -I{} ssh $HOST " ( cat /var/lib/zabbix/.netrc | grep '{}') || (echo '{}' | cat > /var/lib/zabbix/.netrc ) ; chmod go-rwx /var/lib/zabbix/.netrc; chown zabbix:zabbix /var/lib/zabbix/.netrc"

#Restart zabbix agent to pick up the new userparameters
ssh $HOST systemctl restart zabbix-agent

echo "You must disable selinux or install a module to allow zabbix to make http requests"