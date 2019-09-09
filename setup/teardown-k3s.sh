#!/bin/bash

K3S_MASTER="k3s-0"
K3S_WORKERS_AMD64="k3s-1 k3s-2"
K3S_WORKERS_RPI="pi4-a pi4-b pi4-c"

REPO_ROOT=$(git rev-parse --show-toplevel)
export KUBECONFIG="$REPO_ROOT/setup/kubeconfig"

server=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
echo "This is a desructive action that will delete everything and remove the kubernetes cluster served by $server"
while true; do
    read -p "Are you SURE you want to run this? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

# TODO: somehow delete/cleanup storage used by workloads before uninstalling agents. Otherwise there will be a lot storage used with no clean ownership
# maybe: delete helmreleases or forcefully delete pv/pvcs or drain all nodes first and then remove storage
# delete all workloads
for ns in $(kubectl get ns --field-selector="status.phase==Active" --no-headers -o "custom-columns=:metadata.name"); do
  # kubectl -n $ns delete pvc --all
  kubectl delete namespace "$ns" --wait=false
done
kubectl -n default delete deployments,statefulsets,daemonsets,pvc --all
kubectl -n kube-system delete statefulsets,daemonsets,pvc --all
sleep 10
kubectl -n kube-system delete deployments --all

# raspberry pi4 worker nodes
for node in $K3S_WORKERS_RPI; do
  echo "tearing-down rpi $node"
  ssh pi@"$node" "k3s-agent-uninstall.sh"
done

# amd64 worker nodes
for node in $K3S_WORKERS_AMD64; do
  echo "tearing-down amd64 $node"
  ssh ubuntu@"$node" "k3s-agent-uninstall.sh"
done

# k3s master node
echo "removing k3s from $K3S_MASTER"
ssh ubuntu@"$K3S_MASTER" "/usr/local/bin/k3s-uninstall.sh"
