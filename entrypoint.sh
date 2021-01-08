echo "starting ssh as root"
service ssh start &
#gosu root /usr/sbin/sshd -D &

echo "starting tail user"
exec tail -f /dev/null
