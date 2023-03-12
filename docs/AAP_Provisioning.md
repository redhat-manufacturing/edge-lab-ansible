# Ansible Automation Platform (AAP) Environment

This document describes how to setup and provision an instance of Ansible Automation Platform as containers in OpenShift as well as traditional environments (Bare metal/VM's).

## Configurations

The configurations necessary to deploy AAP are defined in a variables file located in [inventory/group_vars/aap/vars](inventory/group_vars/aap/vars) as well as within Ansible Vault. The contents can be modified to customize the configuration of the deployment.

## Prerequisites

The following requirements must be satisfied prior to provisioning AAP.

* Infrastructure for which AAP should be installed
* RHN credentials to subscribe the instances
* Ansible Automation Platform License file
* API token to obtain assets from the Red Hat API
* Credentials to access Red Hat Container images
* Custom Execution Environment

### Infrastructure

Bare metal instances or virtual machine must be provided in order to install AAP. Please refer to the [Ansible Automation Platform installation requirements](https://access.redhat.com/documentation/en-us/red_hat_ansible_automation_platform/2.3/html-single/red_hat_ansible_automation_platform_installation_guide/index) document for the necessary hardware requirements.

Populate the AAP inventory with the desired infrastructure in the [inventory/aap](inventory/aap) file.


### AAP License File

An Ansible Automation Platform license file is required to enable the instances to have the appropriate licensing required for operation. More information surrounding how to obtain the license file can be found [here](https://access.redhat.com/solutions/2975721).

The location the license file is controlled by the `aap_license_file` variable and by default expects the file to be called `aap-license.zip` and to be located at the root of this repository. An alternate path and filename can be chosen by overriding the value of the variable.

### Registry Registry Credentials

Container images from the Red Hat Container Catalog is used within Ansible Automation Platform, and specifically within Automation Hub. While personal account credentials can be used, it is recommended that a Service Account be used. More information on how to obtain a service account can be found [here](https://access.redhat.com/terms-based-registry).

### Inventory Considerations

Each of the sections described within this document as they relate to the prerequisites require that steps be implemented so that their values are utilized as part of the provisioning process.

Create a new file, such as `my-sensitive-aap-creds.yml` containing the following content:

```yaml
subscription_username: "<username>"
subscription_password: "<password>"

aap_setup_down_offline_token: "<offline_token>"

aap_setup_prep_inv_secrets:
  all:
    registry_username: "<registry_username>"
    registry_password: "<registry_password>"

```

### Certificates

By default, Ansible Automation Platform generates of self signed TLS certificates to secure transport between externally facing endpoints. This repository supports providing a set of certificates to override the default.

The following variables can be used to specify the content of the certificates:

* `root_ca_ssl_cert` - Root TLS certificate
* `root_ca_ssl_key` - Root TLS private key
* `aap_controller_ssl_cert` - Ansible Controller TLS certificate
* `aap_controller_ssl_key` - Ansible Controller TLS private key
* `aap_hub_ssl_cert` - Automation Hub TLS certificate
* `aap_hub_ssl_key` - Automation Hub TLS private key

### Custom Execution Environment

A custom Execution Environment (EE) contains all of the necessary libraries and Ansible content to perform the deployment and manage the environment. This EE can be specified when running `ansible-navigator` by using the `--eei` flag.

## Deployment

Once all of the prerequisites have been satisfied, AAP can be deployed. The deployment consists of executing two playbooks located in the [playbooks](playbooks) directory:

* [aap-prereqs.yml](playbooks/aap-prereqs.yml)
* [setup-aap.yml](playbooks/setup-aap.yml)

The `aap-prereqs.yml` playbook subscribes the RHEL machines, enables the required RPM repositories along with deploying an instance of PostgreSQL to support the environment.

Execute the following command from the root of the repository to perform the prerequisites needed to support the deployment:

```shell
ansible-navigator run --eei=localhost/edge-lab-aap:latest --pp=missing playbooks/aap-prereqs.yml
```

Once the prerequisites playbook has been executed and all of the prerequisite steps as described earlier have been satisfied, execute the following command to deploy AAP

```shell
ansible-navigator run --eei=localhost/edge-lab-aap:latest --pp=missing playbooks/setup-aap.yml -e @my-sensitive-aap-creds.yml`
```

Once the playbook completes, AAP will be deployed and available at the endpoints provided in the inventory.
