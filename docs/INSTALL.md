## Installing

This document will go over the steps required to setup a windows cell
in a working cf/diego deployment

## Requirements

- working cf/diego deployment
- windows cell
  - Recommended Windows ISO SHA1: B6F063436056510357CB19CB77DB781ED9C11DF3

**NOTE** AWS specific instructions can be found [here](AWS.md)

## Retrieve the MSI

### Building from source

See [BUILDING.md](BUILDING.md) for further instructions.

### Download a prebuilt MSI

You can download our latest msi from
[here](https://github.com/pivotal-cf/diego-windows-msi/releases/latest)

## Setup the windows cell

TODO: enhance this section

1. Download
[this script](https://raw.githubusercontent.com/cloudfoundry-incubator/diego-windows-msi/master/scripts/setup.ps1)
and run it inside the instance to enable the required Windows features
and configure the DNS settings that the cell will need.
![enable features script](https://github.com/cloudfoundry-incubator/diego-windows-msi/blob/master/README_images/enable_features.png)


## Install the MSI

The following instructions assume that the msi was downloaded to `C:\diego.msi`

```
msiexec /norestart /i c:\diego.msi ^
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

An example would be:

```
msiexec /norestart /i c:\diego.msi ^
          ADMIN_USERNAME=Administrator ^
          ADMIN_PASSWORD=secretpassword ^
          EXTERNAL_IP=10.10.5.4 ^
          CONSUL_IPS=10.10.5.11,10.10.6.11,10.10.7.11 ^
          ETCD_CLUSTER=http://10.10.5.10:4001 ^
          CF_ETCD_CLUSTER=http://10.244.0.42:4001 ^
          MACHINE_NAME=WIN-RD649GEUDP1 ^
          STACK=windows2012 ^
          REDUNDANCY_ZONE=0c35dfe1cf34ec47e2a2 ^
          LOGGREGATOR_SHARED_SECRET=loggregator-secret ^
          SYSLOG_HOST_IP=syslog-server.example.com ^
          SYSLOG_PORT=514
```

### Notes:
- The `REDUNDANCY_ZONE` is *not* an AWS zone (e.g. us-east-1) but is
  instead the same zone listed like
```
diego:
  rep:
    zone: my-zone
```
in your diego deployment manifest.
- `EXTERNAL_IP` is IP of the windows instance
- `CONSUL_IPS` can be retrieved by running `bosh vms` and copying
  the `consul_z1/0` IP address (in our case "10.10.5.11")
- `ETCD_CLUSTER` can be retrieved by running `bosh vms` and
  formatting the `etcd_z1/0` (in the **diego deployment**) IP address as a
  URL with port 4001 (e.g. "http://10.10.5.10:4001")
- `CF_ETCD_CLUSTER` can be retrieved by running `bosh vms` and
  formatting the `etcd_z1/0` (in the **cf deployment**) IP address as a
  URL with port 4001 (e.g. "http://10.244.0.42:4001")
- `MACHINE_NAME` can be retrieved by running `hostname` inside the
  Windows instance (i.e. "WIN-3Q38P0J78DF")
- `LOGGREGATOR_SHARED_SECRET` can be retrieved from the cf deployment manifest
- Note: `SYSLOG_HOST_IP` and `SYSLOG_PORT` are listed as
  `SYSLOG_DAEMON_HOST` and `SYSLOG_DAEMON_PORT` respectively in the
  bosh manifest

## Verify that all the services are up and running

1. If everything has worked correctly, you should now see the
   following five services running in the Task Manager (it's easier to
   sort the services using the `Description` column and look for
   descriptions starting with `CF `):

   | Name          | Description      | Status  |
   |---------------|------------------|---------|
   | Consul        | CF Consul        | Running |
   | Containerizer | CF Containerizer | Running |
   | Executor      | CF Executor      | Running |
   | GardenWindows | CF GardenWindows | Running |
   | Metron        | CF Metron        | Running |
   | Rep           | CF Rep           | Running |
