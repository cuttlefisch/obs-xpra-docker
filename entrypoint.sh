#!/bin/bash

USER_UID=$(id -u)
USER_GID=$(id -g)
mkdir -p /run/user/${USER_UID}
chown $USER_UID:$USER_GID -R /run/user/${USER_UID}

cp /opt/xorg.conf /root/xorg.conf

exec "$@"

#exec su -s /bin/bash - user -c "$*"

