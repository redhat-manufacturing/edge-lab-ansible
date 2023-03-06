# Ansible Automation Platform Execution Environment

This Execution Environment produces a compatible runtime to install and configure Ansible Automation Platform.

## Prerequisites

1. The base lab images (`extended-base-image` and `extended-builder-image`) must already be built on the current machine this EE is being produced. See the repository [README](../README.md).
2. Create an `ansible.cfg` at that path [context/ansible.cfg] containing the following contents:

```ini
[galaxy]
server_list = automation_hub, community

[galaxy_server.automation_hub]
url=https://cloud.redhat.com/api/automation-hub/
auth_url=https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token

token=<TOKEN>

[galaxy_server.community]
url=https://galaxy.ansible.com
```

Replace the `token` value with your token for [Automation Hub](https://console.redhat.com/ansible/automation-hub)

## Producing an EE

Due to limitations on a dependency caused by the [kubernetes collection](https://galaxy.ansible.com/kubernetes/core), `ansible-builder` nor `ansible-navigator` cannot be used and the EE must be produced manually using `podman`.

Once the necessary prerequisites have been completed, build the EE with the following command:

```shell
podman build -t localhost/edge-lab-aap:latest context
```

