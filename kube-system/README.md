# cert-manager

[cert-manager](https://github.com/jetstack/cert-manager) for natively automatically obtaining and renewing LetsEncrypt certificates

* [cert-manager/cert-manager-crds.yaml](cert-manager/cert-manager-crds.yaml)
* [cert-manager/cert-manager-chart.yaml](cert-manager/cert-manager-chart.yaml)
* [cert-manager/cert-sync.yaml](cert-manager/cert-sync.yaml)
* [cert-manager/cert-manager-cloudflare-api-key.yaml](cert-manager/cert-manager-cloudflare-api-key.yaml)
* [cert-manager/cert-manager-letsencrypt.txt](cert-manager/cert-manager-letsencrypt.txt)

# Intel GPU Plugin

Leverage Intel-based iGPU via the [gpu plugin](https://github.com/intel/intel-device-plugins-for-kubernetes/tree/master/cmd/gpu_plugin) DaemonSet for serving-up GPU-based workloads (e.g. Plex) via the `gpu.intel.com/i915` node resource

* [intel-gpu_plugin/intel-gpu_plugin.yaml](intel-gpu_plugin/intel-gpu_plugin.yaml)

# kured

![](https://i.imgur.com/wYWTMGI.png)

Automatically drain and reboot nodes when a reboot is required (e.g. a kernel update was applied): https://github.com/weaveworks/kured

* [kured/kured.yaml](kured/kured.yaml)
* [kured/kured-helm-values.yaml](kured/kured-helm-values.yaml)

# metallb

[Run your own on-prem LoadBalancer](https://metallb.universe.tf/)

* [metallb/metallb.yaml](metallb/metallb.yaml)

# metrics-server

* [metrics-server/metrics-server.yaml](metrics-server/metrics-server.yaml)

# nfs-client-provisioner

Using the [nfs-client storage type](https://github.com/kubernetes-incubator/external-storage/tree/master/nfs-client)

* [nfs-client-provisioner/fs-client-provisioner.yaml](nfs-client-provisioner/nfs-client-provisioner.yaml)

# nfs-pv

nfs-based persistent mounts for various pod access (media mount & data mount)

* [nfs-pv/](nfs-pv/)

# traefik

![](https://i.imgur.com/gwienvX.png)

traefik in HA-mode (multiple replicas) leveraging cert-manager as the central cert store

* [traefik/](traefik/)

# vault

[vault-helm chart](https://github.com/hashicorp/vault-helm)

* [vault/vault.yaml](vault/vault.yaml)

TODO: Implement vault in HA mode

## Setup

After deployment, initialize vault via:

```shell
kubectl -n kube-system port-forward svc/vault 8200:8200 &
export VAULT_ADDR='http://127.0.0.1:8200'
vault operator init -n 1 -t 1
```

Make note of the unseal key and root token and keep in a very safe place

```shell
vault operator unseal <unseal key from above>
vault login <root token from above>
```

# vault-secrets-operator

[vault-secrets-operator](https://github.com/ricoberger/vault-secrets-operator)

* [vault-secrets-operator/vault-secrets-operator.yaml](vault-secrets-operator/vault-secrets-operator.yaml)

## Setup

Follow the [vault-secrets-operator guide](https://github.com/ricoberger/vault-secrets-operator/blob/master/README.md) which is mostly the following:

```shell
# if not logged in to vault already:
kubectl -n kube-system port-forward svc/vault 8200:8200 &
export VAULT_ADDR='http://127.0.0.1:8200'
vault login <root token>

# enable kv secrets type
vault secrets enable -path=secrets -version=1 kv

# create read-only policy for kubernetes
cat <<EOF | vault policy write vault-secrets-operator -
path "secrets/*" {
  capabilities = ["read"]
}
EOF

export VAULT_SECRETS_OPERATOR_NAMESPACE=$(kubectl -n kube-system get sa vault-secrets-operator -o jsonpath="{.metadata.namespace}")
export VAULT_SECRET_NAME=$(kubectl -n kube-system get sa vault-secrets-operator -o jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl -n kube-system get secret $VAULT_SECRET_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl -n kube-system get secret $VAULT_SECRET_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
export K8S_HOST=$(kubectl -n kube-system config view --minify -o jsonpath='{.clusters[0].cluster.server}')

# Verify the environment variables
env | grep -E 'VAULT_SECRETS_OPERATOR_NAMESPACE|VAULT_SECRET_NAME|SA_JWT_TOKEN|SA_CA_CRT|K8S_HOST'

vault auth enable kubernetes

# Tell Vault how to communicate with the Kubernetes cluster
vault write auth/kubernetes/config \
  token_reviewer_jwt="$SA_JWT_TOKEN" \
  kubernetes_host="$K8S_HOST" \
  kubernetes_ca_cert="$SA_CA_CRT"

# Create a role named, 'vault-secrets-operator' to map Kubernetes Service Account to Vault policies and default token TTL
vault write auth/kubernetes/role/vault-secrets-operator \
  bound_service_account_names="vault-secrets-operator" \
  bound_service_account_namespaces="$VAULT_SECRETS_OPERATOR_NAMESPACE" \
  policies=vault-secrets-operator \
  ttl=24h
```
