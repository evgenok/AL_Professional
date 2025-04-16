echo "write ip address your server"
read ip

echo "$ip:/srv/share/ /mnt nfs vers=3,noauto,x-systemd.automount 0 0" >> /etc/fstab

systemctl daemon-reload
systemctl restart remote-fs.target

mount | grep mnt
