#!/bin/bash

# nodes
K3S_MASTER="k3s-0"
K3S_WORKERS_AMD64="k3s-1 k3s-2"
K3S_WORKERS_RPI="pi4-a pi4-b pi4-c"

REPO_ROOT=$(git rev-parse --show-toplevel)

need() {
    which "$1" &>/dev/null || die "Binary '$1' is missing but required"
}

need "curl"
need "ssh"
need "kubectl"
need "helm"

message() {
  echo -e "\n######################################################################"
  echo "# $1"
  echo "######################################################################"
}

k3sMasterNode() {
  message "installing k3s master to $K3S_MASTER"
  ssh -o "StrictHostKeyChecking=no" ubuntu@"$K3S_MASTER" "curl -sLS https://get.k3s.io | INSTALL_K3S_EXEC='server --tls-san $K3S_MASTER --no-deploy servicelb --no-deploy traefik' sh -"
  ssh -o "StrictHostKeyChecking=no" ubuntu@"$K3S_MASTER" "sudo cat /etc/rancher/k3s/k3s.yaml | sed 's/server: https:\/\/127.0.0.1:6443/server: https:\/\/$K3S_MASTER:6443/'" > "$REPO_ROOT/setup/kubeconfig"
  NODE_TOKEN=$(ssh -o "StrictHostKeyChecking=no" ubuntu@"$K3S_MASTER" "sudo cat /var/lib/rancher/k3s/server/node-token")
}

ks3amd64WorkerNodes() {
  for node in $K3S_WORKERS_AMD64; do
    message "joining amd64 $node to $K3S_MASTER"
    ssh -o "StrictHostKeyChecking=no" ubuntu@"$node" "curl -sfL https://get.k3s.io | K3S_URL=https://k3s-0:6443 K3S_TOKEN=$NODE_TOKEN sh -s -"
  done
}

ks3armWorkerNodes() {
  for node in $K3S_WORKERS_RPI; do
    message "joining pi4 $node to $K3S_MASTER"
    ssh -o "StrictHostKeyChecking=no" pi@"$node" "curl -sfL https://get.k3s.io | K3S_URL=https://k3s-0:6443 K3S_TOKEN=$NODE_TOKEN sh -s - --node-taint arm=true:NoExecute --data-dir /mnt/usb/var/lib/rancher"
  done
}

installHelm() {
  message "installing helm (tiller)"
  # generate files locally instead of against the cluster directly ?
  # TMPFILE=`mktemp /tmp/helm.XXXXXX` || exit 1
  # kubectl -n kube-system create sa tiller --dry-run -o=yaml >> "$TMPFILE"
  # echo "---" >> "$TMPFILE"
  # kubectl create clusterrolebinding tiller-cluster-rule \
  #     --clusterrole=cluster-admin \
  #     --serviceaccount=kube-system:tiller \
  #     --dry-run -o=yaml >> "$TMPFILE"
  # echo "---" >> "$TMPFILE"
  # helm init --service-account tiller -o=yaml >> "$TMPFILE"

  kubectl -n kube-system create sa tiller
  kubectl create clusterrolebinding tiller-cluster-rule \
      --clusterrole=cluster-admin \
      --serviceaccount=kube-system:tiller
  helm init --wait --service-account tiller

  HELM_SUCCESS="$?"
  if [ "$HELM_SUCCESS" != 0 ]; then
    echo "helm init failed - no bueno!"
    exit 1
  fi
}

installFlux() {
  message "installing flux"
  # install flux
  helm repo add fluxcd https://charts.fluxcd.io
  helm upgrade --install flux --values "$REPO_ROOT"/setup/flux-values.yaml --namespace flux fluxcd/flux

  FLUX_READY=1
  while [ $FLUX_READY != 0 ]; do
    echo "waiting for flux pod to be fully ready..."
    kubectl -n flux wait --for condition=available deployment/flux
    FLUX_READY="$?"
    sleep 5
  done

  # grab output the key
  FLUX_KEY=$(kubectl -n flux logs deployment/flux | grep identity.pub | cut -d '"' -f2)

  message "adding the key to github automatically"
  "$REPO_ROOT"/setup/add-repo-key.sh "$FLUX_KEY"
}

kapply() {
  if output=$(envsubst < "$@"); then
    printf '%s' "$output" | kubectl apply -f -
  fi
}

installManualObjects(){
  . "$REPO_ROOT"/setup/.env

  message "installing manual secrets and objects"
  ##########
  # secrets
  ##########
  kubectl --namespace kube-system delete secret vault > /dev/null 2>&1
  kubectl --namespace kube-system create secret generic vault --from-literal=vault-unwrap-token="$VAULT_UNSEAL_TOKEN"

  #########################
  # cert-manager bootstrap
  #########################
  CERT_MANAGER_READY=1
  while [ $CERT_MANAGER_READY != 0 ]; do
    echo "waiting for cert-manager to be fully ready..."
    kubectl -n kube-system wait --for condition=Available deployment/cert-manager > /dev/null 2>&1
    CERT_MANAGER_READY="$?"
    sleep 5
  done
  kapply "$REPO_ROOT"/kube-system/cert-manager/cert-manager-letsencrypt.txt
}

k3sMasterNode
ks3amd64WorkerNodes
ks3armWorkerNodes

export KUBECONFIG="$REPO_ROOT/setup/kubeconfig"
installHelm
installFlux
installManualObjects

# bootstrap vault
"$REPO_ROOT"/setup/bootstrap-vault.sh

message "all done!"
kubectl get nodes -o=wide
