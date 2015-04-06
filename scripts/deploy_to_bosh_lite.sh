#!/usr/bin/env bash

cd `dirname $0`

if [ "x$ADMIN_PASS" == "x" ]; then
    echo "Please set ADMIN_PASS env variable"
    exit 1
fi

#JUMP_MACHINE_IP
export ADMIN_PASS
export MACHINE_IP=172.16.234.139
export CONSUL_IPS=10.244.0.54
export ETCD_CLUSTER=http://10.244.16.2:4001
export CF_ETCD_CLUSTER=http://10.244.0.42:4001
export DEPLOYMENTS_RUNTIME=~/workspace/deployments-runtime/ketchup

./deploy_msi.sh "$@"
