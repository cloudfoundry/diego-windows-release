Debugging tips & tricks
--------------

1. Ensure that all the Windows features documented in [scripts/setup.ps1](scripts/setup.ps1) are installed.
1. Ensure Consul is resolving correctly. This can be done by running `curl http://file-server.service.cf.internal:8080` from the Windows cell.
