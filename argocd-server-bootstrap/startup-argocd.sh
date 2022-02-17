#!/bin/bash

# startup des base-image
cat /usr/local/bin/startup.sh | grep -v "/bin/bash" > /usr/local/bin/startup-wrapped.sh
source /usr/local/bin/startup-wrapped.sh

minikube start --force

kubectl cluster-info
kubectl get all -A 


/bin/bash