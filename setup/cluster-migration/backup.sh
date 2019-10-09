#!/bin/bash

# the purpose of this script is to backup source persistent volumes housed in external ceph rbd and restore them in a rook-provisioned cephfs storage solution holding the corresponding persistent volume

# PREREQUISITES & ASSUMPTIONS:
#   1. rook toolbox must be present and the 'shared filesystem tools' must be mounted to /tmp/registry (see https://rook.io/docs/rook/v1.1/direct-tools.html)
#   2. this script needs to be executed as sudo due to permission issues with some of the files being handled
#   3. (reccomended) key-based ssh-access without interactive password
#   4. (HIGHLY RECCOMENDED) source and destination workloads are scaled-to-zero prior to running this

PVCS_TO_BACKUP="home-assistant mc-minecraft-datadir mcsv-minecraft-datadir node-red kube-plex-config radarr-config rtorrent-flood-config sonarr-config unifi influxdb"
PVCS_TO_RESTORE="home-assistant mc-minecraft-datadir mcsv-minecraft-datadir kube-plex-config radarr-config rtorrent-flood-config sonarr-config unifi"
PVCS_TO_RESTORE_NFS="node-red influxdb"

ssh root@proxmox mkdir -p /tmp/rbd
# backup the stuff
export KUBECONFIG=/home/jeff/.kube/config
for pvc in $PVCS_TO_BACKUP
do
  PV=$(kubectl get pv | grep "$pvc" | awk '{print $1}')
  RBDIMAGE=$(kubectl describe pv "$PV" | grep RBDImage | awk '{print $2}')
  echo "Backing up $pvc ($RBDIMAGE) to proxmox:/tank/backups/cluster/$pvc"
  ssh root@proxmox "rm -rf /tank/backups/cluster/$pvc && rbd map kube/$RBDIMAGE && mount /dev/rbd0 /tmp/rbd && cp -a /tmp/rbd /tank/backups/cluster/$pvc; umount /tmp/rbd && rbd unmap /dev/rbd0"
done

# restore the stuff to cephfs
export KUBECONFIG=/home/jeff/src/k3s-gitops/setup/kubeconfig
for pvc in $PVCS_TO_RESTORE
do
  PV=$(kubectl get pv --all-namespaces | grep "$pvc" | awk '{print $1}')
  CEPHFS_THING=$(kubectl describe pv "$PV" | grep VolumeHandle | awk '{print $2}' | sed 's/[0-9]*-[0-9]*-rook-ceph-[0-9]*-\(.*\)/\1/g')
  TOOLBOX_PATH="/tmp/registry/volumes/csi/csi-vol-$CEPHFS_THING"
  echo "===== Restoring $pvc ($CEPHFS_THING) from proxmox:/tank/backups/cluster/$pvc"
  tools="$(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}')"
  echo "     ----- deleting contents of $TOOLBOX_PATH in the toolbox pod"
  kubectl -n rook-ceph exec -it "$tools" -- sh -c "rm -rf $TOOLBOX_PATH/{*,.*} 2> /dev/null"
  echo "     ----- copying /mnt/backups/cluster/$pvc to $tools:/tmp/"
  kubectl -n rook-ceph cp /mnt/backups/cluster/"$pvc" "$tools":/tmp/
  echo "     ----- moving /tmp/$pvc to $TOOLBOX_PATH/"
  kubectl -n rook-ceph exec -it "$tools" -- sh -c "mv /tmp/$pvc/{*,.*} $TOOLBOX_PATH/ 2> /dev/null"
  kubectl -n rook-ceph exec -it "$tools" -- sh -c "rmdir /tmp/$pvc"
done

# restore the stuff to nfs-client
for pvc in $PVCS_TO_RESTORE_NFS
do
  PV=$(kubectl get pv --all-namespaces | grep "$pvc" | awk '{print $1}')
  NFS_PATH=$(kubectl get pv "$PV" -o=jsonpath='{.spec.nfs.path}')
  echo "===== Restoring $pvc ($NFS_PATH) from proxmox:/tank/backups/cluster/$pvc"
  ssh root@proxmox "rm -rf $NFS_PATH/* ; rm -rf $NFS_PATH/.* ; cp -a /tank/backups/cluster/$pvc/* $NFS_PATH/ ; cp -a /tank/backups/cluster/$pvc/.* $NFS_PATH/"
done