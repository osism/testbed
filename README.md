# OSISM testbed

[![Installation guide](https://img.shields.io/static/v1?label=&message=documentation&color=blue)](https://docs.osism.tech/testbed)

With this testbed, it is possible to run a full OSISM installation, the baseline
of the Sovereign Cloud Stack, on an existing OpenStack environment such as Cleura
or Open Telekom Cloud.

The testbed is intended as a playground. Further services and integration will be
added over time. More and more best practices and experiences from the productive
installations will be included here in the future. It will become more production-like
over time. However, at no point does it claim to represent a production setup exactly.

Open Source Software lives from participation. We welcome any issues, change requests
or general feedback. Do not hesitate to open an issue.

## Point of entry

The [Homer: Operations Dashboard](https://homer.testbed.osism.xyz) is best for
getting started with the testbed after full deployment.

| :exclamation: The testbed uses certs signed by the self-signed [OSISM Testbed CA](https://raw.githubusercontent.com/osism/testbed/main/environments/kolla/certificates/ca/testbed.crt) |
|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|

![Operations Dashboard](https://raw.githubusercontent.com/osism/testbed/main/contrib/assets/operations-dashboard.png)

## GitHub Actions

### Syntax checks

[![Check terraform syntax](https://github.com/osism/testbed/actions/workflows/check-terraform-syntax.yml/badge.svg)](https://github.com/osism/testbed/actions/workflows/check-terraform-syntax.yml)

### Regular tasks

[![Update manager images](https://github.com/osism/testbed/actions/workflows/update-manager-images.yml/badge.svg)](https://github.com/osism/testbed/actions/workflows/update-manager-images.yml)

## Zuul job results

https://zuul.osism.xyz/t/osism/builds?project=osism%2Ftestbed&skip=0
