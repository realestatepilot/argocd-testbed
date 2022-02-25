#!/bin/bash
echo "Starts minikube and argocd inside docker"
echo "You will get a shell after startup (serveral minutes)"

# docker run --rm --name argocd -it --privileged -v /tmp/argocd:/var/lib/docker -p 8080:80 -p 443:443 $(docker build -q .)
docker run \
  --rm --name argocd -it --privileged -p 8080:8080 \
  -v $PWD/argocd-bootstrap:/argocd-bootstrap \
  -v $PWD/secrets:/secrets \
   $(docker build -q .)