# argocd-testbed

Argocd acts as the heart of gitops driven deployments. Upgrading this can be challenging. You better test your setup before. This testbed can be used in situations where:
* ArgoCD is used as gitops state machine
* Secrets are handled by sops (pgp / age / Hashicorp Vault)
* deployments use helm-charts if secrets are needed

NEVER use this in production or test production systems!
* changes are not persistent
* admin password is fix, simple and unsecure

## Motivation

Setting up all tools in right flavor can be challenging
* [sops](https://github.com/mozilla/sops)
* [helm secrets plugin](https://github.com/jkroepke/helm-secrets)
* [age](https://github.com/FiloSottile/age/)
* minikube and deployment

This Docker bundles all together and all components are documented due docker file and scripts. You can test installation via browser and shell access. All needed command line tools are preconfigured.

## Setup and Requirements

To access argocd and nginx via browser append 
`127.0.0.1 *.ubuntu.localhost`
to your local hosts file.


## Run Argcd testbed - using existing minikube

### Install Requirements

generally needed:
* [minikube](https://minikube.sigs.k8s.io/docs/start/)
* kubectl
* helm with secrets plugin
* gpg


```
mkdir -p $PWD/bin/
cd $PWD/bin/
wget https://github.com/mozilla/sops/releases/download/v3.7.2/sops-v3.7.2.linux
chmod +x sops-v3.7.2.linux
mv sops-v3.7.2.linux sops

wget https://github.com/FiloSottile/age/releases/download/v1.0.0/age-v1.0.0-linux-amd64.tar.gz
tar xfvz age-v1.0.0-linux-amd64.tar.gz 
mv age age_ 
mv age_/age . 
mv age_/age-keygen .
rm -rf age_

helm plugin install https://github.com/jkroepke/helm-secrets --version v3.12.0
cd ..

```

* a Hashicorp Vault with transit engine and an [approle access](https://developer.hashicorp.com/vault/docs/auth/approle)
  * put role_id an secret_id into `secrets/vault-secret.yaml' (see template `secrets/vault-secret.yaml.template')

For vault transit secrets you should be able to encrypt content locally via your vault. Place `.sops` file at approbpriate location.


### Run
```
minikube start --force --memory 4096 --cpus 2
```

First time start:
* install CRDs `kubectl apply -k "https://github.com/argoproj/argo-cd/manifests/crds?ref=v2.8.4"`
* install vault approle secrets `kubectl create ns argocd; kubectl apply -f secrets/vault-secret.yaml`
* encrypt secret-values-vault-transit.yaml.cleartext via vault transit `helm secrets encrypt secret-values-vault-transit.yaml.cleartext > secret-values-vault-transit.yaml`

Script `startup-argocd-local-k8s.sh` rolls out the ArgoCD Deployment and your secrets.
Open ArgoCD GUI with your port forward.


## Run argocd testbed - Docker In Docker (unsupported and maybe broken)

* keep your disk usage level under ~80% or deployment will fail (kubernetes disk pressure)
* startup takes about 5 min, downloading about 1GB
* files in /argocd-bootstrap and /secrets are mounted into docker

Run `run.sh` and wait. Finaly you get a shell. Now look at ArgoCD GUI how argocd deploys the test app. It's nice to see  but be patient.

Argocd webgui is reachable on http://argocd.ubuntu.localhost:8080, Login with admin / admin

See demo application with secrets on http://nginx.ubuntu.localhost:8080.

All keys and deployments  are read to run without any modification just to have a quick experience with to tool.

## Features 

* ArgoCD 2.8.4
* helm secrets 4.5.1
* sops 3.7.2
* encryption via sops / gpg (2.2)
* encryption via sops / age 
* encryption via Vault transit Engine
* LDAP Authentification
* deploy some apps at local cluster

## Detailed technics

## Integration Vault in ArgoCD
* Init-Container defined in `argocd-bootstrap/argocd-values.yaml`
  * used with helm install on startup script
  * download tools needed to enhance argocd-reposerver
  * patch helm secrets hook ti inject the currently vault login token into environment
* Sidecar-Container defined in `argocd-bootstrap/argocd-values.yaml` as `extraContainer`
  * runs `vault agent` to refresh token regulary

## encrpytion via SOPS

_WARNING_

helm secrets bases on special uri to reference yaml files from external ressources (git, file etc). plugin `helm secrets` use this in argocd. last working version for this url handling is 2.2.3.
see https://github.com/jkroepke/helm-secrets/issues/185


According to author of helm secrets plugin Age should be prefered over PGP. This testbed support
* existing GPG encrypted files
* existing AGE encrypted files
* encrypt new files via age

SOPS can handle multiple encryption provider. So for decryption it uses the engine referenced in encrypted file. Keys must be placed at right location inside agro-resp-server and local machine of course. For encryption it uses .sops.yaml config file and read public keys from it.

See following instructions how to handle keys. Keys for demo purposes are included under /secrets.

### Age encrpytion

on container shell this solution works for one recipient:

generate key pair inside docker shell
```
age-keygen -o /secrets/tenant1.key.age
```

#### config sops

create `.sops.yaml` with
``` 
creation_rules:
  - age: 'age1vfklxarn ..... '
```
(take private key from generated file above)


`helm secrets enc file.yaml` encrypts file with age
`helm secrets edit file.yaml` open default editor to edit encrypted file

### Transit Encyption via Hashicorp Vault

Problem: 
* Encryted data need always the same key to decrypt
* key is saved inside vault
* Vault devmode don allow persisence but 
* devmode keeps testbed simple

Solution:
* author has exported key used for encrypt demo data
* setup container does
  * enable vault transit encryption (vault container)
  * restore prepared key into vault (secondary container with curl)
  
Setup for testbed:
* Argocd Application for Vault
  * devMode
  * no persistence
* setup-Container to Configure transit Encryption
  1. vault container 

####

### GPG for leagcy files

**Create new key pair**

```
gpg --batch --generate-key <<EOF
%no-protection
Key-Type: default
Subkey-Type: default
Name-Real: tenant1
Name-Email: you@tenant1.org
Expire-Date: 0
EOF
```

**get fingerprint (public key)**

```
# gpg --fingerprint
gpg: checking the trustdb
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
/root/.gnupg/pubring.kbx
------------------------
pub   rsa3072 2022-02-25 [SC]
      30B1 28A6 8534 A766 A646  DCDF D1E7 6CE1 660D 14D6
uid           [ultimate] tenant1 <you@tenant1.org>
sub   rsa3072 2022-02-25 [E]
```
(line "30B1 ..." contains the public key)

**get secret key (aka private key)**

```
gpg --export-secret-key  tenant1 > /secrets/tenant1.key.gpg
```

**import existing secret key**

In case of sops files encrypted with gpg, import your private key
```
gpg --allow-secret-key-import --import /secrets/tenant1.key.gpg
``` 

more on gpg see https://poweruser.blog/how-to-encrypt-secrets-in-config-files-1dbb794f7352

# Tests

If somthing goes wrong run tests inside docker:

test if argocd is running and if ingress is defined correct
```
curl -H "Host: argocd.localhost.ubuntu" http://localhost:8080
```

show encrypted content with various encryption provider
```
curl -H "Host: nginx.localhost.ubuntu" http://localhost:8080
```

# Changes

## v0.3.0

Status:
* argocd-testbed no longer depands on individual repo server image
* refactor init-container to run on minikube
* describe test setup with local minikube
* support Hashicorb Vault Transit Encryption
  * introduce vault agent sidecar for refreshing token
  * patch helm wrapper to inject currently valid token into helm templating process
  * uses AppRole Authentication
  * only supported in local minikube environment
* ingresses dont used any longer - use port forward

Upgrade from 0.2.1
* Upgrade CRD with `kubectl apply -k "https://github.com/argoproj/argo-cd/manifests/crds?ref=v2.8.4"`
* CRD will managed outside helm, add argument to script


## 0.2.1 
* upgrade dependency ngin helm chart
* fix init-container

## v0.2.0
* use ArgoCD v2.3.2
* increment sops to v3.7.2
* add env params for helm secrets plugin
* use standard argocd docker image

## v0.1.0
inital version for ArgoCD 2.2.4

# Author

Thomas Grünert (2022) on [Github](https://github.com/tgruenert) or [linkedIn](https://www.linkedin.com/in/thomas-gr%C3%BCnert/)

Thanks also to my current employer [RealEstatePilot AG](https://realestatepilot.com) which is supporting me on this.
