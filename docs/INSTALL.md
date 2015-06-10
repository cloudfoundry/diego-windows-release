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

1. Download the `setup.ps1` from our [latest release](https://github.com/pivotal-cf/diego-windows-msi/releases/latest). From inside File explorer right click on the file and click `Run with powershell`. The script will enable the required Windows features
and configure the DNS settings that the cell will need.

## Install the MSI

The following instructions assume that the msi was downloaded to `C:\diego.msi`

```
msiexec /norestart /i c:\diego.msi ^
          ADMIN_USERNAME=[Username with admin privileges] ^
          ADMIN_PASSWORD=[Previous user password] ^
          CONSUL_IPS=[Comma-separated IP addresses of consul agents from bosh deploy of CF] ^
          ETCD_CLUSTER=[URI of your Diego etcd cluster from bosh deploy] ^
          CF_ETCD_CLUSTER=[URI of your Runtime cf etcd cluster from bosh deploy of cf] ^
          STACK=[CF stack, eg. windows2012R2] ^
          REDUNDANCY_ZONE=[Diego zone this cell is part of] ^
          LOGGREGATOR_SHARED_SECRET=[loggregator secret from your bosh deploy of cf] ^
          EXTERNAL_IP=[(optional) External IP of box] ^
          MACHINE_NAME=[(optional) This machine's name (must be unique across your cluster)] ^
          SYSLOG_HOST_IP=[(optional) Syslog host IP to send logs to] ^
          SYSLOG_PORT=[(optional) Syslog port to send logs to]
```

An example would be:

```
msiexec /norestart /i c:\diego.msi ^
          ADMIN_USERNAME=Administrator ^
          ADMIN_PASSWORD=secretpassword ^
          CONSUL_IPS=10.10.5.11,10.10.6.11,10.10.7.11 ^
          ETCD_CLUSTER=http://10.10.5.10:4001 ^
          CF_ETCD_CLUSTER=http://10.244.0.42:4001 ^
          STACK=windows2012R2 ^
          REDUNDANCY_ZONE=0c35dfe1cf34ec47e2a2 ^
          LOGGREGATOR_SHARED_SECRET=loggregator-secret ^
          SYSLOG_HOST_IP=syslog-server.example.com ^
          SYSLOG_PORT=514
```

### Notes for ops manager deployments:

If you used ops manager to deploy CF/Diego, follow these steps to find out
the values that you should use in the misexec command:

**CONSUL_IPS**

Go to the OpsManager -> Runtime tile -> Status -> consul job and copy
the IP address(es).

**ETCD_CLUSTER**

Go to the OpsManager -> Diego tile -> Status -> etcd job and copy the
IP address(es). Format the IP address as a URL with port 4001
(e.g. "http://10.10.5.10:4001"). Use this command to ensure you can
connect to the etcd server from Ops Manager:

```
curl http://<etcd-server-ip>:4001/v2/keys/message -XPUT -d value="Hello diego"
```

**CF_ETCD_CLUSTER**

Go to the OpsManager -> Runtime tile -> Status -> etcd job and copy
the IP address. Format the IP address as a URL with port 4001
(e.g. "http://10.10.5.10:4001")

**ZONE / REDUNDANCY_ZONE**

For AWS users, You can get the zone from the EC2 instances list,
instance name, after the dash. The EC2 instance name with
nats-partition-abcde12345fedcb54321/0 would have a zone of
abcde12345fedcb54321. **NOTE** this is not the AWS zone.

You can also navigate to OpsManager -> Diego for PCF -> Credentials
and then find the username and password for *Receptor Credentials* and
then:

Go to `http://receptor.[DOMAIN]/v1/cells`

You should see `zone` listed inside each existing cell, e.g.:

```json
[{"cell_id":"cell-partition-0880c1d1dca06bbf67e1-0","zone":"0880c1d1dca06bbf67e1","capacity":{"memory_mb":30679,"disk_mb":15993,"containers":256}}]
```

**LOGGREGATOR_SHARED_SECRET**
The shared secret listed in your CF Runtime deployment / credentials
tab, e.g.:

You should see *Shared Secret Credentials* listed under *Doppler
Server*, you want the second value

eg. If you see `Shared Secret Credentials : abc / 123` then **123** is
the **LOGGREGATOR_SHARED_SECRET**

### Notes for bosh deployments:
- Both **MACHINE_NAME** and **EXTERNAL_IP** are optional.
**CONSUL_IPS**

Run `bosh vms` and copy the **consul_z1/0** IP address.

**ETCD_CLUSTER**

Run `bosh vms` and format the **etcd_z1/0** (in the **diego
deployment**) IP address as a URL with port 4001
(e.g. "http://10.10.5.10:4001")

**CF_ETCD_CLUSTER**

Run `bosh vms` and format the **etcd_z1/0** (in the **cf
deployment**) IP address as a URL with port 4001
(e.g. "http://10.10.5.10:4001")

**ZONE / REDUNDANCY_ZONE**

This is **not** an AWS zone (e.g. us-east-1) but is instead the same
zone listed like

```
diego:
  rep:
    zone: my-zone
```
in your diego deployment manifest.

**LOGGREGATOR_SHARED_SECRET**

The shared secret can be found in the cf deployment manifest. e.g.:

```
  loggregator_endpoint:
    shared_secret: loggregator-secret
```

**SYSLOG_HOST_IP** and **SYSLOG_PORT**

These are both optional, or you can use any syslog udp endpoint you
would like. If an endpoint was set in diego, you can find the ip and
port in the manifest as **SYSLOG_DAEMON_HOST** and
**SYSLOG_DAEMON_PORT** respectively.

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
