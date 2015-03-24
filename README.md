# diego-windows-msi

This repo contains submodules with all of the source requirements to run a
Windows Cell for Cloud Foundry (Diego). After an install all of the necessary
programs (consul, containerizer, garden-windows, executor, rep) will be running
as services and logging to windows events.


## Dependencies
- Go 1.4 (tested with version go1.4.2 windows/amd64)
- 64 bit version of Windows (tested with Windows Server 2012 R2 Standard)

## Building the MSI

### Additional Build Dependencies
- Visual Studio 2013
- [Visual Studio Installer Projects Extension](https://visualstudiogallery.msdn.microsoft.com/9abe329c-9bba-44a1-be59-0fbf6151054d)

### Producing an MSI

- Run `make.bat` as an Administrator, the MSI and Windows Circus tgz file will be output into the `output` directory.

## Installing the MSI

After you have built the MSI:

```
msiexec /norestart /i output\DiegoWindowsMSI.msi \
          CONTAINERIZER_USERNAME=[Username with admin privileges] \
          CONTAINERIZER_PASSWORD=[Previous user password] \
          EXTERNAL_IP=[External IP of box] \
          CONSUL_IPS=[Comma-separated IP addresses of consul agents from bosh deploy of diego]
          ETCD_CLUSTER=[IP address of your etcd cluster from bosh deploy of diego]
          MACHINE_NAME=[This machine's name (must be unique across your cluster)]
          STACK=[CF stack, eg. windows2012]
          ZONE=[Bosh zone this cell is part of]
```

An example would be

```
msiexec /norestart /i output\DiegoWindowsMSI.msi CONTAINERIZER_USERNAME=.\Administrator CONTAINERIZER_PASSWORD=secretpassword \
  EXTERNAL_IP=10.10.5.4 CONSUL_IPS=10.10.5.11,10.10.6.11,10.10.7.11 ETCD_CLUSTER=http://10.10.5.10:4001 \
  MACHINE_NAME=WIN-RD649GEUDP1 STACK=windows2012 ZONE=z1
```

## Deploying Diego to a local BOSH-Lite instance

1. Install and start [BOSH-Lite](https://github.com/cloudfoundry/bosh-lite),
   following its
   [README](https://github.com/cloudfoundry/bosh-lite/blob/master/README.md).

1. Download the latest Warden Trusty Go-Agent stemcell and upload it to BOSH-lite

        bosh public stemcells
        bosh download public stemcell (name)
        bosh upload stemcell (downloaded filename)

1. Checkout cf-release (develop branch) from git

        cd ~/workspace
        git clone git@github.com:cloudfoundry/cf-release.git
        cd ~/workspace/cf-release
        git checkout develop
        ./update

1. Checkout diego-release (develop branch) from git

        cd ~/workspace
        git clone git@github.com:cloudfoundry-incubator/diego-release.git
        cd ~/workspace/diego-release
        git checkout develop
        ./scripts/update

1. Install spiff, a tool for generating BOSH manifests. spiff is required for
   running the scripts in later steps. The following installation method
   assumes that go is installed. For other ways of installing `spiff`, see
   [the spiff README](https://github.com/cloudfoundry-incubator/spiff).

        go get github.com/cloudfoundry-incubator/spiff

1. Generate a deployment stub with the BOSH director UUID

        mkdir -p ~/deployments/bosh-lite
        cd ~/workspace/diego-release
        ./scripts/print-director-stub > ~/deployments/bosh-lite/director.yml

1. Generate and target cf-release manifest:

        cd ~/workspace/cf-release
        ./generate_deployment_manifest warden \
            ~/deployments/bosh-lite/director.yml \
            ~/workspace/diego-release/templates/enable_diego_docker_in_cc.yml > \
            ~/workspace/diego-release/templates/enable_diego_windows_in_cc.yml > \
            ~/deployments/bosh-lite/cf.yml
        bosh deployment ~/deployments/bosh-lite/cf.yml

1. Do the BOSH dance:

        cd ~/workspace/cf-release
        bosh create release --force
        bosh -n upload release
        bosh -n deploy

1. Generate and target diego's manifest:

        cd ~/workspace/diego-release
        ./scripts/generate-deployment-manifest bosh-lite ../cf-release \
            ~/deployments/bosh-lite/director.yml > \
            ~/deployments/bosh-lite/diego.yml
        bosh deployment ~/deployments/bosh-lite/diego.yml

1. Dance some more:

        bosh create release --force
        bosh -n upload release
        bosh -n deploy

Now you can either run the DATs or deploy your own app.

---
###<a name="smokes-and-dats"></a> Running Smoke Tests & DATs

To deploy and run the smoke tests:

1. Create a test Organization and Space for your smoke test applications:

        cf api --skip-ssl-validation api.10.244.0.34.xip.io
        cf auth admin admin
        cf create-org smoke-tests
        cf create-space smoke-tests -o smoke-tests

1. Create a deployment manifest for the smoke test task (known as a BOSH errand).

        spiff merge ~/workspace/diego-release/templates/smoke-tests-bosh-lite.yml \
            ~/deployments/bosh-lite/director.yml \
            > ~/deployments/bosh-lite/diego-smoke-tests.yml

1. Deploy the task and run it.

        bosh -d ~/deployments/bosh-lite/diego-smoke-tests.yml deploy
        bosh -d ~/deployments/bosh-lite/diego-smoke-tests.yml run errand diego_smoke_tests

To deploy and run the DATs:

1. Create a deployment manifest for the DATs errand (you do not need to create an Org or Space for this):

        spiff merge ~/workspace/diego-release/templates/acceptance-tests-bosh-lite.yml \
            ~/deployments/bosh-lite/director.yml \
            > ~/deployments/bosh-lite/diego-acceptance-tests.yml
        bosh -d ~/deployments/bosh-lite/diego-acceptance-tests.yml deploy
        bosh -d ~/deployments/bosh-lite/diego-acceptance-tests.yml run errand diego_acceptance_tests
