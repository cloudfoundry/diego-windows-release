## CF Features Not Supported by Greenhouse/.NET 1.0

1. BOSH. Implications:
   1. Cannot guarantee binary compatability with diego
   2. No automatic/rolling update path for cell operating systems/AMIs and/or MSI
   3. No support for [DEA Network Properties](https://docs.cloudfoundry.org/concepts/security.html#network-traffic) (CF security groups provide this capability)
1. Spare CPU cycles aren't availble for other containers (unlike Linux)
1. Buildpacks
1. Container ssh access
1. ICMP firewall rules (no ICMP traffic is allowed by default)
1. Firewall logging

## Stability and Scalability Expectations

- TODO: There are some stories in the backlog to investigate the limits and stability of a windows cell. The current goal is parity with Diego scaling and stability, but we may publish caveats if this is not easily achievable.

## Known Security and Isolation Limitations

1. A process can allocate shared memory that is not accounted for by job object memory accounting

## Supported Applications

1. [ASP .NET MVC](https://github.com/cloudfoundry-incubator/wats/tree/af669382b4639e7605afc23f1dc8d48d8bfa5dd1/assets/nora/NoraPublished) (12-factor ASP.NET MVC apps compiled against .NET 3.5+ were tested most extensively)
1. [Windows-compiled executables](https://github.com/cloudfoundry-incubator/wats/tree/af669382b4639e7605afc23f1dc8d48d8bfa5dd1/assets/webapp)
1. [Batch scripts (with a manually specified start command)](https://github.com/cloudfoundry-incubator/wats/tree/af669382b4639e7605afc23f1dc8d48d8bfa5dd1/assets/batch-script)

## Applications Not Supported

1. [WCF Applications](http://forums.iis.net/t/1174466.aspx)
