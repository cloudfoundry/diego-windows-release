# Operator Notes

## Rebooting cells

When rebooting the cell, you'll want to first trigger evacuation to ensure your users are not affected by app downtime.
To do so, you can use this PowerShell script:

```powershell
Set-Service RepService -startuptype "Disabled"

Invoke-WebRequest -Uri http://localhost:1800/evacuate -Method Post

while ($true) {
    try {
        Get-WebRequest "http://localhost:1800/ping"
    } catch {
        [system.exception]
        break;
    }
}

Set-Service RepService -startuptype "Automatic"
```

## Getting versions

All executables and MSIs include version numbers in their Properties tab, by right-clicking on the file and going to properties.

For `setup.ps1`, pass the version flag on the command line:

```
powershell .\setup.ps1 -version
```

## Custom CA Certificates

If your applications require custom CA certificates in order to communicate
with other components, the certificates may be installed on the cell.
Certificates trusted by the local computer or domain will then be trusted by
applications running on that cell.

See [this](https://technet.microsoft.com/en-us/library/cc754841.aspx) TechNet
article on managing trusted root certificates.
