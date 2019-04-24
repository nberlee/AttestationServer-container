#!/bin/sh

if [ ! -w . ] ; then
   echo "ERROR: $(pwd) is not writeable, this is needed for sqlite data and java crashlog/dumps."
   echo "       if this folder was volume-mounted please run:"
   echo "       sudo chown -R $(id -u):$(id -g) <volume-mount-dir>"
   exit 1
fi

sqlite3 attestation.db "CREATE TABLE IF NOT EXISTS Configuration (key TEXT PRIMARY KEY NOT NULL, value NOT NULL)"
sqlite3 attestation.db "INSERT OR REPLACE INTO Configuration VALUES ('emailUsername', '$EMAIL_USERNAME'), ('emailPassword', '$EMAIL_PASSWORD'), ('emailHost', '$EMAIL_HOST'), ('emailPort', '$EMAIL_PORT')"

unset EMAIL_USERNAME EMAIL_PASSWORD EMAIL_HOST EMAIL_PORT

exec "$@"