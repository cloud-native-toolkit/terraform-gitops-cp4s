locals {
  name = "cp4s"
  subscription_name          = "ibm-cp4s-operator"
  instance_name              = "ibm-cp4s-threatmgmt-instance"
  bin_dir       = module.setup_clis.bin_dir
  subscription_chart_dir = "${path.module}/charts/ibm-cp4s-operator"
  subscription_yaml_dir      = "${path.cwd}/.tmp/${local.name}/chart/${local.subscription_name}"
  instance_chart_dir = "${path.module}/charts/ibm-cp4s-threatmgmt-instance"
  instance_yaml_dir          = "${path.cwd}/.tmp/${local.name}/chart/${local.instance_name}"
  service_url   = "http://${local.name}.${var.namespace}"
  subscription_values_content = {
    cp4s = {
      cps_namespace        = var.namespace
      cps_platform_channel = var.channel
      catalogsource = var.catalog
      catalogsource_namespace = var.catalog_namespace
    }
  }
  instance_values_content = {
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
  layer = "services"
  type = "instances"
  application_branch = "main"
  namespace = var.namespace
  layer_config = var.gitops_config[local.layer]
}

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"
}

resource null_resource create_subscription_yaml {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.subscription_name}' '${local.subscription_chart_dir}' '${local.subscription_yaml_dir}'"

    environment = {
      VALUES_CONTENT = yamlencode(local.subscription_values_content)
    }
  }
}

resource null_resource setup_subscription_gitops {
  depends_on = [null_resource.create_subscription_yaml]

  triggers = {
    name = local.subscription_name
    namespace = var.namespace
    yaml_dir = local.subscription_yaml_dir
    server_name = var.server_name
    layer = local.layer
    type = "operators"
    git_credentials = yamlencode(var.git_credentials)
    gitops_config   = yamlencode(var.gitops_config)
    bin_dir = local.bin_dir
  }

  provisioner "local-exec" {
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }

  provisioner "local-exec" {
    when = destroy
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --delete --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }
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
  depends_on = [null_resource.setup_subscription_gitops]
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.instance_name}' '${local.instance_chart_dir}' '${local.instance_yaml_dir}'"

    environment = {
      VALUES_CONTENT = yamlencode(local.instance_values_content)
    }
  }
}

resource null_resource setup_instance_gitops {
  depends_on = [null_resource.create_instance_yaml]

  triggers = {
    bin_dir = local.bin_dir
    name = local.instance_name
    namespace = var.namespace
    yaml_dir = local.instance_yaml_dir
    server_name = var.server_name
    layer = local.layer
    type = "instances"
    git_credentials = yamlencode(var.git_credentials)
    gitops_config   = yamlencode(var.gitops_config)
  }

  provisioner "local-exec" {
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type=${self.triggers.type} "

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }

  provisioner "local-exec" {
    when = destroy
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --delete --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }
}