# Operator Notes

## Rebooting cells

When rebooting the cell, you'll want to first trigger evacuation to ensure your users are not affected by app downtime.
To do so, you can use this PowerShell script:

```powershell
Set-Service RepService -startuptype "Disabled"

Invoke-WebRequest -Uri http://localhost:1800/evacuate -Method Post

while (true) {
    try {
        Get-WebRequest "http://localhost:1800/ping"
    } catch {
        [system.exception]
        break;
    }
}

Set-Service RepService -startuptype "Automatic"
```
