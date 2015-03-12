# diego-windows-msi

## Dependencies
- Visual Studio 2013
- [Visual Studio Installer Projects Extension](https://visualstudiogallery.msdn.microsoft.com/9abe329c-9bba-44a1-be59-0fbf6151054d)
- Go 1.4 (tested with version go1.4.2 windows/amd64)
- 64 bit version of Windows (tested with Windows Server 2012 R2 Standard)

## IIS

To be able to run the specs, you'll need to enable the following server roles:

1. `Web Server (IIS)`
2. `Websocket Protocol` (Inside Web Server (IIS)/Web Server/Application Development)
3. `Application Server`

and the following feature:

1. `IIS Hostable Web Core`

There is a dependency between these roles/features. You won't be able to enable 2 & 3 before 1 is enabled, so enable these roles/features in the order specified.

## Producing an MSI

Run `make.bat` as Administrator, the MSI and Windows Circus tgz file will be output into the `output` directory.
