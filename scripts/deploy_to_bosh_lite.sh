#!/usr/bin/env bash

cd `dirname $0`

#JUMP_MACHINE_IP

: ${1:?"Must provide the msi name, e.g.: DiegoWindowsMSI-0.0.314-6c4e74e.msi"}


export ADMIN_PASS=joE3Jj5Fex!
export REDUNDANCY_ZONE=z1
export MACHINE_IP=172.16.234.139
export CONSUL_IPS=10.244.0.54
export ETCD_CLUSTER=http://10.244.16.2:4001
export CF_ETCD_CLUSTER=http://10.244.0.42:4001
export LOGGREGATOR_SHARED_SECRET=loggregator-secret
export JUMP_MACHINE_SSH_KEY=`cat ~/workspace/deployments-runtime/ketchup/keypair/id_rsa_bosh`
export SYSLOG_HOST_IP=logs2.papertrailapp.com
export SYSLOG_PORT=59978

echo "Installing version: ${1}"

echo "https://s3.amazonaws.com/diego-windows-msi/output/$1" > /tmp/url

./run_ruby.sh ./deploy_msi.rb /tmp
