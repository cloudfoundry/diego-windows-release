#!/usr/bin/env bash

set -ex

stemcell=bosh-stemcell-389-warden-boshlite-ubuntu-trusty-go_agent.tgz

if [ "x$RECREATE_VAGRANT" = "xyes" ]; then
    cd ~/workspace/bosh-lite
    vagrant destroy -f
    vagrant up --provider=virtualbox # --provider=vmware_fusion
    if [ ! -e $stemcell ]; then
        bosh download public stemcell $stemcell
    fi
    bosh upload stemcell $stemcell
fi

gem uninstall -a -x -q -I
gem install bosh_cli

cd ~/workspace/diego-release
./scripts/print-director-stub > ~/deployments/bosh-lite/director.yml

cd ~/workspace/cf-release
./generate_deployment_manifest warden \
    ~/deployments/bosh-lite/director.yml \
    ~/workspace/diego-release/stubs-for-cf-release/enable_consul_with_cf.yml \
    ~/workspace/diego-release/stubs-for-cf-release/enable_diego_windows_in_cc.yml \
    ~/workspace/diego-release/stubs-for-cf-release/enable_diego_ssh_in_cc.yml \
    > ~/deployments/bosh-lite/cf.yml

cd ~/workspace/diego-release
./scripts/generate-deployment-manifest \
    ~/deployments/bosh-lite/director.yml \
    manifest-generation/bosh-lite-stubs/property-overrides.yml \
    manifest-generation/bosh-lite-stubs/instance-count-overrides.yml \
    manifest-generation/bosh-lite-stubs/persistent-disk-overrides.yml \
    manifest-generation/bosh-lite-stubs/iaas-settings.yml \
    manifest-generation/bosh-lite-stubs/additional-jobs.yml \
    ~/deployments/bosh-lite \
    > ~/deployments/bosh-lite/diego.yml

function retry {
    for i in {1..3}; do
        if "$@"; then
            return 0
        fi
        echo "Retrying " "$@"
    done
    return 1
}

function sync_blobs {
    retry bosh --parallel 10 sync blobs
}

function create_release {
    retry bosh --parallel 10 -n create release --force
}

function build_and_upload_cf {
    cd ~/workspace/cf-release && \
        sync_blobs && \
        create_release && \
        bosh -n upload release --rebase
}

function build_and_upload_diego {
    cd ~/workspace/diego-release && \
        sync_blobs && \
        create_release && \
        bosh -n upload release --rebase
}


build_and_upload_diego &
diego_pid=$!
build_and_upload_cf &
cf_pid=$!

wait $diego_pid $cf_pid

function fix_deployment_manifest {
    # Disable canaries in the deployment manifest and deploy in
    # parallel (instead of serial) This should make the cf deployment
    # way faster than it used to be
    ruby -ryaml <<EOF
y = YAML.load_file("$1")
y["update"]["canaries"] = 0
y["update"]["serial"] = false
y["update"]["max_in_flight"] = 50
File.open("$1", File::RDWR|File::TRUNC) {|f| f.write y.to_yaml}
EOF
}

fix_deployment_manifest ~/deployments/bosh-lite/cf.yml
fix_deployment_manifest ~/deployments/bosh-lite/diego.yml

retry bosh -n -d ~/deployments/bosh-lite/cf.yml deploy &&
    retry bosh -n -d ~/deployments/bosh-lite/diego.yml deploy

~/workspace/bosh-lite/bin/add-route
cf api --skip-ssl-validation https://api.10.244.0.34.xip.io
cf login -u admin -p admin
if [ "x$RECREATE_VAGRANT" = "xyes" ]; then
    cf create-org org
    cf create-space -o org space
    cf target -o org -s space
fi
