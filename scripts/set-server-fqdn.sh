#!/bin/sh
if [ ! -z "$2" ]; then
  echo "Not sure what to do with a second parameter."
  echo "exiting to be safe."
  exit 1
fi

CURRENT_FQDN=attestation.at.home
echo "Current server FQDN is '$CURRENT_FQDN'"

if [ -z "$1" ]; then
  printf "Enter new fqdn for server: "
  read NEW_FQDN
else
  NEW_FQDN=$1
fi
echo

if [ -z "$NEW_FQDN" ]; then
  echo "ERROR: New FQDN is empty."
  exit 1
fi

shopt -s nocasematch
if [ "$NEW_FQDN" == "$CURRENT_FQDN" ]; then
  echo "Current FQDN is the same as the new one."
  echo "So nothing to do for me :)"
  exit 1
fi


echo "Changing all config files in this repository from fqdn '$CURRENT_FQDN' to '$NEW_FQDN'"
for FILE in container/nginx/conf.d/default-compose.conf container/attestationserver/Dockerfile manifests/ingress.yaml scripts/set-server-fqdn.sh; do
  sed -i "s/$CURRENT_FQDN/$NEW_FQDN/g" ../$FILE
done
echo
echo "Changed."
echo "Tip: Please replace the certificate in container/nginx/conf.d/tls.crt as an valid certificate is needed for HSTS."
