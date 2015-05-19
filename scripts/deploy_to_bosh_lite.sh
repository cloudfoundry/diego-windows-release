#!/usr/bin/env bash

cd `dirname $0`

#JUMP_MACHINE_IP

tag=`git tag --sort="v:refname" | grep -v v0.400 | tail -n1`
commit=`git show -s --oneline ${tag} | awk '{print $1}'`
export GO_REVISION_DIEGO_WINDOWS_MSI=${commit}
export ADMIN_PASS=joE3Jj5Fex!
export REDUNDANCY_ZONE=z1
export MACHINE_IP=172.16.234.139
export CONSUL_IPS=10.244.0.54
export ETCD_CLUSTER=http://10.244.16.2:4001
export CF_ETCD_CLUSTER=http://10.244.0.42:4001
export DEPLOYMENTS_RUNTIME=~/workspace/deployments-runtime/ketchup
export LOGGREGATOR_SHARED_SECRET=loggregator-secret

echo "Installing version: ${tag}:${commit}"

./run_ruby.sh ./deploy_msi.rb "$@"
