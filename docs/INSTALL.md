## Installing

This document will go over the steps required to setup a Windows cell in a
working CF/Diego deployment

## Requirements

- A working CF/Diego deployment with [the Windows stack added](https://github.com/cloudfoundry-incubator/diego-release/blob/9daae2c5ecff2ee8a9f67e3858e5d797815326ff/stubs-for-cf-release/enable_diego_windows_in_cc.yml)
- Windows Server 2012R2 VM (on AWS, we recommend r3.xlarge, per https://github.com/cloudfoundry-incubator/diego-release/commit/c9331bc1b1000bd135cb99a025a3680d1a12ac87)
  - Recommended Windows ISO SHA1: B6F063436056510357CB19CB77DB781ED9C11DF3

## Retrieve the MSI

### Building from source

See [BUILDING.md](BUILDING.md) for further instructions.

### Download a prebuilt MSI

You can download our latest Garden MSIs from
[here](https://github.com/cloudfoundry-incubator/garden-windows-release/releases/latest)
and the latest DiegoWindows MSIs from
[here](https://github.com/cloudfoundry-incubator/diego-windows-release/releases/latest).

## Setup the Windows cell

### CloudFormation deployment on AWS

There is a CloudFormation template in the root of the
[garden-windows-release](https://github.com/cloudfoundry-incubator/diego-windows-release/)
repository. This template can be uploaded to [Cloud
Formation](https://console.aws.amazon.com/cloudformation/home) for automatic
setup of a Windows cell.

The CloudFormation wizard will ask for a number of parameters.

1. SecurityGroup: Security group ID to use for the Windows cells
1. BoshUserName: Username for BOSH director
1. BoshPassword: Pasword for BOSH director
1. BoshHost: Bosh director host
1. CellName: The name for your cell
1. VPCID: the id of the vpc in which the cell and the subnet will be created
1. NAT Instance: the instance ID of the NAT box. Search for `NAT` in the CloudFormation dropdown, it will typically be the first result. Note that the NAT will need to have a security group that allows traffic from the subnet you are setting up the cell within.
1. SubnetCIDR: the IP range of the Windows cell subnet, e.g. `10.0.100.0/24`. It should not collide with an existing subnet within the VPC.
1. Keypair: A keypair that you have the private key to. This will be necessary to retrieve the Administrator password to the Windows VMs that are created.

The CloudFormation template will configure the Windows cell for the
appropriate availability zone based on the provided security group, install the
MSI and register itself with Diego. The CloudFormation template will only
succeed if all services are up and running after installation. To debug a
failed install, set "Rollback on failure" to "No" under advanced options.

### Manual Setup

1. Download the `setup.ps1` script from
our [latest release](https://github.com/cloudfoundry-incubator/garden-windows-release/releases/latest).
From inside File explorer, right click on the file and click `Run with powershell`.
The script will enable the required Windows features,
configure the DNS settings, and configure the firewall to the way that the cell needs.

## Install the MSIs

- Download the `generate.exe` from a compatible [diego-windows-release](https://github.com/cloudfoundry/diego-windows-release/releases) release. **Note** that if you are using Internet Explorer to download the file it may remove the `.exe` extension from the file, so you will have to rename the file and add the extension.

- Run `generate.exe` with the following argument template:

```
generate.exe -outputDir=[the directory where the script will output its files]
             -boshUrl=[the URL for your BOSH director, with credentials]
             -machineIp=[(optional) IP address of this cell. Auto-discovered if ommitted]
```

For example:

```
generate.exe -outputDir=C:\diego-install-dir -boshUrl=https://10.10.0.54:25555 -machineIp=192.168.50.4
```

The output of `generate.exe` is a batch file called `install.bat`, which appears in the same directory.


- Download `DiegoWindows.msi` and `GardenWindows.msi` to the output directory
you specified to the generate command. The filenames must remain unchanged,
since the script assumes these will be the MSI file names.

- Change any properties in the generated `install.bat` if desired.

- Run the `install.bat` script in the output directory. This will install
both of the MSIs with all of the arguments they require.


#### Changing BOSH properties

Note that if BOSH properties are changed in the BOSH manifest, the MSI must be
reinstalled. For example, setting a syslog host in the deployment manifest will
not update the MSI parameters.

## Verifying your DiegoWindows deployment

1. Download `hakim.exe` from the DiegoWindows release onto your Windows cell.
   Run it in a terminal. It will check your system to ensure that the install
   is properly configured, and will output error messages if it detects any
   problems.

1. Download/clone the [CF Smoke Tests](https://github.com/cloudfoundry/cf-smoke-tests) repository

1. Follow the instructions from the README to run the smoke tests against your
environment with the `enable_windows_tests` configuration flag set to `true`.

This will deploy a sample .NET application to one of your Windows cells and
exercise basic CF functionality to ensure your deployment is functioning
properly.
