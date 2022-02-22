# argocd-testbed
Argocd Tests for upgrade versions

## Using

* keep your disk usage level under 80% or deployment will fail (kubernetes disk pressure)
* set your local hosts file with `127.0.0.1 argocd.ubuntu.localhost`
* startup takes about 5 min, downloading about 1GB
* open browser on http://argocd.ubuntu.localhost:8080

## Features 

* encryption via sops / gpg (2.2)
* encryption via sops / age (planed)

## encrpytion via SOPS + age keys

_WARNING_

helm secrets bases on special uri to reference yaml files from external ressources (git, file etc). plugin `helm secrets` use this in argocd. last working version for this url handling is 2.2.3.


## Motivation

Setting up all tools in right flavor can be challenging
* sops
* helm secrets plugin
* age
* minikube and deplyoment

This Docker bundles all together and all compnents are documented by design. Via shell access you can test installation. 


# Tests
curl --insecure  -H "Host: argocd.localhost.ubuntu" http://localhost:8080
