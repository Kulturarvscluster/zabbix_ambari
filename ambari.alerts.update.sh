#!/usr/bin/env bash

AMBARI_URL="$1"


TMPFILE="/var/lib/zabbix/CLUSTER_NAME"

#Read cluster name from Ambari without subshell
/usr/bin/curl -n -s -H 'X-Requested-By: ambari' "$AMBARI_URL/api/v1/clusters/" | jq -r '.items[0].Clusters.cluster_name' > "$TMPFILE"
read CLUSTER_NAME < "$TMPFILE"
rm "$TMPFILE"

CACHE=/var/lib/zabbix/zambarix_cache.json;

flock --exclusive "$CACHE.lock" -c "\
    /bin/rm -f '$CACHE'; \
    /usr/bin/curl -n -s -H 'X-Requested-By: ambari' '$AMBARI_URL/api/v1/clusters/$CLUSTER_NAME/alerts?fields=*&Alert/maintenance_state=OFF' -o '$CACHE'";

jq -r '.items | length' "$CACHE"

#
#( #Lock "$CACHE.lock" as file descriptor 200
#    set -e
#    flock --exclusive 200
#    /bin/rm -f "$CACHE";
#    /usr/bin/curl -n -s -H 'X-Requested-By: ambari' "$AMBARI_URL/api/v1/clusters/$CLUSTER_NAME/alerts?fields=*&Alert/maintenance_state=OFF" -o "$CACHE";
#    jq -r '.items | length' "$CACHE"
#
#) 200>"$CACHE.lock"
