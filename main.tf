locals {
  name = "cp4s"
  subscription_name          = "ibm-cp4s-operator"
  instance_name              = "ibm-cp4s-threatmgmt-instance"
  subscription_chart_dir = "${path.module}/charts/ibm-cp4s-operator"
  subscription_yaml_dir      = "${path.cwd}/.tmp/${local.name}/chart/${local.subscription_name}"
  instance_chart_dir = "${path.module}/charts/ibm-cp4s-threatmgmt-instance"
  license_key         = "license.key"
  secret_name         = "isc-cases-customer-license"
  secrets_dir         = "${path.cwd}/.tmp/${local.name}/secrets"
  instance_yaml_dir   = "${path.cwd}/.tmp/${local.name}/chart/${local.instance_name}"
  service_url   = "http://${local.name}.${var.namespace}"
  subscription_values_content = {
    ibm-cp4s-operator = {
      cp4s = {
        cps_namespace        = var.namespace
        cps_platform_channel = var.channel
        catalogsource = var.catalog
        catalogsource_namespace = var.catalog_namespace
      }
    }
  }
  instance_values_content = {
    ibm-cp4s-threatmgmt-instance = {
      metadata = {
        name = "threatmgmt"
        namespace = var.namespace
      } 
      spec = {
        acceptLicense = true
        basicDeploymentConfiguration = {
          adminUser = var.admin_user
          domain = var.domain
          storageClass = var.storage_class
        }
        extendedDeploymentConfiguration = {
          airgapInstall = false
          backupStorageClass = var.backup_storage_class
          backupStorageSize = var.backup_storage_size
          imagePullPolicy = "Always"
          repository = "cp.icr.io/cp/cp4s"
          repositoryType = "entitled"
          roksAuthentication = var.roks_auth
        }
        threatManagementCapabilities = {
          deployDRC = true
          deployRiskManager = true
          deployThreatInvestigator = true  
        }
      }
    }
  }
  layer = "services"
  type = "instances"
  application_branch = "main"
  namespace = var.namespace
  layer_config = var.gitops_config[local.layer]
}


resource null_resource create_subscription_yaml {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.subscription_name}' '${local.subscription_chart_dir}' '${local.subscription_yaml_dir}'"

    environment = {
      VALUES_CONTENT = yamlencode(local.subscription_values_content)
    }
  }
}

resource gitops_module setup_subscription_gitops {
  depends_on = [null_resource.create_subscription_yaml]

  name = local.subscription_name
  namespace = var.namespace
  content_dir = local.subscription_yaml_dir
  server_name = var.server_name
  layer = local.layer
  type = "base"
  branch = local.application_branch
  config = yamlencode(var.gitops_config)
  credentials = yamlencode(var.git_credentials)
}

module pull_secret {
  source = "github.com/cloud-native-toolkit/terraform-gitops-pull-secret"

  gitops_config = var.gitops_config
  git_credentials = var.git_credentials
  server_name = var.server_name
  kubeseal_cert = var.kubeseal_cert
  namespace = var.namespace
  docker_username = "cp"
  docker_password = var.entitlement_key
  docker_server   = "cp.icr.io"
  secret_name     = "ibm-entitlement-key"
}

resource null_resource create_instance_yaml {
  depends_on = [gitops_module.setup_subscription_gitops]
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.instance_name}' '${local.instance_chart_dir}' '${local.instance_yaml_dir}'"

    environment = {
      VALUES_CONTENT = yamlencode(local.instance_values_content)
    }
  }
}

resource gitops_module setup_instance_gitops {
  depends_on = [
    null_resource.create_instance_yaml,
    module.seal_secrets
  ]

  name = local.instance_name
  namespace = var.namespace
  content_dir = local.instance_yaml_dir
  server_name = var.server_name
  layer = local.layer
  type = "base"
  branch = local.application_branch
  config = yamlencode(var.gitops_config)
  credentials = yamlencode(var.git_credentials)
}

resource null_resource create_secrets_yaml {

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-secrets.sh '${var.namespace}' '${local.secret_name}' '${local.secrets_dir}'"

    environment = {
      LICENSE = var.orchestration_automation_license
      LICENSE_KEY = local.license_key
    }
  }
}


module seal_secrets {
  depends_on = [null_resource.create_secrets_yaml]

  source = "github.com/cloud-native-toolkit/terraform-util-seal-secrets.git"

  source_dir    = local.secrets_dir
  dest_dir      = local.instance_yaml_dir
  kubeseal_cert = var.kubeseal_cert
  label         = local.secret_name
}