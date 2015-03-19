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
