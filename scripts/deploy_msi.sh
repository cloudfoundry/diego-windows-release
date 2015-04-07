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

# TODO: make sure all required env. variables are set

msi_download_url=$1
private_key=${DEPLOYMENTS_RUNTIME}/keypair/id_rsa_bosh
# The following line expect the url to have the sha (e.g. https://s3/path/DiegoWindowsMSI-faf01f9.msi)
expected_sha=`basename ${msi_download_url} | cut -d- -f2 | cut -d. -f1`
ssh_opts="-i ${private_key} -o StrictHostKeyChecking=no"
local_port=2223
msi_location="c:\diego.msi"
# wget equivalent on windows
wget="powershell /C wget"
msi_install="msiexec /norestart /passive /i"
msi_uninstall="msiexec /norestart /passive /x"

function kill_ssh() {
    pkill -f 'ssh -N -f -L'
}

# make sure the key has the right mod so ssh doesn't complain
chmod 600 ${private_key}

if [ "x${JUMP_MACHINE_IP}" != "x" ]; then
    # port forward local_port to windows_cell:22
    ssh -N -f -L ${local_port}:${MACHINE_IP}:22 ${ssh_opts} ec2-user@${JUMP_MACHINE_IP}

    trap kill_ssh EXIT
    ssh_remote="ssh ${ssh_opts} -p ${local_port} ci@localhost"
else
    ssh_remote="ssh ${ssh_opts} ci@${MACHINE_IP}"
fi

# get the hostname from the remote machine, used as the MACHINE_NAME
# when configuring DiegoWindowsMSI
hostname=`${ssh_remote} "hostname" | tr -d '\r'`

# uninstall
${ssh_remote} "${msi_uninstall} ${msi_location}" || echo "Diego isn't installed on this machine"

# download the msi
${ssh_remote} "${wget} ${msi_download_url} -OutFile ${msi_location}"

# install the msi
${ssh_remote} "${msi_install} ${msi_location} CONTAINERIZER_USERNAME=.\Administrator CONTAINERIZER_PASSWORD=${ADMIN_PASS} EXTERNAL_IP=${MACHINE_IP} CONSUL_IPS=${CONSUL_IPS} ETCD_CLUSTER=${ETCD_CLUSTER} CF_ETCD_CLUSTER=${CF_ETCD_CLUSTER} LOGGREGATOR_SHARED_SECRET=loggregator-secret MACHINE_NAME=${hostname} STACK=windows2012R2 ZONE=z1"

actual_sha=`${ssh_remote} 'cmd /C type "C:\Program Files\CloudFoundry\DiegoWindows\RELEASE_SHA"' | awk '{print $2}'`
if [ ${actual_sha} != ${expected_sha} ]; then
    echo "Installation failed: expected ${actual_sha} == ${expected_sha}"
    exit 1
fi
echo "Installation succeeded"
