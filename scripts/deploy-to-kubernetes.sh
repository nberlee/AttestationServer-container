#!/bin/sh
rm -f /tmp/attestation.tar /tmp/kustomize.tar

if [ ! -z "$2" ]; then
  echo "Not sure what to do with a second parameter."
  echo "exiting to be safe."
  exit 1
fi

if [ -z "$1" ]; then
  printf "Enter SSH connect string (username@)servername : "
  read SSHSERVER
else
  SSHSERVER=$1
fi

echo

if [ -z "$SSHSERVER" ]; then
  echo "ERROR: SSH connect string is empty."
  exit 1
fi


TAG=$(grep ATTESTATION_COMMIT=  ../container/attestationserver/Dockerfile | cut -d= -f2)
[ -z "$TAG" ] && TAG=$(grep ATTESTATION_BRANCH=  ../container/attestationserver/Dockerfile | cut -d= -f2)
[ -z "$TAG" ] && TAG=latest
echo "Exporting attestation-server:$TAG"
docker image save attestation-server:$TAG -o /tmp/attestation.tar 2>/dev/null
if [ ! -f /tmp/attestation.tar ]; then
  echo
  echo "Rebuilding the container image as exporting failed."
  ./build-container-image.sh
  echo
  echo "Trying to export container image again."
  docker image save attestation-server:$TAG -o /tmp/attestation.tar 2>/dev/null
  if [ ! -f /tmp/attestation.tar ]; then
    echo "Building container image or exporting image failed."
    exit 1
  fi
fi
cd ..

echo
echo "Modifying kubernetes manifest to use the new image tag"
sed -i "/^  - name: attestation-server/!b;n;c\ \ \ \ newTag: $TAG" kustomization.yaml

echo
echo "Collecting kubernetes kustomize manifest files"
tar cvf /tmp/kustomize.tar kustomization.yaml mailsettings.env container/nginx/nginx.conf container/nginx/conf.d/default-k8s.conf manifests

echo
echo "Uploading container image and manifest files to '$SSHSERVER'"
scp -r /tmp/kustomize.tar /tmp/attestation.tar ${SSHSERVER}:
rm -f /tmp/attestation.tar /tmp/kustomize.tar

echo
echo "SSHing to '${SSHSERVER}' for container image import and deployment"
ssh -t $SSHSERVER sudo sh -c "'
  mkdir -p /tmp/manifest-$TAG
  tar -xf kustomize.tar -C /tmp/manifest-$TAG
  rm kustomize.tar
  if [ ! -d /data/AttestationServerDB ]; then
    mkdir -p /data/AttestationServerDB
    chown 1000:1000 /data/AttestationServerDB
  fi
  echo "Importing image..."
  if [ -d /var/lib/rancher/k3s/agent/images ]; then
    mv attestation.tar /var/lib/rancher/k3s/agent/images
    systemctl restart k3s
    if ! which kustomize >/dev/null; then
      echo "Downloading and installing kustomize"
      wget -O /usr/local/bin/kustomize https://github.com/kubernetes-sigs/kustomize/releases/download/v2.0.3/kustomize_2.0.3_linux_amd64
      chmod +x /usr/local/bin/kustomize
    fi
    echo
    echo "Wait while k3s api recovers from restart"
    while ! k3s kubectl cluster-info 2>/dev/null 1>/dev/null; do sleep 1s; done
    echo 
    echo "Deploy"
    kustomize build /tmp/manifest-$TAG | kubectl apply -f -
  else
    docker load < attestation.tar
    echo 
    echo "Deploy"
    kubectl apply -k /tmp/manifest-$TAG
  fi

  rm -rf attestation.tar /tmp/manifest-$TAG
'"


