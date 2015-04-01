#!/usr/bin/env bash

set -ex


# THe script expects the following env variables:
# 1. ADMIN_PASS: Administrator password on the windows cell
# 2. JUMP_MACHINE_IP: The ip of micro bosh (used to forward ssh to the windows cell)
# 3. MACHINE_IP: The windows cell ip
# 4. CONSUL_IPS: The msi config parameter with the same name
# 5. ETCD_CLUSTER: The msi config parameter with the same name
# 6. CF_ETCD_CLUSTER: The msi config parameter with the same name
# 7. DEPLOYMENTS_RUNTIME: The `deployments-runtime` environment directory (e.g. ~/workspace/deployments-runtime/ketchup)

if [ $# -ne 1 ]; then
    echo "Usage: $0 http://path/to/msi"
    exit 1
fi

msi_download_url=$1

ssh-add ${DEPLOYMENTS_RUNTIME}/keypair/id_rsa_bosh

function kill_ssh() {
    pkill -f 'ssh -N -f -L'
}

if [ "x${JUMP_MACHINE_IP}" != "x" ]; then
    # port forward 2223 to windows_cell:22
    ssh -N -f -L 2223:${MACHINE_IP}:22 ec2-user@${JUMP_MACHINE_IP}

    trap kill_ssh EXIT
    ssh_remote="ssh -p 2223 ci@localhost"
else
    ssh_remote="ssh ci@${MACHINE_IP}"
fi

hostname=`${ssh_remote} "hostname" | tr -d '\r'`

# uninstall
${ssh_remote} "msiexec /norestart /passive /x c:\diego.msi" || echo "Diego isn't installed on this machine"

# download the msi
${ssh_remote} "bitsadmin /transfer mydownloadjob /download /priority normal ${msi_download_url} c:\diego.msi"

# install the msi
${ssh_remote} "msiexec /norestart /passive /i c:\diego.msi CONTAINERIZER_USERNAME=.\Administrator CONTAINERIZER_PASSWORD=${ADMIN_PASS} EXTERNAL_IP=${MACHINE_IP} CONSUL_IPS=${CONSUL_IPS} ETCD_CLUSTER=${ETCD_CLUSTER} CF_ETCD_CLUSTER=${CF_ETCD_CLUSTER} LOGGREGATOR_SHARED_SECRET=loggregator-secret MACHINE_NAME=${hostname} STACK=windows2012R2 ZONE=z1"
