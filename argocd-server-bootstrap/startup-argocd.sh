#!/bin/bash

# startup des base-image, wobei der letzte auruf /bin/bash entfernt wird. dieser muss 
# am ende dieses scripts plaziert werden.

cat /usr/local/bin/startup.sh | grep -v "/bin/bash" > /usr/local/bin/startup-wrapped.sh
source /usr/local/bin/startup-wrapped.sh

minikube start --force --memory 4096 --cpus 2
minikube addons enable ingress

# prepare argocd helm deploy
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# secrets 
kubectl create ns argocd
kubectl create secret  -n argocd generic gpg-key --from-file=/argocd/realestatepilot.key.gpg --from-file=/argocd/evermind.key.gpg

# wait for complete ingress roleout
kubectl rollout status -n ingress-nginx deployment.apps/ingress-nginx-controller

# install argocd
# helm upgrade argocd -i -n argocd -f /argocd/secret-argocd-values.yaml argo/argo-cd --version 3.33.3

# kubectl get all -A 
# kubectl rollout status deployment.apps/argocd-repo-server -n argocd

# configure tinyproxy with current service ip / port
echo "upstream http `minikube service ingress-nginx-controller -n ingress-nginx --format "{{.IP}}:{{.Port}}" --url | head -1`" >> /etc/tinyproxy/tinyproxy.conf
/etc/init.d/tinyproxy restart


/bin/bash
