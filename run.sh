#!/bin/bash
echo "Starts minikube and argocd inside docker"
echo "You will get a shell after startup (serveral minutes)"

docker run --rm --name argocd -it --privileged -v /tmp/argocd:/var/lib/docker $(docker build -q .)