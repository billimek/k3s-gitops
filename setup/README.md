# Light-weight mixed-architecture cluster setup with k3s

## k3s master node installation

on the k3s 'master' k3s node, we tell flannel to use eth0:

```shell
k3sup install --ip 10.2.0.30 --k3s-extra-args '--no-deploy servicelb' --user ubuntu
```

## k3s worker nodes installation

### amd64

```shell
for node in $(echo "10.2.0.31 10.2.0.32"); do
  k3sup join --ip "$node" --server-ip 10.2.0.30 --user ubuntu
done
```

### arm (e.g. rpi4)

We add a node taint to prevent scheduling unless there is a toleration in place. See [this comment](https://github.com/billimek/homelab-infrastructure/issues/2#issuecomment-522558754) for some background.

```shell
for node in $(echo "pi4-a pi4-b"); do
  ssh pi@"$node" "curl -sfL https://get.k3s.io | K3S_URL=https://10.2.0.30:6443 K3S_TOKEN=$(ssh ubuntu@10.2.0.30 'sudo cat /var/lib/rancher/k3s/server/node-token') sh -s - --node-taint arm=true:NoExecute"
done
```

## bootstrapping

### helm

```shell
kubectl -n kube-system create sa tiller
kubectl create clusterrolebinding tiller-cluster-rule \
    --clusterrole=cluster-admin \
    --serviceaccount=kube-system:tiller
helm init --service-account tiller --tiller-image jessestuart/tiller
```

### flux

* Install flux.  Where `git.url` should define the repo where the GitOps code lives:

```shell
helm repo add fluxcd https://charts.fluxcd.io
helm upgrade --install flux --values flux-values.yaml --namespace flux fluxcd/flux
```

* Once flux is installed, [get the SSH key and give it write access to the github repo](https://docs.fluxcd.io/en/latest/tutorials/get-started-helm.html#giving-write-access):

```shell
kubectl -n flux logs deployment/flux | grep identity.pub | cut -d '"' -f2
```

* Add the key to the repo as a deploy key with write access as [described in the instructions](https://docs.fluxcd.io/en/latest/tutorials/get-started-helm.html#giving-write-access)

## kubeseal

### brand-new cluster

If this is brand-new, get the new public cert via,

```shell
kubeseal --fetch-cert \
--controller-namespace=kube-system \
--controller-name=sealed-secrets \
>! pub-cert.pem
```

### restoring existing key

If desiring to restore the existing kubeseal key,

```shell
kubectl replace -f master.key --force
kubectl delete pod -n kube-system -l name=sealed-secrets-controller
```
