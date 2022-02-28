#!/bin/bash
echo "Starts minikube and argocd inside docker"
echo "You will get a shell after startup (serveral minutes)"

docker run \
  --rm --name argocd -it --privileged -p 8080:8080 \
  -v $PWD/argocd-bootstrap:/argocd-bootstrap \
  -v $PWD/secrets:/secrets \
  -v $PWD/helm-charts:/helm-charts \
   $(docker build -q .)