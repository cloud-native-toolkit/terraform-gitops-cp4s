
variable "gitops_config" {
  type        = object({
    boostrap = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
    })
    infrastructure = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
      payload = object({
        repo = string
        url = string
        path = string
      })
    })
    services = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
      payload = object({
        repo = string
        url = string
        path = string
      })
    })
    applications = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
      payload = object({
        repo = string
        url = string
        path = string
      })
    })
  })
  description = "Config information regarding the gitops repo structure"
}

variable "git_credentials" {
  type = list(object({
    repo = string
    url = string
    username = string
    token = string
  }))
  description = "The credentials for the gitops repo(s)"
  sensitive   = true
}

variable "namespace" {
  type        = string
  description = "The namespace where the application should be deployed"
}

variable "kubeseal_cert" {
  type        = string
  description = "The certificate/public key used to encrypt the sealed secrets"
  default     = ""
}

variable "server_name" {
  type        = string
  description = "The name of the server"
  default     = "default"
}

variable "channel" {
  type = string
  description = "The version of channel"
  default = "v1.9"
}

variable "storage_class" {
  type = string
  description = "The provisioned block or file storage class for all the PVCs required by Cloud Pak for Security. When it is not specified, the default storage class is used."
  default = ""
}

variable "roks_auth" {
  type = string
  description = "Whether ROKS authentication need to be enabled"
  default = "false"
}

variable "entitlement_key" {
  type = string
  description = "Entitlement key value"
}

variable "admin_user" {
  type = string
  description = "Short name or email-id of the user to be given administrator privileges in the default account. Mandatory value while creating cp4s-threat-management-instance"
  default = "admin"
}

variable "catalog" {
  type        = string
  description = "The catalog source that should be used to deploy the operator"
  default     = "ibm-operator-catalog"
}

variable "catalog_namespace" {
  type        = string
  description = "The namespace where the catalog has been deployed"
  default     = "openshift-marketplace"
}

variable "backup_storage_size" {
  type = string
  description = "The storage size for the backup and restore PVC. Must be 500Gi or higher."
  default = ""
}

variable "backup_storage_class" {
  type = string
  description = "Storage class for the backup and restore pod. If this value is not set, Cloud Pak for Security takes the value from the storageClass parameter."
  default = ""
}

variable "domain" {
  type = string
  description = "The fully qualified domain name (FQDN) created for Cloud Pak for Security. If you don't specify an FQDN, it is generated as cp4s.<cluster_ingress_subdomain>."
  default = ""
}