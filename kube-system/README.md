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

# sealed-secrets

[Handle encryption of secrets for GitOps workflows](https://github.com/bitnami-labs/sealed-secrets)

* [sealed-secrets/sealed-secrets.yaml](sealed-secrets/sealed-secrets.yaml)

# traefik

![](https://i.imgur.com/gwienvX.png)

traefik in HA-mode (multiple replicas) leveraging cert-manager as the central cert store

* [traefik/](traefik/)
