#!/bin/sh
TAG=$(grep ATTESTATION_COMMIT=  ../container/attestationserver/Dockerfile | cut -d= -f2)
[ -z "$TAG" ] && TAG=$(grep ATTESTATION_BRANCH=  ../container/attestationserver/Dockerfile | cut -d= -f2)
[ -z "$TAG" ] && TAG=latest

docker build ../container/attestationserver -t attestation-server:$TAG
