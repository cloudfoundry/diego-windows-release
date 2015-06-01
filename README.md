[![Build status](https://ci.appveyor.com/api/projects/status/1tpbencvtf67ljqk/branch/master?svg=true)](https://ci.appveyor.com/project/greenhouse/diego-windows-msi/branch/master)

# diego-windows-msi

This repo contains submodules with all of the source requirements to run a
Windows Cell for Cloud Foundry (Diego). After an install all of the necessary
programs (consul, containerizer, garden-windows, executor, rep) will be running
as services and logging to windows events.


## Dependencies
- Go 1.4 (tested with version go1.4.2 windows/amd64)
- Activated Windows Server 2012 R2 Standard
  - ISO SHA1: B6F063436056510357CB19CB77DB781ED9C11DF3


## Building the MSI

### Additional Build Dependencies
- Visual Studio 2013
- [Visual Studio Installer Projects Extension](https://visualstudiogallery.msdn.microsoft.com/9abe329c-9bba-44a1-be59-0fbf6151054d)

### Producing an MSI

- Run `scripts\make.bat` as an Administrator, the MSI and Windows Circus tgz file will be output into the `output` directory.

## Installing the MSI

After you have built the MSI (as above), or downloaded it from [the github release page](https://github.com/pivotal-cf/diego-windows-msi/releases)

```
msiexec /norestart /i output\DiegoWindowsMSI.msi ^
          ADMIN_USERNAME=[Username with admin privileges] ^
          ADMIN_PASSWORD=[Previous user password] ^
          EXTERNAL_IP=[External IP of box] ^
          CONSUL_IPS=[Comma-separated IP addresses of consul agents from bosh deploy of diego] ^
          ETCD_CLUSTER=[URI of your Diego etcd cluster from bosh deploy] ^
          CF_ETCD_CLUSTER=[URI of your Runtime cf etcd cluster from bosh deploy of cf] ^
          MACHINE_NAME=[This machine's name (must be unique across your cluster)] ^
          STACK=[CF stack, eg. windows2012] ^
          REDUNDANCY_ZONE=[Diego zone this cell is part of] ^
          LOGGREGATOR_SHARED_SECRET=[loggregator secret from your bosh deploy of cf] ^
          SYSLOG_HOST_IP=[(optional) Syslog host IP to send logs to] ^
          SYSLOG_PORT=[(optional) Syslog port to send logs to]
```

An example would be

```
msiexec /norestart /i output\DiegoWindowsMSI.msi ADMIN_USERNAME=Administrator ADMIN_PASSWORD=secretpassword ^
  EXTERNAL_IP=10.10.5.4 CONSUL_IPS=10.10.5.11,10.10.6.11,10.10.7.11 ETCD_CLUSTER=http://10.10.5.10:4001 ^
  CF_ETCD_CLUSTER=http://10.244.0.42:4001 MACHINE_NAME=WIN-RD649GEUDP1 STACK=windows2012 REDUNDANCY_ZONE=0c35dfe1cf34ec47e2a2 ^
  LOGGREGATOR_SHARED_SECRET=loggregator-secret ^
  SYSLOG_HOST_IP=syslog-server.example.com SYSLOG_PORT=514
```

Note: The zone is *not* an AWS zone (e.g. us-east-1) but is instead the same zone listed like

```
diego:
  rep:
    zone: my-zone
```

in your diego deployment manifest.

Note: The ETCD_CLUSTER and CF_ETCD_CLUSTER values **must** be of the form `http://10.10.5.10:4001` and not `10.10.5.10:4001` (i.e. they must be URIs, not IP addresses).

Note: SYSLOG_HOST_IP and SYSLOG_PORT are listed as SYSLOG_DAEMON_HOST and SYSLOG_DAEMON_PORT respectively in the bosh manifest
    

## Deploying Diego to a local BOSH-Lite instance

1. See: https://github.com/cloudfoundry-incubator/diego-release#deploying-diego-to-a-local-bosh-lite-instance with the caveat that you must add the windows2012R2 stack to the deployment manifest, i.e.

        cd ~/workspace/cf-release
        ./generate_deployment_manifest warden \
            ~/deployments/bosh-lite/director.yml \
            ~/workspace/diego-release/templates/enable_diego_docker_in_cc.yml > \
            ~/workspace/diego-release/templates/enable_diego_windows_in_cc.yml > \
            ~/deployments/bosh-lite/cf.yml
        bosh deployment ~/deployments/bosh-lite/cf.yml


## Additional resources

- [Creating a Windows Cell on AWS](https://github.com/pivotal-cf/diego-windows-msi/wiki/Creating-a-cell-on-AWS)
