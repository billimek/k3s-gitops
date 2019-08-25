# cert-manager

[cert-manager](https://github.com/jetstack/cert-manager) for natively automatically obtaining and renewing LetsEncrypt certificates

* [cert-manager.yaml](cert-manager.yaml)
* [cert-manager-chart.yaml](cert-manager-chart.yaml)
* [cert-sync.yaml](cert-sync.yaml)
* [cert-manager-letsencrypt.txt](../setup/manual-steps/yamls/cert-manager-letsencrypt.txt)

# traefik

![](https://i.imgur.com/gwienvX.png)

traefik in HA-mode (multiple replicas) leveraging cert-manager as the central cert store

* [traefik.yaml](traefik.yaml)

# fluxcloud

![](https://i.imgur.com/yixxNm9.png)

Send messages to slack for flux events

* [fluxcloud.yaml](fluxcloud.yaml)

# Intel GPU Plugin

Leverage Intel-based iGPU via the [gpu plugin](https://github.com/intel/intel-device-plugins-for-kubernetes/tree/master/cmd/gpu_plugin) DaemonSet for serving-up GPU-based workloads (e.g. Plex) via the `gpu.intel.com/i915` node resource

* [intel-gpu_plugin.yaml](intel-gpu_plugin.yaml)

# kured

![](https://i.imgur.com/wYWTMGI.png)

Automatically drain and reboot nodes when a reboot is required (e.g. a kernel update was applied): https://github.com/weaveworks/kured

* [kured.yaml](kured.yaml)

# metallb

[Run your own on-prem LoadBalancer](https://metallb.universe.tf/)

* [metallb.yaml](metallb.yaml)

# sealed-secrets

[Handle encryption of secrets for GitOps workflows](https://github.com/bitnami-labs/sealed-secrets)

* [sealed-secrets.yaml](sealed-secrets.yaml)
