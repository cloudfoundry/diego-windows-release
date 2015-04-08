dism /online /Enable-Feature /FeatureName:IIS-WebServer /All /NoRestart
dism /online /Enable-Feature /FeatureName:IIS-WebSockets /All /NoRestart
dism /online /Enable-Feature /FeatureName:Application-Server-WebServer-Support /FeatureName:AS-NET-Framework /All /NoRestart
dism /online /Enable-Feature /FeatureName:IIS-HostableWebCore /All /NoRestart

netsh interface ipv4 add dnsserver "Ethernet" address=127.0.0.1 index=1
netsh interface ipv4 add dnsserver "Ethernet" address=8.8.4.4 index=2
netsh interface ipv4 show dnsservers

:: disable Dnscache setup [#91881972]
:: Dnscache will disable dns servers if they didn't respond/were down.
:: This combined with the fact that the Consul agent keeps dying is causing
:: name resolution to all cf components.
sc config Dnscache start= disabled
sc stop Dnscache
