#/bin/bash
mkdir -p /srv/share/upload
chown -R nobody:nogroup /srv/share
chmod 0777 /srv/share/upload

echo "write ip address your client"
read ip
echo "write  netmask your  client"
read netmask

cat << EOF > /etc/exports
/srv/share $ip/$netmask(rw,sync,root_squash)
EOF
exportfs -r
exportfs -s
