#!/usr/bin/env bash



groupName=ambariservices
username=zambarix
firstName='Zabbix'
lastName='Ambari'

echo "Add user '$username' to FreeIPA"


ssh kac-adm-001 <<EOF
set -e
set -x

ipa user-del $username

#Find available uid
groupID=\$(getent group $groupName | cut -d':' -f3)
#Find next available UID
uid=\$((groupID+1))
while id \$uid &>/dev/null; do uid=\$((uid+1)); done


#create user
ipa user-add $username --first=\"$firstName\" --homedir=/syshome/$username --uid=\$uid --shell=/sbin/nologin --gidnumber=\$uid --last=\"$lastName\" --class=SystemUser
ipa group-add-member $groupName --user $username

EOF


echo "set user password"
ssh kac-adm-001 <<EOF
set -e
set -x
#Create password
INITIAL_PASSWORD=\$(openssl rand -base64 12)
echo -e "\${INITIAL_PASSWORD}\n\${INITIAL_PASSWORD}\n" | ipa user-mod $username --password

PASSWORD=\$(openssl rand -base64 12)
echo -e "\${INITIAL_PASSWORD}\n\${PASSWORD}\n\${PASSWORD}\n" | kinit $username -c /tmp/null
echo $username: \${PASSWORD}
EOF


echo "Add user to syspass"
echo "TODO, do this yourself for now"


echo "sync user to ambari"

usersFile=$(mktemp)

ssh kac-abri-001 << EOF
echo zambarix >> $usersFile
sudo ambari-server sync-ldap --users=$usersFile
rm $usersFile
EOF


echo "set ambari user role to 'Cluster users'"

body='[ { "PrivilegeInfo": { "permission_name":"CLUSTER.USER", "principal_name":"'$username'", "principal_type":"USER" } } ]'
curl \
    -n \
    -i \
    -H 'X-Requested-By: ambari' \
    -X POST \
    "http://kac-abri-001.kach.sblokalnet:8080/api/v1/clusters/KAC/privileges" \
    -d "$body"

echo "Update ~/.netrc with user $username"
grep 'kac-abri-001' ~/.netrc | grep $username || echo "machine kac-abri-001.kach.sblokalnet login $username password PASSWORD"




