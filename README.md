## **DEPRECATION NOTICE**

This repository is no longer being supported. Windows Server 2012R2 Diego cells should be deployed with BOSH via [Garden Windows BOSH release](https://github.com/cloudfoundry-incubator/garden-windows-bosh-release). A canonical opsfile can be found at [cloudfoundry/cf-deployment](https://github.com/cloudfoundry/cf-deployment/blob/master/operations/windows-cell.yml).

# diego-windows-release

This repo contains submodules with all of the source requirements to run the
Diego components for Cloud Foundry on Windows. After an install all of the
necessary programs (consul, rep, and metron) will be running as services.

- [Building instructions](docs/BUILDING.md)
- [Installation instructions](docs/INSTALL.md)
- [Operator instructions](docs/OPERATOR-NOTES.md)

Experiencing any issues with your Diego-Windows installation? Check out our convenient [Troubleshooting guide](docs/TROUBLESHOOT.md).
