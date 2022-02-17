# argocd-testbed
Argocd Tests for upgrade versions

## encrpytion via SOPS + age keys

_WARNING_

helm secrets bases on special uri to reference yaml files from external ressources (git, file etc). plugin `helm secrets` use this in argocd. last working version for this url handling is 2.2.3.

