#!/usr/bin/env bash

ALERT_ID="$1"
CACHE=/var/lib/zabbix/zambarix_cache.json;

TMPFILE="/var/lib/zabbix/$ALERT_ID.tmp"

#Read alert value to tmpfile and onwards to VALUE variable
flock --shared "$CACHE.lock" -c "jq -r '.items[] | select(.Alert.id==$ALERT_ID) | .Alert.state' '$CACHE'" > "$TMPFILE"
read VALUE < "$TMPFILE"
rm "$TMPFILE"

#VALUE=$(flock --shared "$CACHE.lock" -c "jq -r '.items[] | select(.Alert.id==$ALERT_ID) | .Alert.state' '$CACHE'");
echo ${VALUE:-MAINTENANCE}


#
#GET_ALERT () {
#    flock --shared "$CACHE.lock" -c "jq -r '.items[] | select(.Alert.id==$ALERT_ID) | .Alert.state' '$CACHE'"
#}
#
##Execute command and override with default without the use of subshells
##https://stackoverflow.com/a/21636953/4527948
#
##Bind 3 to myfifo
#mkfifo /tmp/myfifo
#exec 3<> /tmp/myfifo
#
##Execute GET_ALERT, redirect to 3
#GET_ALERT 1>&3
#
##Read 3 to variable VALUE
#read -u3 VALUE
#
##Echo VALUE with default
#echo ${VALUE:-MAINTENANCE}
#
##Cleanup redirects and temps
#exec 3>&-
#rm /tmp/myfifo




#( #Lock "$CACHE.lock" as file descriptor 200
#    set -e
#    flock --shared 201
#    VALUE=$(jq -r '.items[] | select(.Alert.id=='"$ALERT_ID"') | .Alert.state' "$CACHE")
#
#) 201>"$CACHE.lock"
#
