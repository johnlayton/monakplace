#!/usr/bin/env zsh

. ~/.zshrc

logger title "Initialisation"

logger info "Create and start kube"
kube init

logger title "Prerequisites"

logger info "Add the flux chart repo (and list repos)"
helm repo add fluxcd https://charts.fluxcd.io
helm repo list

logger info "Create the flux namespace and install flux"
kubectl create ns flux
helm upgrade -i flux fluxcd/flux --wait \
  --namespace flux \
  --set registry.pollInterval=1m \
  --set git.pollInterval=1m \
  --set git.url=git@github.com:johnlayton/monakplace

logger info "Get the deployment key and add to repo"
fluxctl identity --k8s-fwd-ns flux
open "http://github.com/johnlayton/monakplace/settings/keys"

logger info "Install the helm operator"
helm upgrade -i helm-operator fluxcd/helm-operator --wait \
  --namespace flux \
  --set git.ssh.secretName=flux-git-deploy \
  --set git.pollInterval=1m \
  --set chartsSyncInterval=1m \
  --set helm.versions=v3

logger info "Install and check linkerd.  Note takes a while"
linkerd install > tools/linkerd.yaml
kubectl apply -f tools/linkerd.yaml
#linkerd install | kubectl apply -f -
linkerd check

logger info "Install and check flagger"
helm repo add flagger https://flagger.app
helm repo list

wget -O tools/flagger.yaml https://raw.githubusercontent.com/weaveworks/flagger/master/artifacts/flagger/crd.yaml
kubectl apply -f tools/flagger.yaml

helm upgrade -i flagger flagger/flagger --wait \
  --namespace linkerd \
  --set crd.create=false \
  --set metricsServer=http://linkerd-prometheus:9090 \
  --set meshProvider=linkerd

logger info "Start linkerd"
linkerd dashboard &

logger info "Start minikube tunnel"
minikube tunnel