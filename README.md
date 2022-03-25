# argocd-testbed

Argocd acts as the heart of gitops driven deployments. Upgrading this can be challenging. You better test your setup before. This testbed can be used in situations where:
* ArgoCD is used as gitops state machine
* Secrets are handled by sops (pgp / age)
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

## Run argocd testbed

* keep your disk usage level under ~80% or deployment will fail (kubernetes disk pressure)
* startup takes about 5 min, downloading about 1GB
* files in /argocd-bootstrap and /secrets are mounted into docker

Run `run.sh` and wait. Finaly you get a shell. Now look at ArgoCD GUI how argocd deploys the test app. It's nice to see  but be patient.

Argocd webgui is reachable on http://argocd.ubuntu.localhost:8080, Login with admin / admin

See demo application with secrets on http://nginx.ubuntu.localhost:8080.

All keys and deployments  are read to run without any modification just to have a quick experience with to tool.

## Features 

* ArgoCD v2.3.2
* helm-secrets plugin
* encryption via sops / gpg (2.2)
* encryption via sops / age 
* LDAP Authentification
* deploy some apps at local cluster

## Detailed technics

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
