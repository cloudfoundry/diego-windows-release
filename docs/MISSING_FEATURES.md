## Missing features in .Net

1. No bosh support. Implications:
   1. Cannot guarantee binary compatability with diego
   2. No automatic/rolling update path for cell operating systems/AMIs and/or MSI
1. Spare CPU cycles aren't availble for other containers (unlike linux)
1. Buildpacks
1. Container ssh access
1. ICMP firewall rules (no ICMP traffic is allowed by default)
1. Firewall logging

## Stability and scalability differences

TODO: There are some stories in the back log to investigate the limits
and stability of a windows cell.
