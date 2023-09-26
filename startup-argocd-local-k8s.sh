#!/bin/bash

# startup base-image, remove last line `/bin/bash`. This has to be called at end of file
# so we can run more commands before getting to endless running shell

# deprec
# cat /usr/local/bin/startup.sh | grep -v "/bin/bash" > /usr/local/bin/startup-wrapped.sh
# source /usr/local/bin/startup-wrapped.sh

# manual right now
# minikube start --force --memory 4096 --cpus 2
# minikube addons enable ingress

####################################################################
### starting from here these steps required on production system ###

# prepare argocd helm deploy
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

kubectl config use-context minikube

# create ns if it not exists
kubectl create ns argocd
kubectl describe ns argocd || kubectl create namespace argocd

# secrets 
kubectl create secret  -n argocd generic gpg-key --from-file=$PWD/secrets/tenant1.key.gpg 
# add more files with --from-file=/secrets/tenant2.key.gpg
kubectl create secret  -n argocd generic age-key --from-file=$PWD/secrets/tenant1.key.age 

# wait for complete ingress roleout
kubectl rollout status -n ingress-nginx deployment.apps/ingress-nginx-controller

# setup local gpg - just for inital bootload argo with some secret content (LDAP, admin-pwd)
gpg --allow-secret-key-import --import $PWD/secrets/*.key.gpg
# setup all private age keys - needed if parts of argocd values are encrypted
mkdir -p $PWD/.config/sops/age
cat $PWD/secrets/*.key.age >> $PWD/.config/sops/age/keys.txt


# install argocd
# optionally deploy also secret file
if [ -f "$PWD/argocd-bootstrap/secret-argocd-values.yaml" ]; then
  helm secrets upgrade argocd -i -n argocd -f $PWD/argocd-bootstrap/secret-argocd-values.yaml -f $PWD/argocd-bootstrap/argocd-values.yaml argo/argo-cd --version 5.46.7
  # SECRET_VALUE_FILE='-f /argocd-bootstrap/secret-argocd-values.yaml'
else
  helm secrets upgrade argocd -i -n argocd -f $PWD/argocd-bootstrap/argocd-values.yaml argo/argo-cd --version 5.46.7
fi

# install vault secret
kubectl apply -n argocd -f $PWD/secrets/vault-secret.yaml

kubectl rollout status deployment.apps/argocd-repo-server -n argocd


### steps required on production system ending here ###
#######################################################



# configure tinyproxy with current service ip / port
# echo "upstream http `minikube service ingress-nginx-controller -n ingress-nginx --format "{{.IP}}:{{.Port}}" --url | head -1`" >> /etc/tinyproxy/tinyproxy.conf
# /etc/init.d/tinyproxy restart


# /bin/bash
