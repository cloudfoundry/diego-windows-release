dism /online /Enable-Feature /FeatureName:IIS-WebServer /All /NoRestart
dism /online /Enable-Feature /FeatureName:IIS-WebSockets /All /NoRestart
dism /online /Enable-Feature /FeatureName:Application-Server-WebServer-Support /FeatureName:AS-NET-Framework /All /NoRestart
dism /online /Enable-Feature /FeatureName:IIS-HostableWebCore /All /NoRestart

netsh interface ipv4 add dnsserver "Ethernet" address=127.0.0.1 index=1
netsh interface ipv4 add dnsserver "Ethernet" address=8.8.4.4 index=2
netsh interface ipv4 show dnsservers
