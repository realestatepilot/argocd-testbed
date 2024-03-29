FROM alpine as tools

WORKDIR /apps

RUN apk update
RUN apk add curl

# Tools to run argocd as helm-chart and using secrets therefor
# install sops 
RUN wget https://github.com/mozilla/sops/releases/download/v3.7.2/sops-v3.7.2.linux
RUN chmod +x sops-v3.7.2.linux
RUN mv sops-v3.7.2.linux sops

RUN wget https://github.com/FiloSottile/age/releases/download/v1.0.0/age-v1.0.0-linux-amd64.tar.gz
RUN tar xfvz age-v1.0.0-linux-amd64.tar.gz 
RUN mv age age_ 
RUN mv age_/age . 
RUN mv age_/age-keygen .

RUN curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
  && chmod +x minikube

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.23.0/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl


FROM cruizba/ubuntu-dind:20.10.9

COPY --from=tools /apps/ /usr/local/bin/

RUN apt-get update

# install git, gpg
RUN apt-get install -y git gpg nano vim tinyproxy

 # install helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# helm secrets
RUN helm plugin install https://github.com/jkroepke/helm-secrets --version v3.12.0

COPY startup-argocd.sh /
RUN chmod +x /startup-argocd.sh

COPY tinyproxy.conf /etc/tinyproxy/

ENTRYPOINT ["/startup-argocd.sh"]