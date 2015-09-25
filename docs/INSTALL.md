## Installing

This document will go over the steps required to setup a Windows cell in a
working CF/Diego deployment

## Requirements

- working CF/Diego deployment
- Windows Server 2012R2 VM (we recommend r3.xlarge, see https://github.com/cloudfoundry-incubator/diego-release/commit/c9331bc1b1000bd135cb99a025a3680d1a12ac87)
  - Recommended Windows ISO SHA1: B6F063436056510357CB19CB77DB781ED9C11DF3

## Retrieve the MSI

### Building from source

See [BUILDING.md](BUILDING.md) for further instructions.

### Download a prebuilt MSI

You can download our latest Garden MSIs from
[here](https://github.com/pivotal-cf/garden-windows-release/releases/latest)
and the latest DiegoWindows MSIs from
[here](https://github.com/pivotal-cf/diego-windows-release/releases/latest].

## Setup the Windows cell

### CloudFormation

There is a CloudFormation template in the root of the
[garden-windows-release](https://github.com/cloudfoundry-incubator/diego-windows-release/)
repository. This template can be uploaded to [Cloud
Formation](https://console.aws.amazon.com/cloudformation/home) for automatic
setup of a Windows cell.

The Cloud Formation wizard will ask for a number of parameters.

1. SecurityGroup: Security group ID to use for the Windows cells
1. BoshUserName: Username for BOSH director
1. BoshPassword: Pasword for BOSH director (Make sure your password meets [Windows complexity requirements](https://technet.microsoft.com/en-us/library/Cc786468(v=WS.10).aspx))
1. BoshHost: Bosh director host
1. ContainerizerPassword: Pasword for containerizer user e.g. password123!
1. CellName: The name for your cell
1. VPCID: the id of the vpc in which the cell and the subnet will be created
1. NATZ: the instance id of the `NATZ` box
1. SubnetCIDR: the ip range of the Windows cell subnet, e.g. `10.10.100.0/24`

The Cloud Formation template will configure the Windows cell for the
appropriate availability zone based on the provided security group, install the
MSI and register itself with Diego. The Cloud Formation template will only
succeed if all services are up and running after installation. To debug a
failed install, set "Rollback on failure" to "No" under advanced options.

### Manual Setup

1. Download the `setup.ps1` from
our [latest release](https://github.com/pivotal-cf/diego-windows-release/releases/latest).
From inside File explorer right click on the file and click `Run with powershell`.
The script will enable the required Windows features
, configure the DNS settings, and configure the firewall to the way that the cell needs.

## Install the MSIs

The following instructions assume that the MSIs were downloaded to `c:\temp`

```
msiexec /norestart /i c:\temp\GardenWindows.msi ^
          ADMIN_USERNAME=[Username with admin privileges] ^
          ADMIN_PASSWORD=[Previous user password] ^
          SYSLOG_HOST_IP=[(optional) Syslog host IP to send logs to] ^
          SYSLOG_PORT=[(optional) Syslog port to send logs to]

msiexec /norestart /i c:\temp\DiegoWindows.msi ^
          BBS_CA_FILE=[(optional) path to the BBS CA certificate] ^
          BBS_CLIENT_CERT_FILE=[(optional) path to the BBS client certificate] ^
          BBS_CLIENT_KEY_FILE=[(optional) path to the BBS client key] ^
          CONSUL_IPS=[Comma-separated IP addresses of consul agents from BOSH deploy of CF] ^
          CONSUL_ENCRYPT_FILE=[path to the consul encryption key] ^
          CONSUL_CA_FILE=[path to the consul CA certificate] ^
          CONSUL_AGENT_CERT_FILE=[path to the consul agent certificate] ^
          CONSUL_AGENT_KEY_FILE=[path to the consul agent key] ^
          CF_ETCD_CLUSTER=[URI of your Elastic Runtime cf etcd cluster from BOSH deploy of cf] ^
          STACK=[CF stack, eg. windows2012R2] ^
          REDUNDANCY_ZONE=windows ^
          LOGGREGATOR_SHARED_SECRET=[loggregator secret from your BOSH deploy of cf] ^
          EXTERNAL_IP=[(optional) External IP of box] ^
          MACHINE_NAME=[(optional) This machine's name (must be unique across your cluster)] ^
          SYSLOG_HOST_IP=[(optional) Syslog host IP to send logs to] ^
          SYSLOG_PORT=[(optional) Syslog port to send logs to]
```

An example would be:

```
msiexec /norestart /i c:\temp\GardenWindows.msi ^
          ADMIN_USERNAME=Administrator ^
          ADMIN_PASSWORD=secret^%password ^
          SYSLOG_HOST_IP=syslog-server.example.com ^
          SYSLOG_PORT=514

msiexec /norestart /i c:\temp\DiegoWindows.msi ^
          ADMIN_USERNAME=Administrator ^
          ADMIN_PASSWORD=secret^%password ^
          BBS_CA_FILE=c:\temp\bbs_ca.crt ^
          BBS_CLIENT_CERT_FILE=c:\temp\bbs_client.crt ^
          BBS_CLIENT_KEY_FILE=c:\temp\bbs_client.key ^
          CONSUL_IPS=10.10.5.11,10.10.6.11,10.10.7.11 ^
          CONSUL_ENCRYPT_FILE=c:\temp\consul_encrypt.key ^
          CONSUL_CA_FILE=c:\temp\consul_ca.crt ^
          CONSUL_AGENT_CERT_FILE=c:\temp\consul_agent.crt ^
          CONSUL_AGENT_KEY_FILE=c:\temp\consul_agent.key ^
          CF_ETCD_CLUSTER=http://10.244.0.42:4001 ^
          STACK=windows2012R2 ^
          REDUNDANCY_ZONE=windows ^
          LOGGREGATOR_SHARED_SECRET=loggregator-secret ^
          SYSLOG_HOST_IP=syslog-server.example.com ^
          SYSLOG_PORT=514
```

Special characters must be escaped with `^`.

### Changing BOSH properties

Note that if BOSH properties are changed in the BOSH manifest, the MSI must be
reinstalled. For example, setting a syslog host in the deployment manifest will
not update the MSI parameters.

### Notes for ops manager deployments:

If you used ops manager to deploy CF/Diego, follow these steps to find out
the values that you should use in the misexec command:

**CONSUL_IPS**

Go to the OpsManager -> Elastic Runtime tile -> Status -> consul job and copy
the IP address(es).

**CF\_ETCD\_CLUSTER**

Go to the OpsManager -> Elastic Runtime tile -> Status -> etcd job and copy
the IP address. Format the IP address as a URL with port 4001
(e.g. "http://10.10.5.10:4001")

**ZONE / REDUNDANCY_ZONE**

Use the value `windows` for this field (see examples above).

**LOGGREGATOR\_SHARED\_SECRET**
The shared secret listed in your Elastic Runtime deployment / credentials
tab, e.g.:

You should see *Shared Secret Credentials* listed under *Doppler

Server*, you want the second value

eg. If you see `Shared Secret Credentials : abc / 123` then **123** is
the **LOGGREGATOR_SHARED_SECRET**

### Notes for BOSH deployments:
- Both **MACHINE_NAME** and **EXTERNAL_IP** are optional.
**CONSUL_IPS**

Run `bosh vms` and copy the **consul_z1/0** IP address.

**CF\_ETCD\_CLUSTER**

Run `bosh vms` and format the **etcd_z1/0** (in the **cf
deployment**) IP address as a URL with port 4001
(e.g. "http://10.10.5.10:4001")

**ZONE / REDUNDANCY_ZONE**

Use the value `windows` for this field (see examples above).

**LOGGREGATOR\_SHARED\_SECRET**

The shared secret can be found in the cf deployment manifest. e.g.:

```
  loggregator_endpoint:
    shared_secret: loggregator-secret
```

**SYSLOG\_HOST\_IP** and **SYSLOG_PORT**

These are both optional, or you can use any syslog udp endpoint you
would like. If an endpoint was set in Diego, you can find the ip and
port in the manifest as **SYSLOG\_DAEMON\_HOST** and
**SYSLOG\_DAEMON\_PORT** respectively.

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

2. Go to `http://receptor.[DOMAIN]/v1/cells`


You should see the Windows cell(s) listed e.g.:

```json
[
  {
    "cell_id": "cell_z1-0",
    "zone": "z1",
    "capacity": {
      "memory_mb": 30158,
      "disk_mb": 45766,
      "containers": 256
    },
    "rootfs_providers": {
      "docker": [
        
      ],
      "preloaded": [
        "cflinuxfs2"
      ]
    }
  },
  {
    "cell_id": "cell_z2-0",
    "zone": "z2",
    "capacity": {
      "memory_mb": 30158,
      "disk_mb": 45766,
      "containers": 256
    },
    "rootfs_providers": {
      "docker": [
        
      ],
      "preloaded": [
        "cflinuxfs2"
      ]
    }
  },
  {
    "cell_id": "WIN-FCTL342T6B1",
    "zone": "z1",
    "capacity": {
      "memory_mb": 15624,
      "disk_mb": 35487,
      "containers": 100
    },
    "rootfs_providers": {
      "preloaded": [
        "windows2012R2"
      ]
    }
  }
]
