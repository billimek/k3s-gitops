(for context see https://github.com/billimek/k8s-gitops/issues/54)

## pre-flight

1. configure k3s-gitops repo to use 'real' domain name and 'real' metalLB loadbalancer IPs
1. bootstrap new k3s cluster - see [bootstrap-cluster.sh](../bootstrap-cluster.sh)

## cutover

### on rke cluster

1. shut-down (scale to 0) workloads that need to be backed-up - see [scale.sh](scale.sh)
1. backup all necessary workloads - see [backup.sh](backup.sh)
1. drain k8s-4 (odroid-h2 node where the google coral usb device is installed)
1. remove k8s-4 from rke k8s cluster
1. 'shut down' cluster nodes

### on new k3s cluster

1. shut-down (scale to 0) workloads that need to be restored - see [scale.sh](scale.sh)
1. 'add' k8s-4 node to k3s cluster
1. restore-from-backup necessary workloads - see [backup.sh](backup.sh)
1. scale-up workloads from step 1
1. sync with flux

## postflight

1. mass-update k8s-gitops repo to reflect new cluster
1. update/redeploy flux to use the k8s-gitops repo instead of the k3s-gitops repo
