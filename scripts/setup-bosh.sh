#!/usr/bin/env bash

set -ex
bosh_lite_cmd="bosh -u admin -p admin -t https://192.168.50.4:25555"
bosh_aws_cmd="bosh"

dir=$(dirname $0)
cd "$dir"
workspace=$PWD/../..
deployments=$workspace/../deployments

# ENV variable to setup parallel create and upload release
PARALLEL=${PARALLEL:-"yes"}

# ENV variables used to setup syslog
# PAPERTRAIL_ENDPOINT=            # logs.papaertrail.com:5550
export PAPERTRAIL_ADDR=$(echo $PAPERTRAIL_ENDPOINT | cut -d: -f1)
export PAPERTRAIL_PORT=$(echo $PAPERTRAIL_ENDPOINT | cut -d: -f2)

# ENV variables used to setup bosh lite
# RECREATE_VAGRANT=               # yes to recreate the virtual bos vm
# BOSH_LITE=                      # yes to deploy to bosh lite

# ENV variables used to setup aws env
# AWS_ENVIRONMENT=                # environment name, e.g. ferret

if [ "x$RECREATE_VAGRANT" == "xyes" ]; then

    cd $workspace/bosh-lite
    vagrant destroy -f
    vagrant up --provider=virtualbox # --provider=vmware_fusion
fi

if [ "x$BOSH_LITE" == "xyes" ]; then
    bosh_cmd=$bosh_lite_cmd
    bosh_upload_release_cmd="$bosh_cmd -n upload release"

    CF_MANIFEST=$deployments/bosh-lite/cf.yml
    DIEGO_MANIFEST=$deployments/bosh-lite/diego.yml

    stemcell=bosh-warden-boshlite-ubuntu-trusty-go_agent
    if [ ! -e $stemcell ]; then
      `wget --show-progress -qcO /tmp/$stemcell https://bosh.io/d/stemcells/$stemcell`
    fi
    $bosh_cmd upload stemcell /tmp/$stemcell --skip-if-exists || echo 0

    cd "$workspace/diego-release"
    uuid=`$bosh_cmd status --uuid`
    echo "director_uuid: ${uuid}" > $deployments/bosh-lite/director.yml

    cd "$workspace/cf-release"
    ./scripts/generate_deployment_manifest warden \
                                   $deployments/bosh-lite/director.yml \
                                   $workspace/diego-release/stubs-for-cf-release/enable_consul_with_cf.yml \
                                   $workspace/diego-release/stubs-for-cf-release/enable_diego_windows_in_cc.yml \
                                   $workspace/diego-release/stubs-for-cf-release/enable_diego_ssh_in_c*.yml \
                                   > $CF_MANIFEST

    cd $workspace/diego-release
    ./scripts/generate-deployment-manifest \
        manifest-generation/bosh-lite-stubs/property-overrides.yml \
        manifest-generation/bosh-lite-stubs/instance-count-overrides.yml \
        manifest-generation/bosh-lite-stubs/persistent-disk-overrides.yml \
        manifest-generation/bosh-lite-stubs/iaas-settings.yml \
        manifest-generation/bosh-lite-stubs/additional-jobs.yml \
        $deployments/bosh-lite \
        > $DIEGO_MANIFEST
elif [ "x$AWS_ENVIRONMENT" != "x" ]; then
    bosh_cmd=$bosh_aws_cmd
    bosh_upload_release_cmd="$bosh_cmd -n upload release --rebase"

    cd "$workspace/greenhouse-private/${AWS_ENVIRONMENT}"
    ./generate-cf-diego-manifests.sh
    CF_MANIFEST=/tmp/cf.yml
    DIEGO_MANIFEST=/tmp/diego.yml
else
    echo "either $AWS_ENVIRONMENT or BOSH_LITE=yes must be provided"
    exit 1
fi

function retry {
    for _ in {1..3}; do
        if "$@"; then
            return 0
        fi
        echo "Retrying " "$@"
    done
    return 1
}

function sync_blobs {
    retry $bosh_cmd --parallel 10 sync blobs
}

function create_release {
    retry $bosh_cmd --parallel 10 -n create release --force
}

function build_and_upload_cf {
    cd $workspace/cf-release &&
        sync_blobs &&
        create_release &&
        $bosh_upload_release_cmd
}

function build_and_upload_garden_linux {
    cd $workspace/garden-linux-release &&
        sync_blobs &&
        create_release &&
        $bosh_upload_release_cmd
}

function build_and_upload_diego {
    cd $workspace/diego-release &&
        sync_blobs &&
        create_release &&
        $bosh_upload_release_cmd
}

function upload_etcd_release {
  wget --show-progress -qcO /tmp/etcd-release https://bosh.io/d/github.com/cloudfoundry-incubator/etcd-release
  $bosh_cmd upload release /tmp/etcd-release
}


function fix_deployment_manifest {
    # Disable canaries in the deployment manifest and deploy in
    # parallel (instead of serial) This should make the cf deployment
    # way faster than it used to be
    ruby -ryaml <<EOF
y = YAML.load_file("$1")
y["jobs"].select {|x| x["name"] =~ /etcd_z/}.each {|x| x["update"]["serial"] = true }
y["update"]["canaries"] = 0
y["update"]["serial"] = false
y["update"]["max_in_flight"] = 50
y["properties"]["syslog_daemon_config"] = {
  "address" => ENV["PAPERTRAIL_ADDR"],
  "port"    => ENV["PAPERTRAIL_PORT"]
}
File.open("$1", File::RDWR|File::TRUNC) {|f| f.write y.to_yaml}
EOF
}

fix_deployment_manifest $CF_MANIFEST
fix_deployment_manifest $DIEGO_MANIFEST

# This could fail if the release was already uploaded, this should be
# fixed in the latest directory
# https://github.com/cloudfoundry/bosh/commit/104869c8b1f4cd58bd87e50c8557e38edee91f10
if [ "x$PARALLEL" == "xyes" ]; then
    build_and_upload_diego &
    build_and_upload_cf &
    build_and_upload_garden_linux &
    upload_etcd_release &
    wait
else
    build_and_upload_diego
    build_and_upload_cf
    build_and_upload_garden_linux
    upload_etcd_release
fi

retry $bosh_cmd -n -d $CF_MANIFEST deploy &&
    retry $bosh_cmd -n -d $DIEGO_MANIFEST deploy

if [ "x$BOSH_LITE" = "xyes" ]; then
    $workspace/bosh-lite/bin/add-route
    cf api --skip-ssl-validation https://api.bosh-lite.com
    cf login -u admin -p admin
    if [ "x$RECREATE_VAGRANT" = "xyes" ]; then
        cf create-org org &&
            cf create-space -o org space &&
            cf target -o org -s space
    fi
fi
