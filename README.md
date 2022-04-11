# Cloud Pak for Security GitOps module

Module to populate a gitops repository with the resources to deploy IBM Cloud Pak for Security. 

## Software dependencies

The module depends on the following software components:

### Command-line tools

- terraform >= v0.15

### Terraform providers

None

## Module dependencies

This module makes use of the output from other modules:

- GitOps - github.com/cloud-native-toolkit/terraform-tools-gitops.git
- Namespace - github.com/cloud-native-toolkit/terraform-gitops-namespace.git
- Catalogs - github.com/cloud-native-toolkit/terraform-gitops-cp-catalogs.git

## Example usage

```hcl-terraform
module "cp4s" {
  source = "github.com/cloud-native-toolkit/terraform-gitops-cp4s.git"

  gitops_config = module.gitops.gitops_config
  git_credentials = module.gitops.git_credentials
  server_name = module.gitops.server_name
  namespace = module.gitops_namespace.name
  catalog = module.cp_catalogs.catalog_ibmoperators
  kubeseal_cert = module.gitops.sealed_secrets_cert
  entitlement_key = module.cp_catalogs.entitlement_key
  admin_user  = var.cp4s_admin_user
}
```