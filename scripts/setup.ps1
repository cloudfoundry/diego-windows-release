Configuration CFWindows {
  Node "localhost" {

    WindowsFeature IISWebServer {
      Ensure = "Present"
        Name = "Web-Webserver"
    }
    WindowsFeature WebSockets {
      Ensure = "Present"
        Name = "Web-WebSockets"
    }
    WindowsFeature WebServerSupport {
      Ensure = "Present"
        Name = "AS-Web-Support"
    }
    WindowsFeature DotNet {
      Ensure = "Present"
        Name = "AS-NET-Framework"
    }
    WindowsFeature HostableWebCore {
      Ensure = "Present"
        Name = "Web-WHC"
    }

    Script SetupDNS {
      SetScript = {
        Set-DnsClientServerAddress -InterfaceAlias Ethernet0 -ServerAddresses 127.0.0.1,8.8.4.4
      }
      GetScript = {
        Get-DnsClientServerAddress -AddressFamily ipv4 -InterfaceAlias Ethernet0
      }
      TestScript = {
        if(@(Compare-Object -ReferenceObject (Get-DnsClientServerAddress -InterfaceAlias Ethernet0 -AddressFamily ipv4 -ErrorAction Stop).ServerAddresses -DifferenceObject 127.0.0.1,8.8.4.4).Length -eq 0)
        {
          Write-Verbose -Message "DNS Servers are set correctly."
            return $true
        }
        else
        {
          Write-Verbose -Message "DNS Servers not yet correct."
            return $false
        }
      }
    }

    Script DisableDNSCache
    {
      SetScript = {
        Set-Service -Name Dnscache -StartupType Disabled
          Stop-Service -Name Dnscache
      }
      GetScript = {
        Get-Service -Name Dnscache
      }
      TestScript = {
        return @(Get-Service -Name Dnscache).Status -eq "Stopped"
      }
    }

    Script EnableDiskQuota
    {
      SetScript = {
        fsutil quota enforce C:
      }
      GetScript = {
        fsutil quota query C:
      }
      TestScript = {
        $query = "select * from Win32_QuotaSetting where VolumePath='C:\\'"
          return @(Get-WmiObject -query $query).State -eq 2
      }
    }

    Registry IncreaseDesktopHeapForServices
    {
        Ensure = "Present"
        Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\SubSystems"
        ValueName = "Windows"
        ValueType = "ExpandString"
        ValueData = "%SystemRoot%\system32\csrss.exe ObjectDirectory=\Windows SharedSection=1024,20480,20480 Windows=On SubSystemType=Windows ServerDll=basesrv,1 ServerDll=winsrv:UserServerDllInitialization,3 ServerDll=sxssrv,4 ProfileControl=Off MaxRequestThreads=16"
    }

    Script SetupFirewall
    {
      TestScript = {
        $anyFirewallsDisabled = !!(Get-NetFirewallProfile -All | Where-Object { $_.Enabled -eq "False" })
        $adminRuleMissing = !(Get-NetFirewallRule -Name CFAllowAdmins -ErrorAction Ignore)
        Write-Verbose "anyFirewallsDisabled: $anyFirewallsDisabled"
        Write-Verbose "adminRuleMissing: $adminRuleMissing"
        if ($anyFirewallsDisabled -or $adminRuleMissing)
        {
          return $false
        }
        else {
          return $true
        }
      }
      SetScript = {
        $admins = New-Object System.Security.Principal.NTAccount("Administrators")
        $adminsSid = $admins.Translate([System.Security.Principal.SecurityIdentifier])

        $LocalUser = "D:(A;;CC;;;$adminsSid)"
        $otherAdmins = Get-WmiObject win32_groupuser | 
          Where-Object { $_.GroupComponent -match 'administrators' } |
          ForEach-Object { [wmi]$_.PartComponent }

        foreach($admin in $otherAdmins)
        {
          $ntAccount = New-Object System.Security.Principal.NTAccount($admin.Name)
          $sid = $ntAccount.Translate([System.Security.Principal.SecurityIdentifier]).Value
          $LocalUser = $LocalUser + "(A;;CC;;;$sid)"
        }
        New-NetFirewallRule -Name CFAllowAdmins -DisplayName "Allow admins" `
          -Description "Allow admin users" -RemotePort Any `
          -LocalPort Any -LocalAddress Any -RemoteAddress Any `
          -Enabled True -Profile Any -Action Allow -Direction Outbound `
          -LocalUser $LocalUser

        Set-NetFirewallProfile -All -DefaultInboundAction Allow -DefaultOutboundAction Block -Enabled True
      }
      GetScript = { Get-NetFirewallProfile }
    }
  }
}

Enable-PSRemoting -Force
CFWindows
Start-DscConfiguration -Wait -Path .\CFWindows -Force -Verbose
