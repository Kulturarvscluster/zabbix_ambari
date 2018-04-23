#!/usr/bin/env bash

set -e
set -x

SCRIPT_DIR=$(dirname $(readlink -f $BASH_SOURCE[0]))

HOST=${1:-root@kac-abri-001}

cd $SCRIPT_DIR

ssh $HOST sudo yum -y install jq

scp ambari_lld.py $HOST:/var/lib/zabbix/

ssh $HOST chown zabbix:zabbix /var/lib/zabbix/ambari_lld.py

#Create a file `/var/lib/zabbix/.netrc` with this content and set permissions to 0700

grep zambarix ~/.netrc | xargs -r -I{} ssh $HOST " ( cat /var/lib/zabbix/.netrc | grep '{}') || (echo '{}' | cat > /var/lib/zabbix/.netrc ) ; chmod go-rwx /var/lib/zabbix/.netrc; chown zabbix:zabbix /var/lib/zabbix/.netrc"

scp userparameter_ambari_alerts.conf $HOST:/etc/zabbix/zabbix_agentd.d/

ssh $HOST systemctl restart zabbix-agent

echo "You must disable selinux or install a module to allow zabbix to make http requests"